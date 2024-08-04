Debian_IPv6() {
    iName=$(ip add | grep "^2: " | awk -F'[ :]' '{print $3}')
    dhclient -6 $iName # 临时开启IPv6
    echo $iName # 人工查看网卡是否正确
    cp /etc/network/interfaces /root
    sed -i "$ a iface $iName inet6 dhcp" /etc/network/interfaces

    # 重启网络服务
    ifdown $iName && ifup $iName

    # 验证IPv6配置是否生效
    sleep 2s
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
