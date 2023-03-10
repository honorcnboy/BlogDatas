#!/bin/bash

start_time=$(date +%s)

# Detect system type

if [[ $(uname -s) == "Linux" ]]; then
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu-based system
        INSTALL_CMD="apt -y install"
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS-based system
        INSTALL_CMD="yum -y install"
    else
        echo "Unsupported Linux distribution" >&2
        exit 1
    fi
else
    echo "This script only supports Linux systems" >&2
    exit 1
fi

# Install unzip

if ! command -v unzip &> /dev/null
then
    echo "unzip not found, installing..."
    sudo $INSTALL_CMD unzip
else
    echo "unzip already installed"
fi

# install besttrace

if [ ! -f "besttrace2023" ]; then
    mkdir /tmp/besttrace
    cd /tmp/besttrace
    wget https://github.com/honorcnboy/BlogDatas/releases/download/AutoBestTrace/besttrace4linux.zip
    unzip besttrace*.zip
    if [[ $(uname -m) == "x86_64" ]]; then
    mv besttrace /root/besttrace2023
    elif [[ $(uname -m) == "i386" ]]; then
    mv besttrace32 /root/besttrace2023
    elif [[ $(uname -m) == "aarch64" ]]; then
    mv besttracearm /root/besttrace2023
    fi
    cd /root/
    rm -rf /tmp/besttrace
    chmod +x besttrace2023
fi

## start to use besttrace

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear

log_file="/root/besttracelog.txt"
header="
#==========================================
# Project: AutoBesttrace
# Updated: 2023.03.06
# Author: CNBoy
# Blog:   https://cnboy.org
# Github: https://github.com/honorcnboy
#==========================================
"

# Add the following line to output the header in green color

echo "$header" | tee $log_file

next

ip_list=(219.141.244.2 221.130.33.60 202.106.50.1 202.96.209.5 211.136.150.66 211.95.52.116 202.96.128.86 211.136.192.6 210.21.4.130 61.128.192.68 218.201.4.3 221.5.203.98 61.134.1.5 111.19.239.36 113.200.112.30)
ip_addr=(北京电信 北京移动 北京联通 上海电信 上海移动 上海联通 广州电信 广州移动 广州联通 重庆电信 重庆移动 重庆联通 西安电信 西安移动 西安联通)

# ip_len=${#ip_list[@]}

for i in {0..14}
do
    echo "检测地区&运营商: ${ip_addr[$i]}"
    ./besttrace2023 -q 1 -g cn ${ip_list[$i]}
    next
done > >(tee -a $log_file)

end_time=$(date +%s)
total_time=$((end_time - start_time))
minutes=$((total_time / 60))
seconds=$((total_time % 60))

printf "脚本运行时间：%d分%d秒\n" "$minutes" "$seconds" | tee -a $log_file

echo -e "\n检测结果已保存至 ${log_file}，请自行查看"

## Delete Besttrace2023 Files

rm -f /root/besttrace2023
