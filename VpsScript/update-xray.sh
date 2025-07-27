#!/bin/bash

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

BIN_DIR="/usr/local/x-ui/bin"
ARCH=$(uname -m)
TMP_DIR="/tmp/xray_update"
RETRY_COUNT=3

get_arch() {
    case "$ARCH" in
        x86_64) echo "64" ;;
        aarch64) echo "arm64-v8a" ;;
        armv7l) echo "arm32-v7a" ;;
        armv6l) echo "arm32-v6" ;;
        *) echo "unknown" ;;
    esac
}

get_latest_version() {
    curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
        | grep '"tag_name":' | cut -d\" -f4
}

detect_existing_xray() {
    f=$(find "$BIN_DIR" -maxdepth 1 -type f -name "xray*" | head -n 1)
    if [[ -z "$f" ]]; then
        log "❌ 未在 $BIN_DIR 找到现有 xray 文件，请手动确认"
        exit 1
    fi
    echo "$f"
}

rollback() {
    if [[ -f "$XRAY_BACKUP" ]]; then
        log "⚠️ 回滚：恢复旧版本..."
        mv -f "$XRAY_BACKUP" "$XRAY_BIN"
        chmod +x "$XRAY_BIN"
        systemctl restart x-ui
        log "✅ 已恢复并重启 x-ui"
    fi
}

update_xray() {
    arch=$(get_arch)
    if [[ "$arch" == "unknown" ]]; then
        log "❌ 不支持的系统架构: $ARCH"
        exit 1
    fi

    latest_ver=$(get_latest_version)
    log "✅ 检测到最新版本: $latest_ver"

    zip_name="Xray-linux-$arch.zip"
    download_url="https://github.com/XTLS/Xray-core/releases/download/${latest_ver}/${zip_name}"
    log "⬇️ 准备下载: $download_url"

    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"

    success=0
    for ((i=1; i<=$RETRY_COUNT; i++)); do
        if curl -L -o "$zip_name" "$download_url"; then
            success=1
            break
        else
            log "⚠️ 下载失败，重试中 ($i/$RETRY_COUNT)..."
            sleep 3
        fi
    done

    if [[ $success -ne 1 ]]; then
        log "❌ 下载失败，退出更新"
        exit 1
    fi

    unzip -o "$zip_name" xray

    if [[ ! -f "./xray" ]]; then
        log "❌ 解压失败，未找到 xray 文件"
        exit 1
    fi

    XRAY_BIN=$(detect_existing_xray)
    XRAY_BACKUP="${XRAY_BIN}.bak_$(date '+%Y%m%d%H%M%S')"
    log "📍 检测到现有 xray 路径: $XRAY_BIN"

    log "🧰 备份旧版本..."
    cp "$XRAY_BIN" "$XRAY_BACKUP"

    log "🛑 停止 x-ui 服务..."
    systemctl stop x-ui || true

    log "🚀 替换为新版本..."
    chmod +x xray
    mv -f xray "$XRAY_BIN"

    log "✅ 启动 x-ui 服务..."
    if systemctl start x-ui; then
        log "🎉 更新完成，清理旧备份: $XRAY_BACKUP"
        rm -f "$XRAY_BACKUP"
    else
        log "❌ 启动失败，尝试回滚..."
        rollback
    fi
}

trap rollback ERR  # 任何错误触发回滚

update_xray
