#!/bin/bash

# Function to prompt user and validate Y/N input
prompt_yn() {
    read -p "$1 (Y/N): " response
    case "$response" in
        [yY])
            return 0
            ;;
        [nN])
            return 1
            ;;
        *)
            echo "无效的输入，请输入 Y 或 N。"
            prompt_yn "$1"
            ;;
    esac
}

# Function to prompt user and validate integer input
prompt_integer() {
    read -p "$1: " response
    if [[ "$response" =~ ^[0-9]+$ ]]; then
        echo "$response"
    else
        echo "无效的输入，请输入有效的数字。"
        prompt_integer "$1"
    fi
}

# 常见端口数组
common_ports=(22 80 443 53 123)

# Step 1: Check if a firewall is installed
firewall_installed=""
if command -v iptables &>/dev/null; then
    firewall_installed="iptables"
elif command -v ufw &>/dev/null; then
    firewall_installed="ufw"
elif command -v firewalld &>/dev/null; then
    firewall_installed="firewalld"
fi

if [ -n "$firewall_installed" ]; then
    echo "防火墙 ($firewall_installed) 已安装。"
    prompt_yn "是否继续使用当前防火墙？" && {
        echo "保留当前防火墙 ($firewall_installed)。"
    } || {
        echo "移除当前防火墙 ($firewall_installed)..."
        case $firewall_installed in
            "iptables")
                iptables -F
                iptables -X
                iptables -Z
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                ;;
            "ufw")
                ufw disable
                ;;
            "firewalld")
                systemctl stop firewalld
                systemctl disable firewalld
                ;;
        esac
    }
fi

# Step 2: Choose a firewall to install
if [ -z "$firewall_installed" ] || [ $? -eq 1 ]; then
    echo "选择要安装的防火墙:"
    echo "1. iptables"
    echo "2. ufw"
    echo "3. firewalld"
    firewall_to_install=""
    while [ -z "$firewall_to_install" ]; do
        selected_option=$(prompt_integer "请输入相应的数字 (1/2/3): ")
        case $selected_option in
            1)
                firewall_to_install="iptables"
                ;;
            2)
                firewall_to_install="ufw"
                ;;
            3)
                firewall_to_install="firewalld"
                ;;
            *)
                echo "无效的选择，请重新输入。"
                ;;
        esac
    done

    echo "安装 $firewall_to_install..."
    apt-get update
    apt-get install -y $firewall_to_install
fi

# 添加常见端口的规则
case $firewall_to_install in
    "iptables")
        for port in "${common_ports[@]}"; do
            iptables -A INPUT -p tcp --dport $port -j ACCEPT
            iptables -A INPUT -p udp --dport $port -j ACCEPT
        done
        ;;
    "ufw")
        for port in "${common_ports[@]}"; do
            ufw allow $port
        done
        ;;
    "firewalld")
        for port in "${common_ports[@]}"; do
            firewall-cmd --add-port=$port/tcp
            firewall-cmd --add-port=$port/udp
        done
        ;;
esac

# Step 3: Start the selected firewall
case $firewall_to_install in
    "iptables")
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        ;;
    "ufw")
        ufw default deny incoming
        ufw default allow outgoing
        ufw enable
        ;;
    "firewalld")
        systemctl start firewalld
        systemctl enable firewalld
        ;;
esac

# Step 4: Check the current firewall rules
case $firewall_to_install in
    "iptables")
        echo "当前防火墙规则:"
        iptables -L --line-numbers
        ;;
    "ufw")
        echo "当前防火墙规则:"
        ufw status numbered
        ;;
    "firewalld")
        echo "当前防火墙规则:"
        firewall-cmd --list-all
        ;;
esac

# Step 5: Remove specific allowed ports
prompt_yn "是否要移除特定允许的端口?" && {
    read -p "请输入要移除的端口号 (如果有多个，请用逗号分隔): " ports_to_remove
    echo "您输入的要移除的端口号为: $ports_to_remove"
    prompt_yn "确认移除这些端口号?" && {
        case $firewall_to_install in
            "iptables")
                for port in $(echo $ports_to_remove | tr ',' ' '); do
                    iptables -D INPUT -p tcp --dport $port -j ACCEPT
                    iptables -D INPUT -p udp --dport $port -j ACCEPT
                done
                ;;
            "ufw")
                for port in $(echo $ports_to_remove | tr ',' ' '); do
                    ufw delete allow $port
                done
                ;;
            "firewalld")
                for port in $(echo $ports_to_remove | tr ',' ' '); do
                    firewall-cmd --remove-port=$port/tcp
                    firewall-cmd --remove-port=$port/udp
                done
                ;;
        esac
    } || {
        prompt_yn "是否要重新输入要移除的端口号?" && {
            prompt_yn "确认移除这些端口号?" && {
                # Repeat confirmation and removal process
            }
        }
    }
}

# Step 6: Add specific allowed ports
prompt_yn "是否要添加特定允许的端口?" && {
    read -p "请输入要添加的端口号 (如果有多个，请用逗号分隔): " ports_to_add
    echo "您输入的要添加的端口号为: $ports_to_add"
    prompt_yn "确认添加这些端口号?" && {
        case $firewall_to_install in
            "iptables")
                for port in $(echo $ports_to_add | tr ',' ' '); do
                    iptables -A INPUT -p tcp --dport $port -j ACCEPT
                    iptables -A INPUT -p udp --dport $port -j ACCEPT
                done
                ;;
            "ufw")
                for port in $(echo $ports_to_add | tr ',' ' '); do
                    ufw allow $port
                done
                ;;
            "firewalld")
                for port in $(echo $ports_to_add | tr ',' ' '); do
                    firewall-cmd --add-port=$port/tcp
                    firewall-cmd --add-port=$port/udp
                done
                ;;
        esac
    } || {
        prompt_yn "是否要重新输入要添加的端口号?" && {
            prompt_yn "确认添加这些端口号?" && {
                # Repeat confirmation and addition process
            }
        }
    }
}

# Final Step: Show all currently opened ports
echo "当前所有已开放的端口："
case $firewall_to_install in
    "iptables")
        iptables -L INPUT -n | grep ACCEPT
        ;;
    "ufw")
        ufw status numbered | grep ALLOW
        ;;
    "firewalld")
        firewall-cmd --list-ports
        ;;
esac

echo "脚本成功执行完毕。"
