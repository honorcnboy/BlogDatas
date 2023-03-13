#!/bin/bash

# 查询主机名，并将其赋值给变量 "Hostname"
Hostname=$(hostname)

# 查询本机公网IP，并将其赋值给变量 "Public_IP"
Public_IP=$(curl -4 -s http://checkip.amazonaws.com)

# 检查 "/etc/hosts" 文件中是否存在 "127.0.0.1 ${Hostname}" 这一行内容
if grep -q "127.0.0.1 ${Hostname}" /etc/hosts; then
    echo "已有：127.0.0.1 ${Hostname}"
else
    echo "127.0.0.1 ${Hostname}" | sudo tee -a /etc/hosts > /dev/null
    echo "已添加：127.0.0.1 ${Hostname}"
fi

# 检查 "/etc/hosts" 文件中是否存在 "${Public_IP} '字符串1' '字符串2'" 这样的形式
if grep -q "${Public_IP}" /etc/hosts; then
    # 从 "/etc/hosts" 文件中找到 "${Public_IP} '字符串1' '字符串2'" 这一行，并将 "字符串2" 替换为 "${Hostname}"
    sudo sed -i "s/${Public_IP} .*/${Public_IP} $(hostname)/" /etc/hosts
else
    echo "已添加：${Public_IP} ... ${Hostname}，请查看 /etc/hosts 文件是否存在问题"
fi
