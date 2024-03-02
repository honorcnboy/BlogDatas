#!/bin/bash

# 检测是否安装了ethtool和nmcli，如果没有则安装
if ! command -v ethtool &> /dev/null || ! command -v nmcli &> /dev/null; then
    echo "ethtool或nmcli未安装，正在安装..."
    sudo apt update
    sudo apt install -y ethtool network-manager
    echo "ethtool和nmcli已安装"
else
    echo "ethtool和nmcli已安装"
fi

# 获取所有网络接口的名称
interfaces=$(nmcli device status | awk '{print $1}' | grep -v DEVICE)

# 循环遍历每个网络接口
for interface in $interfaces; do
    # 使用nmcli增加环缓冲的大小
    echo "Setting ring buffer size for interface $interface..."
    sudo nmcli connection modify $interface txqueuelen 10000

    # 调优网络设备积压队列以避免数据包丢弃
    echo "Tuning network device backlog for interface $interface..."
    sudo nmcli connection modify $interface rxqueuelen 10000

    # 增加NIC的传输队列长度
    echo "Increasing NIC transmission queue length for interface $interface..."
    sudo nmcli connection modify $interface transmit-hash-policy layer2+3
done

# 检查系统虚拟化类型，如果是 KVM，则关闭 TSO 和 GSO
if [ "$(sudo dmidecode -s system-product-name)" == "KVM" ]; then
    echo "系统虚拟化类型为 KVM，正在关闭 TSO 和 GSO..."
    for interface in $(nmcli device status | awk '{print $1}' | grep -v DEVICE); do
        sudo ethtool -K $interface tso off gso off
        echo "TSO 和 GSO 已关闭于接口 $interface"
    done
else
    echo "系统虚拟化类型非 KVM，不需要关闭 TSO 和 GSO。"
fi

# 备份 sysctl.conf
cp /etc/sysctl.conf /etc/sysctl.conf.bak



# 打开文件描述符限制 将硬限制和软限制都设置为65535，以允许更多的文件描述符
echo "* hard nofile 65535" >> /etc/security/limits.conf 
echo "* soft nofile 65535" >> /etc/security/limits.conf

# 调整内核参数 通过 here 文档（heredoc）向 /etc/sysctl.conf 文件中添加内核参数
cat << EOF >> /etc/sysctl.conf
# 调整网络参数 增加 TCP 最大连接数
net.core.somaxconn = 65535
# 增大接收缓冲区和发送缓冲区的大小
net.core.rmem_max = 16777216 
net.core.wmem_max = 16777216
# 增加 TCP 最大半连接队列长度
net.ipv4.tcp_max_syn_backlog = 65535
# 增加 TIME-WAIT 状态的最大数量
net.ipv4.tcp_max_tw_buckets = 65535
# 允许 TIME-WAIT 状态的 socket 重新用于新的 TCP 连接
net.ipv4.tcp_tw_reuse = 1
# 减少 TIME-WAIT 状态的超时时间
net.ipv4.tcp_fin_timeout = 10
# 禁用 TCP 连接的慢启动算法
net.ipv4.tcp_slow_start_after_idle = 0
# 设置 TCP Keepalive 的时间间隔和尝试次数
net.ipv4.tcp_keepalive_time = 300 
net.ipv4.tcp_keepalive_probes = 5 
net.ipv4.tcp_keepalive_intvl = 15
# 开启 SYN Cookie 机制以防止 SYN 攻击
net.ipv4.tcp_syncookies = 1
# 开启 TCP 时间戳选项以提高性能
net.ipv4.tcp_timestamps = 1
# 开启 TCP 窗口缩放选项以提高性能
net.ipv4.tcp_window_scaling = 1
# 设置 TCP 接收窗口广告窗口大小
net.ipv4.tcp_rmem = 4096 87380 16777216
# 减少 TCP 性能峰值
net.ipv4.tcp_limit_output_bytes = 131072
# 修改系统 initcwnd 参数
net.ipv4.tcp_slow_start_after_idle = 0
# 开启 TCP Fast Open (TFO)
net.ipv4.tcp_fastopen = 3
# 修改系统的 Ring Buffer 大小和队列数量
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.optmem_max = 65536
net.core.netdev_budget = 300
# 优化 txqueuelen 参数
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_mtu_probing = 1
# IPv6的优化
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.ipv6.conf.all.accept_ra_pinfo = 1
net.ipv6.conf.default.accept_ra_pinfo = 1
net.ipv6.conf.all.accept_ra_defrtr = 1
net.ipv6.conf.default.accept_ra_defrtr = 1
net.ipv6.conf.all.autoconf = 1
net.ipv6.conf.default.autoconf = 1
net.ipv6.conf.all.max_addresses = 16
net.ipv6.conf.default.max_addresses = 16
net.ipv6.conf.all.accept_redirects = 2
net.ipv6.conf.default.accept_redirects = 2
net.ipv6.conf.all.router_solicitations = 0
net.ipv6.conf.default.router_solicitations = 0
net.ipv6.conf.all.dad_transmits = 0
net.ipv6.conf.default.dad_transmits = 0
EOF

# 应用新的内核参数 使用 sysctl 命令重新加载 /etc/sysctl.conf 文件中的配置
sysctl -p

# 调整网络队列处理算法（Qdiscs），优化TCP重传次数
for interface in $interfaces; do
    echo "Tuning network queue disciplines (Qdiscs) and TCP retransmission for interface $interface..."
    sudo tc qdisc add dev $interface root fq
    sudo tc qdisc change dev $interface root fq maxrate 90mbit
    sudo tc qdisc change dev $interface root fq burst 15k
    sudo tc qdisc add dev $interface ingress
    sudo tc filter add dev $interface parent ffff: protocol ip u32 match u32 0 0 action connmark action mirred egress redirect dev ifb0
    sudo tc qdisc add dev ifb0 root sfq perturb 10
    sudo ip link set dev ifb0 up
    sudo ethtool -K $interface tx off rx off
done

# 调整TCP和UDP流量的优先级
for interface in $interfaces; do
    echo "Setting priority for TCP and UDP traffic on interface $interface..."
    sudo iptables -A OUTPUT -t mangle -p tcp -o $interface -j MARK --set-mark 10
    sudo iptables -A OUTPUT -t mangle -p udp -o $interface -j MARK --set-mark 20
    sudo iptables -A PREROUTING -t mangle -i $interface -j MARK --set-mark 10
    sudo iptables -A PREROUTING -t mangle -p udp -i $interface -j MARK --set-mark 20
done

# 检查是否已经安装了 BBR 模块
if lsmod | grep -q "^tcp_bbr "; then
    echo "BBR 模块已安装"
else
    # 安装 BBR 模块
    echo "安装 BBR 模块..."
    sudo modprobe tcp_bbr
    echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# 验证 BBR 是否已启用
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR 已启用"
else
    echo "BBR 启用失败，请手动检查您的系统设置"
fi

echo "系统优化设置完成。"
