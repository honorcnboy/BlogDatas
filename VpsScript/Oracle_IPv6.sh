Debian_IPv6() {
    iName=$(ip add | grep "^2: " | awk -F'[ :]' '{print $3}')
    dhclient -6 $iName # 临时开启IPv6
    echo $iName # 人工查看网卡是否正确
    cp /etc/network/interfaces /root

    # 查找并添加 auto $iName 、iface $iName inet6 dhcp 、accept_ra 2
    if ! grep -q "^auto $iName" /etc/network/interfaces; then
        iName_line=$(grep -n "^iface $iName" /etc/network/interfaces | cut -d: -f1)
        if [ -n "$iName_line" ]; then
            sed -i "${iName_line}i auto $iName" /etc/network/interfaces
        else
            echo -e "auto $iName" >> /etc/network/interfaces
        fi
    fi

    if grep -q "^iface $iName inet6 dhcp" /etc/network/interfaces; then
        sed -i "/^iface $iName inet6 dhcp/a\    accept_ra 2" /etc/network/interfaces
    else
        echo -e "\niface $iName inet6 dhcp\n    accept_ra 2" >> /etc/network/interfaces
    fi

    # 重启网络服务
    ifdown $iName && ifup $iName

    # 验证IPv6配置是否生效
    sleep 2s
    echo "如果PING失败，请尝试: sudo service networking restart && sudo dhclient -6 -r $iName && sudo dhclient -6 $iName && ip a ,查看IPv6是否获取正常，如有多条则释放旧地址: sudo ip -6 addr del <格式:0000:0000.../123> dev $iName
 后再次尝试PING. 如仍有问题, 请自行Google或GPT."
    ping -c 4 ipv6.google.com
}

Ubuntu_IPv6() {
    yamlName=$(find /etc/netplan/ -iname "*.yaml")
    iName=$(ip add | grep "^2: " | awk -F'[ :]' '{print $3}')
    dhclient -6 $iName
    MAC=$(ip add | grep "link/ether.*brd" | awk -F' ' '{print $2}')
    IPv6=$(ip add | grep "inet6.*global" | awk -F' ' '{print $2}')
    if [[ ${#IPv6} -lt 5 ]]; then echo "Can't get IPv6"; exit 1; fi

    cp $yamlName /root/

    cat <<EOF >$yamlName
network:
   ethernets:
      ens3:
          dhcp4: true
          dhcp6: false
          match:
              macaddress: $MAC
          addresses:
              - $IPv6
          set-name: $iName
   version: 2
EOF

    # 应用新的网络配置
    netplan apply

    # 验证IPv6配置是否生效
    sleep 2s
    ping -c 4 ipv6.google.com
}

myOS=$(hostnamectl | sed -n 's_.*System: \(\S*\).*_\1_p')
# Ubuntu, Debian

if [[ "$myOS" =~ "Ubuntu" ]]; then
    echo "Ubuntu"
    Ubuntu_IPv6
elif [[ "$myOS" =~ "Debian" ]]; then
    echo "Debian"
    Debian_IPv6
fi
