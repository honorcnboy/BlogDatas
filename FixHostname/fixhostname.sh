#!/bin/bash

# 查询主机名"Hostname"
while true; do
    echo "请输入新的主机名："
    read new_hostname

    # 检查用户是否有输入主机名
    if [ -z "$new_hostname" ]; then
        echo "没有输入主机名"
    else
        # 修改主机名
        echo "$new_hostname" > /etc/hostname
        hostnamectl set-hostname $new_hostname

        echo "已将主机名修改为 $new_hostname"
        break
    fi

# 查询主机名，并将其赋值给变量 "Hostname"
Hostname=$(hostname)

# 检查 "/etc/hosts" 文件中是否存在 "127.0.0.1 ${Hostname}" 这一行内容
if grep -q "127.0.0.1 ${Hostname}" /etc/hosts; then
    echo "已有：127.0.0.1 ${Hostname}"
else
    echo "127.0.0.1 ${Hostname}" | sudo tee -a /etc/hosts > /dev/null
    echo "已添加：127.0.0.1 ${Hostname}"
fi
