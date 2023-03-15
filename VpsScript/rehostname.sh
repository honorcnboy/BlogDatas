#!/bin/bash

# 预先获取 sudo 权限
sudo -v

# 查询当前主机名，并将其赋值给变量 "Old_Hostname"
Old_Hostname=$(hostname)

while true; do
    echo "请输入新的主机名："
    read new_hostname

    # 检查用户是否有输入主机名
    if [ -z "$new_hostname" ]; then
        echo "没有输入主机名"
    else
        # 修改主机名
        echo "$new_hostname" | sudo tee /etc/hostname > /dev/null
        hostnamectl set-hostname $new_hostname

        echo "已将主机名修改为: $new_hostname"
        break
    fi
done

# 查询新的主机名，并将其赋值给变量 "New_Hostname"
New_Hostname=$(hostname)

# 检查 "/etc/hosts" 文件中是否存在 "127.0.0.1 ${Old_Hostname}" 这一行内容并将其删除
if grep -q "127.0.0.1 ${Old_Hostname}" /etc/hosts; then
  sudo sed -i "/127.0.0.1 ${Old_Hostname}/d" /etc/hosts
  echo "删除hosts文件中旧主机名解析: 127.0.0.1 ${Old_Hostname}"
fi

# 检查 "/etc/hosts" 文件中是否存在 "127.0.0.1 ${New_Hostname}" 这一行内容
if grep -q "127.0.0.1 ${New_Hostname}" /etc/hosts; then
    echo "hosts文件中已存在: 127.0.0.1 ${New_Hostname}"
else
    echo "127.0.0.1 ${New_Hostname}" | sudo tee -a /etc/hosts > /dev/null
    echo "hosts文件中已加入: 127.0.0.1 ${New_Hostname}"
fi

echo ""
echo "hosts文件位于: /etc/hosts ，请自行检查."
