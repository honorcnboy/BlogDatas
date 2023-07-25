#!/bin/bash

# 常见端口列表（可自行修改）
COMMON_PORTS="22 21 80 443 25 53 110 143"

check_ufw_installed() {
  if command -v /usr/sbin/ufw &>/dev/null; then
    return 0
  else
    return 1
  fi
}

uninstall_previous_firewall() {
  apt-get purge -y iptables
}

install_ufw() {
  apt-get install -y ufw
}

enable_common_ports() {
  for port in $COMMON_PORTS; do
    /usr/sbin/ufw allow $port
  done
}

enable_firewall() {
  /usr/sbin/ufw enable
}

show_open_ports() {
  /usr/sbin/ufw status
}

add_additional_ports() {
  local ports="$1"
  for port in $ports; do
    /usr/sbin/ufw allow $port
  done
}

main() {
  echo "检查是否已安装UFW防火墙..."
  if check_ufw_installed; then
    echo "UFW防火墙已安装。卸载之前的防火墙..."
    uninstall_previous_firewall
  else
    echo "未安装UFW防火墙。正在安装UFW..."
    install_ufw
  fi

  echo "启用常见端口..."
  enable_common_ports

  echo "启用防火墙..."
  enable_firewall

  echo "当前已开放的端口："
  show_open_ports

  read -r -p "是否添加其他端口？（Y/N）：" user_input
  while [[ ! "$user_input" =~ ^[YyNn]$ ]]; do
    read -r -p "输入无效。请回答 'Y' 或 'N'：" user_input
  done

  if [[ "$user_input" =~ ^[Yy]$ ]]; then
    read -r -p "请输入需要开放的端口（以空格分隔）：" additional_ports
    add_additional_ports "$additional_ports"

    echo "已更新的开放端口："
    show_open_ports
  fi

  echo "脚本执行完毕。"
}

main
