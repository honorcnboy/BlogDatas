#!/bin/bash

# 定义网站/数据库压缩文件存储目录
site_dir="/www/backup/site"
db_dir="/www/backup/database"

# 定义网盘备份上传的网站/数据库目录
netdrive_site_dir="GloryCN_OD:HonorBT/site"
netdrive_db_dir="GloryCN_OD:HonorBT/database"

# 获取当前系统日期
now_date=$(date +"%Y%m%d")

# 定义日志文件中分隔符
next() {
    printf "%-70s\n" "=" | sed 's/\s/=/g'
}

# 获取当前系统日期及时间
now_time=$(date +"%Y-%m-%d-%H:%M:%S")

# 统计符合要求的网站备份压缩文件总数
total_site_files=$(ls ${site_dir}/web_*.tar.gz | grep -c "${now_date}")

echo "★开始上传网站备份文件 [${now_time}]"
echo "-- 待上传文件 ${total_site_files} 个："
next

# 遍历${site_dir}下所有的压缩包文件
for file in ${site_dir}/web_*.tar.gz; do
    # 获取文件名中的日期部分
    file_date=$(echo ${file} | grep -oE "[0-9]{8}")

    # 判断文件名中的日期部分是否与当前系统日期相同
    if [ "${file_date}" = "${now_date}" ]; then
        # 解析site_url部分
        site_url=$(echo ${file} | grep -oE "web_[^_]+_[0-9]{8}_[0-9]{6}" | cut -d "_" -f 2)

        # 初始化尝试次数
        try_times=0

        # 尝试上传文件，最多重试5次
        while [ ${try_times} -lt 5 ]; do
            # 更新尝试次数
            try_times=$((try_times+1))

            # 组装上传文件名
            upload_file="web_${site_url}_${file_date}_$(date +"%H%M%S").tar.gz"

            # 尝试上传文件
            rclone copy "${file}" "${netdrive_site_dir}/${site_url}/"

            # 判断上传是否成功
            if [ $? -eq 0 ]; then
                echo "${upload_file} 上传成功，网盘路径：${netdrive_site_dir}/${site_url}/${upload_file}"
                break
            else
                echo "第 ${try_times} 次重试上传 ${file} 到 ${netdrive_site_dir}/${site_url}/${upload_file}"
            fi
        done

        # 判断是否上传成功
        if [ ${try_times} -eq 5 ]; then
            echo "web_${site_url}_${file_date}.tar.gz 上传失败，已重试5次，放弃上传。"
            failed_files+=("${file}")
        else
            success_files+=("${file}")
        fi
    fi
done

# 统计上传结果
success_num=${#success_files[@]}
success_files_str=$(echo "${success_files[*]}" | sed 's/ /, /g')
failed_num=${#failed_files[@]}
failed_files_str=$(echo "${failed_files[*]}" | sed 's/ /, /g')

next

# 输出上传结果
echo "☆网站备份文件上传完成！"
echo ""

next

# 统计符合要求的文件总数
total_db_files=$(ls ${db_dir}/db_*.sql.gz | grep -c "${now_date}")

echo "★开始上传数据库备份文件 [${now_time}]"
echo "-- 待上传文件 ${total_db_files} 个:"
next

# 遍历${db_dir}下所有的压缩包文件
for file in ${db_dir}/db_*.sql.gz; do
    # 获取文件名中的日期部分
    file_date=$(echo ${file} | grep -oE "[0-9]{8}")

    # 判断文件名中的日期部分是否与当前系统日期相同
    if [ "${file_date}" = "${now_date}" ]; then
        # 解析db_url部分
        filename=$(basename "${file}")
        db_url=$(echo "${filename#db_}" | sed -E 's/_[0-9]{8}_.*//;s/_$//')

        # 初始化尝试次数
        try_times=0

        # 尝试上传文件，最多重试5次
        while [ ${try_times} -lt 5 ]; do
            # 更新尝试次数
            try_times=$((try_times+1))

            # 组装上传文件名
            upload_file="db_${db_url}_${file_date}_$(date +"%H%M%S").sql.gz"

            # 尝试上传文件
            rclone copy "${file}" "${netdrive_db_dir}/${db_url}"

            # 判断上传是否成功
            if [ $? -eq 0 ]; then
                echo "${upload_file} 上传成功，网盘路径：${netdrive_db_dir}/${db_url}/${upload_file}"
                break
            else
                echo "第 ${try_times} 次重试上传 ${file} 到 ${netdrive_db_dir}/${db_url}/${upload_file}"
            fi
        done

        # 判断是否上传成功
        if [ ${try_times} -eq 5 ]; then
            echo "db_${db_url}_${file_date}.sql.gz 上传失败，已重试5次，放弃上传。"
            failed_files+=("${file}")
        else
            success_files+=("${file}")
        fi
    fi
done

# 统计上传结果
success_num=${#success_files[@]}
success_files_str=$(echo "${success_files[*]}" | sed 's/ /, /g')
failed_num=${#failed_files[@]}
failed_files_str=$(echo "${failed_files[*]}" | sed 's/ /, /g')

next

# 输出上传结果
echo "☆数据库备份文件上传完成！"
echo ""
next
echo "★网站 / 数据库备份文件上传完成！"
echo "-上传成功 ${success_num} 个文件，文件名[本地完整路径]："
for success_file in "${success_files[@]}"; do
  echo " ${success_file}"
done
echo "-上传失败 ${failed_num} 个文件，文件名[本地完整路径]："
for failed_file in "${failed_files[@]}"; do
  echo " ${failed_file}"
done
echo "***请检查上传失败文件，并手动上传."
