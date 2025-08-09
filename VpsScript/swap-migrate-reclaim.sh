#!/bin/bash
# swap-migrate-reclaim.sh
# 一键迁移 swap 分区到 swap 文件，支持用户确认删除分区并自动扩容根分区（自动识别文件系统）
set -euo pipefail

SWAPFILE="/swapfile"
BACKUP_FSTAB="/etc/fstab.bak.$(date +%F-%H%M%S)"

log() { echo -e "[`date +'%F %T'`] $*"; }

echo "=== [1/6] 检测系统信息 ==="
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    log "无法检测操作系统，退出"
    exit 1
fi
log "操作系统: $PRETTY_NAME"

# 推荐 swap 大小（MB）
MEM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [ "$MEM_MB" -le 2048 ]; then
    RECOMMEND_SWAP=$((MEM_MB * 2))
elif [ "$MEM_MB" -le 8192 ]; then
    RECOMMEND_SWAP=$MEM_MB
else
    RECOMMEND_SWAP=8192
fi
log "物理内存: ${MEM_MB} MB，推荐 swap 大小: $RECOMMEND_SWAP MB"

read -p "请输入 swap 大小（单位MB，纯数字，回车使用推荐值 $RECOMMEND_SWAP MB）： " INPUT_SWAP

# 去除单位，只取数字部分
INPUT_SWAP_NUM=$(echo "$INPUT_SWAP" | grep -oE '^[0-9]+$' || true)

if [ -z "$INPUT_SWAP_NUM" ]; then
    # 用户没输入或输入无效，使用推荐值
    SWAPSIZE_MB=$(echo "$RECOMMEND_SWAP" | grep -oE '^[0-9]+')
else
    SWAPSIZE_MB=$INPUT_SWAP_NUM
fi

log "使用 swap 大小: ${SWAPSIZE_MB} MB"

# 创建 swap 文件时，统一用 dd 创建，避免 fallocate 不支持
if [ ! -f "$SWAPFILE" ]; then
    log "创建 swap 文件，大小：${SWAPSIZE_MB}MB"
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$SWAPSIZE_MB status=progress
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
else
    log "$SWAPFILE 已存在，跳过创建"
fi

# 检测 swap 文件是否已经启用，避免重复启用导致报错
if ! swapon --show=NAME | grep -q "^$SWAPFILE$"; then
    log "启用 swap 文件 $SWAPFILE"
    swapon "$SWAPFILE"
else
    log "swap 文件 $SWAPFILE 已启用"
fi

# 备份 fstab 并添加 swap 文件挂载
if [ -f /etc/fstab ]; then
    cp /etc/fstab "$BACKUP_FSTAB"
    log "备份 /etc/fstab 到 $BACKUP_FSTAB"
fi
if ! grep -qF "$SWAPFILE" /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    log "添加 swap 文件到 /etc/fstab"
else
    log "/etc/fstab 已包含 swap 文件条目"
fi

# 检测当前启用的 swap 分区（磁盘分区）
CURRENT_SWAP_PART=$(swapon --noheadings --raw | awk '$1 ~ /^\/dev\// {print $1}' || true)

if [ -z "$CURRENT_SWAP_PART" ]; then
    log "没有检测到 swap 分区，迁移完成。"
    # 打印最终状态
    log "当前 swap 状态："
    swapon --show
    log "根分区使用情况："
    df -h /
    exit 0
fi

log "检测到 swap 分区: $CURRENT_SWAP_PART"
read -p "是否关闭并删除该 swap 分区并扩容根分区？(y/N): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    log "用户选择保留 swap 分区，迁移结束。"
    # 打印最终状态
    log "当前 swap 状态："
    swapon --show
    log "根分区使用情况："
    df -h /
    exit 0
fi

# 安装必要工具（仅删除分区扩容时安装）
log "安装删除分区和扩容所需工具：parted growpart"
PKG_INSTALL_CMD=""
if command -v apt >/dev/null 2>&1; then
    PKG_INSTALL_CMD="apt update && apt install -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG_INSTALL_CMD="dnf install -y"
elif command -v yum >/dev/null 2>&1; then
    PKG_INSTALL_CMD="yum install -y"
else
    log "无法识别包管理器，请手动安装 parted 和 cloud-utils-growpart"
    exit 1
fi

for pkg in parted cloud-guest-utils gdisk; do
    if ! command -v "${pkg%% *}" >/dev/null 2>&1; then
        log "安装 $pkg..."
        set +e
        eval "$PKG_INSTALL_CMD $pkg"
        set -e
    fi
done

if ! command -v growpart >/dev/null 2>&1; then
    log "安装 growpart..."
    set +e
    eval "$PKG_INSTALL_CMD cloud-guest-utils" || eval "$PKG_INSTALL_CMD cloud-utils-growpart"
    set -e
fi

log "关闭 swap 分区 $CURRENT_SWAP_PART"
swapoff "$CURRENT_SWAP_PART"
sed -i.bak "/$(echo "$CURRENT_SWAP_PART" | sed 's/\//\\\//g')/ s/^/#/" /etc/fstab

DISK=$(lsblk -no PKNAME "$CURRENT_SWAP_PART")
PART_NUM=$(echo "$CURRENT_SWAP_PART" | grep -o '[0-9]\+$')

if [ -z "$DISK" ] || [ -z "$PART_NUM" ]; then
    log "无法解析磁盘或分区号，取消删除分区操作。请手动处理。"
    exit 1
fi

log "删除分区 $PART_NUM (磁盘 /dev/$DISK)"
parted /dev/$DISK --script rm $PART_NUM

log "刷新内核分区表"
partprobe /dev/$DISK || blockdev --rereadpt /dev/$DISK || true

# 获取根分区设备及文件系统类型
ROOT_PART=$(findmnt / -no SOURCE)
FSTYPE=$(findmnt / -no FSTYPE /)
log "根分区: $ROOT_PART，文件系统类型: $FSTYPE"

ROOT_DISK=$(lsblk -no PKNAME "$ROOT_PART")
ROOT_PART_NUM=$(echo "$ROOT_PART" | grep -o '[0-9]\+$')

if [ -z "$ROOT_DISK" ] || [ -z "$ROOT_PART_NUM" ]; then
    log "无法解析根分区磁盘或分区号，请手动扩容分区。"
    exit 1
fi

log "使用 growpart 扩展 /dev/$ROOT_DISK 分区 $ROOT_PART_NUM"
growpart /dev/$ROOT_DISK $ROOT_PART_NUM

log "根据文件系统类型扩展文件系统..."
case "$FSTYPE" in
    ext4|ext3|ext2)
        if command -v resize2fs >/dev/null 2>&1; then
            resize2fs "$ROOT_PART"
        else
            log "缺少 resize2fs，请安装 e2fsprogs"
        fi
        ;;
    xfs)
        if command -v xfs_growfs >/dev/null 2>&1; then
            xfs_growfs /
        else
            log "缺少 xfs_growfs，请安装 xfsprogs"
        fi
        ;;
    *)
        log "未知文件系统类型 $FSTYPE，请手动扩容文件系统"
        ;;
esac

# 打印扩容后磁盘和文件系统实际容量
log "扩容后根分区大小（块设备）："
lsblk "/dev/$ROOT_DISK" -o NAME,SIZE,TYPE,MOUNTPOINT | grep "$ROOT_PART"
log "扩容后根分区文件系统使用情况："
df -h /

# 打印当前 swap 状态和 swap 文件大小
log "当前 swap 状态："
swapon --show
log "swap 文件大小信息："
ls -lh "$SWAPFILE"

log "迁移并删除旧 swap 分区完成。"
log "备份 fstab 文件在：$BACKUP_FSTAB"
log "如需回退，请恢复 fstab 并删除 swap 文件。"
