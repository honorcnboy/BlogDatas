#!/bin/bash

# =======================================
# Xray 更新脚本 - 支持 Linux (ARM64/AMD64)
# 作者: ChatGPT + HonorCN
# GitHub: https://github.com/XTLS/Xray-core
# =======================================

set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 配置
BIN_DIR="/usr/local/x-ui/bin"
XRAY_BIN="$BIN_DIR/xray"
ARCH=$(uname -m)
TMP_DIR="/tmp/xray_update"
RETRY_COUNT=3

# 映射系统架构到 Xray 的发布包格式
get_arch() {
    case "$ARCH" in
        x86_64) echo "64" ;;
        aarch64) echo "arm64-v8a" ;;
        armv7l) echo "arm32-v7a" ;;
        armv6l) echo "arm32-v6" ;;
        *) echo "unknown" ;;
    esac
}

# 获取最新版本号
get_latest_version() {
    curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
        | grep '"tag_name":' | cut -d\" -f4
}

# 下载并更新 Xray
update_xray() {
    arch=$(get_arch)
    if [[ "$arch" == "unknown" ]]; then
        log "不支持的架构: $ARCH"
        exit 1
    fi

    latest_ver=$(get_latest_version)
    log "检测到最新版本: $latest_ver"
    
    zip_name="Xray-linux-$arch.zip"
    download_url="https://github.com/XTLS/Xray-core/releases/download/${latest_ver}/${zip_name}"

    log "准备下载: $download_url"

    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"

    success=0
    for ((i=1; i<=$RETRY_COUNT; i++)); do
        if curl -L -o "$zip_name" "$download_url"; then
            success=1
            break
        else
            log "下载失败，重试中 ($i/$RETRY_COUNT)..."
            sleep 3
        fi
    done

    if [[ $success -ne 1 ]]; then
        log "下载失败，退出更新"
        exit 1
    fi

    unzip -o "$zip_name" xray

    if [[ ! -f "./xray" ]]; then
        log "解压失败，未找到 xray 文件"
        exit 1
    fi

    log "备份旧版本..."
    cp "$XRAY_BIN" "${XRAY_BIN}.bak_$(date '+%Y%m%d%H%M%S')"

    log "停止 x-ui..."
    systemctl stop x-ui || true

    log "复制新文件..."
    chmod +x xray
    mv -f xray "$XRAY_BIN"

    log "启动 x-ui..."
    systemctl start x-ui || true

    log "更新完成！当前版本: $latest_ver"
}

# 执行
update_xray
