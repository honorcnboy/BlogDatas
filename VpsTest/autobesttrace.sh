#!/bin/bash

echo -e "\033[32m"
cat << "EOF"
#======================================
# Project: testrace
# Version: 1.2
# Author: nanqinlang
# Blog:   https://sometimesnaive.org
# Github: https://github.com/nanqinlang
#======================================
EOF
echo -e "\033[0m"

# install unzip

if ! command -v unzip &> /dev/null
then
    echo "unzip not found, installing..."
    sudo apt -y install unzip
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

# Add the following line to output the header in green color

echo -e "\033[32m#======================================\n# Project: testrace\n# Version: 1.2\n# Author: nanqinlang\n# Blog:   https://sometimesnaive.org\n# Github: https://github.com/nanqinlang\n#======================================\033[0m"

next

ip_list=(219.141.244.2 211.136.17.107 202.106.50.1  202.96.209.5 211.136.150.66 211.95.52.116 202.96.128.86 211.136.192.6 210.21.4.130 61.128.192.68 218.201.4.3 221.5.203.98 61.134.1.5 111.19.239.36 113.200.112.30)
ip_addr=(北京电信 北京移动 北京联通 上海电信 上海移动 上海联通 广州电信 广州移动 广州联通 重庆电信 重庆移动 重庆联通 西安电信 西安移动 西安联通)

# ip_len=${#ip_list[@]}

now=$(date +"%y%m%d%H%M")
log_file="/root/besttrace${now}.txt"

for i in {0..14}
do
    echo ${ip_addr[$i]}
    ./besttrace2023 -q 1 -g cn ${ip_list[$i]}
    next
done > >(tee -a $log_file)

echo "运行结果已保存至 ${log_file}，请自行查看。"

## Delete Besttrace2023 Files

rm -f /root/besttrace2023
