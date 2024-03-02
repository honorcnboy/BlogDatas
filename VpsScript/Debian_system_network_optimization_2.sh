#!/bin/bash

# 获取网卡接口名称
nic_interface=$(ip addr | grep 'state UP' | awk '{print $2}' | sed 's/.$//')

# 安装 ethtool（如果未安装）
if ! [ -x "$(command -v ethtool)" ]; then
    apt-get update
    apt-get -y install ethtool
fi

# 检查网卡丢包计数
echo "Checking NIC's missed packet count..."
ethtool -S $nic_interface | grep -e rx_no_buffer_count -e rx_missed_errors -e rx_fifo_errors -e rx_over_errors

# 增加网卡接收缓冲区大小
echo "Increasing the size of NIC's receive buffer..."
ethtool -g $nic_interface
# 设置所需的 RX 描述符值（例如，2048）
ethtool -G $nic_interface rx 2048

# 增加查询通道数
echo "Increasing the number of query channels..."
ethtool -l $nic_interface
# 设置所需的 combined 通道数（例如，4）
ethtool -L $nic_interface combined 4

# 调整中断协作设置
echo "Adjusting interrupt coalescing settings..."
ethtool -c $nic_interface
# 设置所需的 rx-usecs 和 tx-usecs 值（例如，10）
ethtool -C $nic_interface rx-usecs 10 tx-usecs 10

# 检查软中断丢包数
echo "Checking softIRQ misses..."
cat /proc/net/softnet_stat

# 增加 NIC 的接收队列大小
echo "Increasing the size of NIC's backlog..."
# 设置所需的接收队列大小（例如，10000）
sysctl -w net.core.netdev_max_backlog=10000

# 增加 netdev_budget 和 netdev_budget_usecs
echo "Increasing netdev_budget and netdev_budget_usecs..."
# 设置所需的 netdev_budget 和 netdev_budget_usecs 值（例如，50000 和 8000）
sysctl -w net.core.netdev_budget=50000
sysctl -w net.core.netdev_budget_usecs=8000

# 设置 net.ipv4.tcp_moderate_rcvbuf
echo "Enabling receive buffer auto-tuning..."
sysctl -w net.ipv4.tcp_moderate_rcvbuf=1

# 启用 TCP 窗口缩放
echo "Enabling TCP window scaling..."
sysctl -w net.ipv4.tcp_window_scaling=1

# 设置最大 TCP 窗口大小
echo "Setting maximum TCP window size..."
sysctl -w net.ipv4.tcp_workaround_signed_windows=1

# 增加最大文件描述符数
echo "Increasing the maximum number of file descriptors..."
# 设置所需的最大文件描述符数（例如，1000000）
sysctl -w fs.file-max=1000000
sysctl -w fs.nr_open=1000000

# 增加最大端口范围
echo "Increasing the maximum port range..."
# 设置所需的最大端口范围（例如，1024-65535）
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# 增加完全建立的套接字队列的最大长度
echo "Increasing the maximum queue length of completely established sockets..."
# 设置所需的最大队列长度（例如，10000）
sysctl -w net.core.somaxconn=10000

# 增加不附加到任何用户文件句柄的 TCP 套接字的最大数量
echo "Increasing the maximum number of orphaned connections..."
# 设置所需的最大孤立连接数（例如，10000）
sysctl -w net.ipv4.tcp_max_orphans=10000

# 增加 SYN_RECV 状态套接字的最大数量
echo "Increasing the maximum number of SYN_RECV sockets..."
# 设置所需的最大 SYN_RECV 套接字数（例如，10000）
sysctl -w net.ipv4.tcp_max_syn_recv=10000

# 增加 TIME_WAIT 状态套接字的最大数量
echo "Increasing the maximum number of sockets in TIME_WAIT state..."
# 设置所需的最大 TIME_WAIT 套接字数（例如，10000）
sysctl -w net.ipv4.tcp_max_tw_buckets=10000

# 快速丢弃 FIN-WAIT-2 状态的套接字
echo "Quickly discarding sockets in FIN-WAIT-2 state..."
# 设置所需的超时时间（例如，10）
sysctl -w net.ipv4.tcp_fin_timeout=10

# 设置 TCP 接收和发送缓冲区大小
echo "Setting TCP socket buffer sizes..."
# 设置所需的接收和发送缓冲区大小（例如，134217728 和 33554432）
sysctl -w net.ipv4.tcp_adv_win_scale=-2
sysctl -w net.core.rmem_max=134217728
sysctl -w net.ipv4.tcp_rmem="8192 262144 134217728"
sysctl -w net.core.wmem_max=33554432
sysctl -w net.ipv4.tcp_wmem="8192 
