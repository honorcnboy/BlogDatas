#!/bin/bash

# 定义需备份网站文件夹完整路径,根据实际自行增加、减少
folders=(
  "/www/wwwroot/abc.com"
  "/www/wwwroot/xyz.com"
  "/opt/abc"
  "/opt/xyz"
)

# 定义压缩文件存储目录,根据实际自行设置
backup_dir="/www/backup/site"

# 定义Onedrive网盘备份上传目录,OD为你的网盘名,Backup为网盘内的目录
onedrive_dir="OD:Backup"

# 定义压缩及上传重试次数
retry_times=5

# 定义日志文件路径,根据实际自行设置
log_file="/root/webbackup.txt"

# 定义日志文件中分隔符
next() {
    printf "%-70s\n" "=" | sed 's/\s/=/g'
}

# 获取当前时间
now=$(date +"%Y%m%d_%H%M%S")

# 定义函数：备份压缩并上传
backup_compress_upload() {
  folder_path="$1"
  folder_name=$(basename $folder_path)
  backup_file="$backup_dir/web_${folder_name}_${now}.tar.gz"
  start_time=$(date +"%Y-%m-%d-%H:%M:%S")
  echo $(next) | tee -a $log_file
  echo "开始备份网站: ${folder_name} [${start_time}]" | tee -a $log_file
  echo "|-开始压缩: ${folder_path}" | tee -a $log_file

# 压缩文件夹
for (( i=1; i<=$retry_times; i++ ))
do
   tar -zcf $backup_file -P $folder_path
  if [ $? -eq 0 ]; then
    echo "|-压缩完成: ${backup_file}" | tee -a $log_file
    echo "|-开始上传: ${onedrive_dir}/${folder_name}/" | tee -a $log_file
    break
  else
    echo "|-压缩失败!" | tee -a $log_file
    rm -f $backup_file
    if [ $i -eq $retry_times ]; then
      break
    fi
    sleep 10s
  fi
done

# 上传文件至Onedrive网盘
  for (( i=1; i<=$retry_times; i++ ))
  do
    rclone copy $backup_file $onedrive_dir/${folder_name}/
    if [ $? -eq 0 ]; then
      echo "|-上传完成: ${onedrive_dir}/${folder_name}/web_${folder_name}_${now}.tar.gz" | tee -a $log_file
      echo "★ 网站备份成功!" | tee -a $log_file
      break
    else
      echo "|-上传失败..." | tee -a $log_file
      if [ $i -eq $retry_times ]; then
        break
      fi
    fi
  done
  echo "" | tee -a $log_file
}

# 开始备份
for folder_path in "${folders[@]}"
do
  backup_compress_upload $folder_path
done

# 结束备份
echo "☆★☆ 全部网站备份结束." | tee -a $log_file
