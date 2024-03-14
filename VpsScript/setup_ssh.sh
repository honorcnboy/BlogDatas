#!/bin/bash

# 函数：报错并退出
error_exit() {
    echo "出现错误,请检查!"
    exit 1
}

echo "开始设置秘钥登录"

# 步骤 2：提示用户输入公钥
echo -n "输入公钥: "
read public_key || error_exit

# 步骤 3：保存/更新公钥文件
mkdir -p /root/.ssh || error_exit
echo "$public_key" >> /root/.ssh/authorized_keys || error_exit
echo "已保存/更新公钥文件."

# 步骤 4：设置公钥文件权限
chmod 700 /root/.ssh || error_exit
chmod 600 /root/.ssh/authorized_keys || error_exit
echo "公钥文件权限成功."

# 步骤 5：修改sshd_config文件
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config || error_exit
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || error_exit
echo "'/etc/ssh/sshd_config'文件修改成功."

# 步骤 6：重启sshd服务
service sshd restart || error_exit
echo "秘钥登录设置成功，并关闭密码登录.请验证无误后再关闭窗口."

# 删除当前脚本文件
rm -- "$0"
