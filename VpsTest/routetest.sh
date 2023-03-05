#!/bin/bash

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

# Install mtr

if ! command -v mtr &> /dev/null
then
    echo "mtr not found, installing..."
    sudo $INSTALL_CMD mtr
else
    echo "mtr already installed"
fi

clear

## start test route

now=$(date +"%y%m%d%H%M")
log_file="/root/routetest${now}.txt"
header="
#==========================================
# Project: Routetest
# Version: 1.0
# Author: CNBoy
# Blog:   https://cnboy.org
# Github: https://github.com/honorcnboy
#==========================================
"
time {
echo -e "$header\n正在进行测试, 请稍等...\n-------------------------------------------------------\n" | tee $log_file

ip_list=(219.141.244.2 221.130.33.60 202.106.50.1 202.96.209.5 211.136.150.66 211.95.52.116 202.96.128.86 211.136.192.6 210.21.4.130 61.128.192.68 218.201.4.3 221.5.203.98 61.134.1.5 111.19.239.36 113.200.112.30)
ip_addr=(北京电信 北京移动 北京联通 上海电信 上海移动 上海联通 广州电信 广州移动 广州联通 重庆电信 重庆移动 重庆联通 西安电信 西安移动 西安联通)

for i in {0..14}; do
	mtr -r --n --tcp ${ip_list[$i]} > /tmp/routetest.log
	grep -q "59\.43\." /tmp/routetest.log
	if [ $? == 0 ];then
		grep -q "202\.97\."  /tmp/routetest.log
		if [ $? == 0 ];then
		echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;32m电信CN2 GT\033[0m"
		else
		echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;31m电信CN2 GIA\033[0m"
		fi
	else
		grep -q "202\.97\."  /tmp/routetest.log
		if [ $? == 0 ];then
			grep -q "219\.158\." /tmp/routetest.log
			if [ $? == 0 ];then
			echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;33m联通169\033[0m"
			else
			echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;34m电信163\033[0m"
			fi
		else
				grep -q "218\.105\."  /tmp/routetest.log
				if [ $? == 0 ];then
				echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;35m联通9929\033[0m"
				else
					grep -q "219\.158\."  /tmp/routetest.log
					if [ $? == 0 ];then
						grep -q "219\.158\.113\." /tmp/routetest.log
						if [ $? == 0 ];then
						echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;33m联通AS4837\033[0m"
						else
						echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;33m联通169\033[0m"
						fi
					else				
						grep -q "223\.120\."  /tmp/routetest.log
						if [ $? == 0 ];then
						echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;35m移动CMI\033[0m"
						else
							grep -q "221\.183\."  /tmp/routetest.log
							if [ $? == 0 ];then
							echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:\033[1;35m移动cmi\033[0m"
							else
							echo -e "检测地区&运营商:${ip_addr[i]}\t回程线路:其他"
						fi
					fi
				fi
			fi
		fi
	fi
echo 
done > >(tee -a $log_file)

echo -e "脚本运行时间：$(date +%s)秒" | tee -a $log_file
}
echo -e "-------------------------------------------------------\n本脚本测试结果为TCP回程路由, 仅供参考.\n" | tee -a $log_file
echo "检测结果已保存至 ${log_file}，请自行查看"

rm -f /tmp/routetest.log
