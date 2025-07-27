#!/bin/bash
set -e
LOGFILE="/root/update-xray.log"
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) A="linux-64" ;;
  arm64|aarch64) A="linux-arm64" ;;
  armv7*|armv7l) A="linux-armv7" ;;
  i386|i686) A="linux-32" ;;
  *) echo "Unsupported arch $ARCH" >&2; exit 1 ;;
esac

echo "[$(date +'%F %T')] Starting Xray update (arch=$A)" | tee -a "$LOGFILE"

# 停止面板
echo "Stopping x-ui service..." | tee -a "$LOGFILE"
systemctl stop x-ui || systemctl stop x-ui.service

# 获取最新版本下载 URL
echo "Fetching latest Xray version..." | tee -a "$LOGFILE"
LATEST_URL=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
  | grep browser_download_url \
  | grep "$A.zip" \
  | cut -d '"' -f4)
if [ -z "$LATEST_URL" ]; then
  echo "Failed to detect download URL" | tee -a "$LOGFILE"
  exit 1
fi
echo "Downloading from $LATEST_URL" | tee -a "$LOGFILE"

TMP=$(mktemp -d)
cd "$TMP"
curl -sL "$LATEST_URL" -o xray.zip
unzip -q xray.zip
chmod +x xray
# 替换二进制文件
mv -f xray /usr/local/x-ui/bin/xray
echo "Replaced xray binary" | tee -a "$LOGFILE"

# 清理
cd /
rm -rf "$TMP"

# 启动服务
echo "Starting x-ui service..." | tee -a "$LOGFILE"
systemctl daemon-reload
systemctl start x-ui

echo "[$(date +'%F %T')] Xray updated successfully" | tee -a "$LOGFILE"
