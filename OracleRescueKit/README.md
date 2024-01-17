## Oracle Rescue Kit
      
### Ubuntu 20.04 AMD [更新时间：2024-01-13]

- 基于官方原版 Canonical-Ubuntu-20.04 打包

- 密码登录（用户名 / 密码）：root / CNBoy.org
  * 实际执行恢复过程中，出现了一些概率，在恢复后root密码变为执行恢复命令的VPS的root密码。原因暂时不明。所以如果SSH登录时root密码出现错误，请使用你执行恢复命令的那台VPS的root密码进行尝试。

- 秘钥登录：将秘钥文件 backup 导入本地SSH登录工具，无密码登录（请勿使用backup.pub，这是服务器上存储的公钥）

- 恢复包链接：https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/Ubuntu20.04.amd.img.gz

- 私钥链接：https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/backup

      
### Ubuntu 20.04 ARM [更新时间：2024-01-13]

- 基于官方原版 Canonical-Ubuntu-18.04-aarch64 打包

- 密码登录（用户名 / 密码）：root / CNBoy.org
  * 实际执行恢复过程中，出现了一些概率，在恢复后root密码变为执行恢复命令的VPS的root密码。原因暂时不明。所以如果SSH登录时root密码出现错误，请使用你执行恢复命令的那台VPS的root密码进行尝试。

- 秘钥登录：将秘钥文件 backup 导入本地SSH登录工具，无密码登录（请勿使用backup.pub，这是服务器上存储的公钥）

- 恢复包链接：https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/Ubuntu20.04.arm.img.gz

- 私钥链接：https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/backup

### dabian 10 ARM

- 网络精简版

- 用户名：root

- 密码：10086.fit

https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/dabian10.arm.img.gz
