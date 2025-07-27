#!/bin/bash

set -e

log() {
    echo -e "[${TIME}] $1"
}

TIME=$(date "+%Y-%m-%d %H:%M:%S")
ARCH=$(uname -m)

# 自动安装 jq（如果未安装）
if ! command -v jq &>/dev/null; then
    log "⏳ 未检测到 jq，正在尝试自动安装..."
    if [[ -x "$(command -v apt)" ]]; then
        apt update && apt install -y jq
    elif [[ -x "$(command -v yum)" ]]; then
        yum install -y epel-release && yum install -y jq
    else
        log "❌ 未知包管理器，无法安装 jq，请手动安装后重试"
        exit 1
    fi
fi

# 只适用于使用 x-ui 的情况
XRAY_PATH=$(find /usr/local/x-ui/bin/ -maxdepth 1 -type f -name "xray*" | grep -Ev '\.bak|\.old' | head -n1)

if [[ -z "$XRAY_PATH" || ! -f "$XRAY_PATH" ]]; then
    log "❌ 未找到 /usr/local/x-ui/bin/ 中的 xray 可执行文件，请确认是否安装了 x-ui"
    exit 1
fi

log "📍 检测到现有 xray 路径: $XRAY_PATH"
INSTALL_DIR=$(dirname "$XRAY_PATH")
BACKUP_PATH="${XRAY_PATH}.bak"

# 识别架构
case "$ARCH" in
x86_64) XRAY_ARCH="Xray-linux-64.zip" ;;
aarch64) XRAY_ARCH="Xray-linux-arm64-v8a.zip" ;;
armv7l) XRAY_ARCH="Xray-linux-arm32-v7a.zip" ;;
*) log "❌ 不支持的架构: $ARCH" && exit 1 ;;
esac

# 获取当前版本
CURRENT_VERSION=$($XRAY_PATH -version 2>/dev/null | grep -oP 'Xray\s+\K[\d\.]+')

# 获取最新 10 个非预发布版本
log "📡 正在获取 Xray 最新版本（非预发布）..."
version_list=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases |
    jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n 10)
version_array=($version_list)

if [[ ${#version_array[@]} -eq 0 ]]; then
    log "❌ 无法获取版本列表，请检查网络连接或 GitHub API"
    exit 1
fi

log "✅ 当前 Xray 内核版本: ${CURRENT_VERSION:-未知}"

echo -e "\n📋 可选版本列表（最近 10 个）："
for i in "${!version_array[@]}"; do
    printf " %2d) %s\n" "$((i+1))" "${version_array[$i]}"
done

# 用户选择版本
read -p $'\n请输入要安装的版本编号（默认1）: ' selection
selection=${selection:-1}
if [[ ! $selection =~ ^[1-9]$|10 ]]; then
    log "❌ 无效输入，退出"
    exit 1
fi
selected_version="${version_array[$((selection-1))]}"

log "📦 准备下载版本: $selected_version"

# 构建下载链接
download_url="https://github.com/XTLS/Xray-core/releases/download/${selected_version}/${XRAY_ARCH}"
temp_dir=$(mktemp -d)
cd "$temp_dir"

# 下载尝试
for i in {1..3}; do
    log "⬇️ 开始下载（尝试第 $i 次）..."
    if curl -L -o xray.zip "$download_url"; then
        break
    elif [[ $i -eq 3 ]]; then
        log "❌ 下载失败，退出更新"
        exit 1
    else
        log "⚠️ 下载失败，重试中..."
        sleep 2
    fi
done

# 解压
unzip xray.zip >/dev/null
if [[ ! -f "xray" ]]; then
    log "❌ 解压失败，未找到 xray 文件"
    exit 1
fi

log "🔧 正在备份旧版本..."
cp -f "$XRAY_PATH" "$BACKUP_PATH"

log "🛑 停止 x-ui 服务..."
systemctl stop x-ui || true
    
log "🚀 安装新版本..."
chmod +x xray
mv -f xray "$XRAY_PATH"

# 验证更新
systemctl start x-ui
NEW_VERSION=$($XRAY_PATH -version 2>/dev/null | grep -oP 'Xray\s+\K[\d\.]+')
if [[ "$NEW_VERSION" == "${selected_version#v}" ]]; then
    log "✅ 更新成功！当前版本: $NEW_VERSION"
    rm -f "$BACKUP_PATH"
else
    log "❌ 更新失败，正在回滚..."
    mv -f "$BACKUP_PATH" "$XRAY_PATH"
    log "🔄 已恢复原版本: $CURRENT_VERSION"
fi

cd /
rm -rf "$temp_dir"
