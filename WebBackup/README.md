#### 网站文件夹自动备份

因宝塔ondrive网站备份一直以来经常会出现上传出错导致备份失败的情况，至今没有修复。所以自己写了一个网站文件夹自动备份脚本，在BT中设定定时运行该脚本，对需备份的网站文件夹进行压缩并上传到onedrive网盘

- 根据自定义的网站完整目录，逐一进行压缩、上传
- 自行在脚本中设置：需备份的网站完整目录、压缩文件存储目录、Onedrive网盘备份上传目录、日志文件路径、及压缩及上传重试次数，并配置好rclone，即可开始使用
- 如果需要备份至Googdrive，直接将脚本中第15行：onedrive_dir="OD:Backup"中的“OD:Backup”更改为Googdrive网盘名跟网盘内的目录即可
- 如果不在本机中保存备份文件，直接在脚本中第65行“echo "☆网站备份成功!" | tee -a $log_file”后添加一行：rm -f $backup_file，即可


**运行命令**：
```bash
wget -qO- https://raw.githubusercontent.com/honorcnboy/BlogDatas/main/WebBackup/webbackup.sh | bash 
```
