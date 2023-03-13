#!/bin/bash

# 查询主机名，并将其赋值给变量 "Hostname"
Hostname=$(hostname)

# 检查 "/etc/hosts" 文件中是否存在 "127.0.0.1 ${Hostname}" 这一行内容
if grep -q "127.0.0.1 ${Hostname}" /etc/hosts; then
    echo "已有：127.0.0.1 ${Hostname}"
else
    echo "127.0.0.1 ${Hostname}" | sudo tee -a /etc/hosts > /dev/null
    echo "已添加：127.0.0.1 ${Hostname}"
fi
