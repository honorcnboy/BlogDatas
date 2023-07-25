#### AutoBesttrace - 回程路由检测

适用于 AMD / ARM 架构 ubuntu / debian / centos 系统的三网回程路由检测脚本

- 北京、上海、广州、重庆、西安 5地三网回程路由检测，并打印检测结果

运行命令：
```bash
wget -qO- https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/autobesttrace.sh | bash 
```

#### Routetest - 回程线路检测

适用于 AMD / ARM 架构 ubuntu / debian / centos 系统的三网回程线路检测脚本

- 北京、上海、广州、重庆、西安 5地三网回程线路检测，将线路专业代码直观显示为：电信CN2 GT、电信CN2 GIA、联通169、电信163、联通9929、联通4837、移动CMI，并打印检测结果

运行命令：
```bash
wget -qO- https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/routetest.sh | bash 
```

#### ReHostname - 修改系统主机名

运行命令：
```bash
wget https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/rehostname.sh && chmod +x rehostname.sh && ./rehostname.sh
```

Fix命令：
```bash
wget https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/fixhostname.sh && chmod +x fixhostname.sh && ./fixhostname.sh
```

#### RestartNetwork - 解决重启网卡失效

适用于 AMD / ARM 架构 debian 系统。甲骨文等主机商服务器DD后 sudo service networking restart 或 sudo /etc/init.d/networking restart 重启网卡命令失效，重启网卡会导致SSH失联的问题。

运行命令：
```bash
wget https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/restartnetwork.sh && chmod +x restartnetwork.sh && bash restartnetwork.sh
```

#### FireWallSetup - UFW安装及一键设置

运行命令：
```bash
wget https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/VpsScript/firewall_setup.sh && chmod +x firewall_setup.sh && ./firewall_setup.sh
```
