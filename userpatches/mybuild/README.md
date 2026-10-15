# mybuild

本配置为 Orange Pi 5 Pro 镜像添加无人值守初始化。
入口为 [own build 工作流](../../.github/workflows/build.yml)。

## 仓库机密

在 **Settings → Secrets and variables → Actions → Repository secrets** 添加以下六项。

| 机密名称 | 用途 |
| --- | --- |
| ROOT_PASSWORD | root 密码。 |
| USER_NAME | 普通用户名。以小写字母开头；允许数字、下划线和连字符；最多 32 字符；禁止 root。 |
| USER_PASSWORD | 普通用户密码。 |
| WIFI_SSID | Wi-Fi 热点名。最多 32 个 UTF-8 字节。 |
| WIFI_PASSWORD | WPA/WPA2 个人网络密码。支持 8–63 个可打印 ASCII 字符，或 64 位十六进制密钥。 |
| IMAGE_PASSWORD | 镜像解压密码。使用独立强密码。 |

任意一项机密未设置或为空时，工作流打印警告并整体切换为普通模式。
普通模式不注入账户或 Wi-Fi 凭据，也不加密镜像。
准备脚本会清除上次生成的私有输入，避免复用旧凭据。
六项机密齐全但内容非法时，工作流仍报错停止。
所有机密均禁止换行和空字符。

## 镜像默认值

- 私有模式：首次启动的控制台自动登录执行 Armbian 原生账户预设。
- 普通模式：保留 Armbian 默认账户和交互式首次登录流程，不预设 Wi-Fi。
- 普通用户权限和自动登录清理由 Armbian 原生流程管理。
- 私有模式在镜像封装时即替换默认 root 密码。
- 时区为上海。默认语言为简体中文，字符集为 UTF-8。
- 私有模式下，NetworkManager 自动连接 Wi-Fi，使用 DHCP 和 IPv6 自动配置。
- 临时目录使用 Armbian 的 zram 压缩 ext4，不使用普通 tmpfs。
- 保留 zram 服务和原有压缩日志。禁用 zram swap。
- 临时目录保留默认逻辑容量：物理内存的一半。

私有模式的账户预设和 Wi-Fi 配置包含明文凭据，仅允许 root 读取。
Armbian 在初始化成功后删除账户预设，保留 Wi-Fi 配置。
预设执行依赖 Armbian 的控制台自动登录，不增加自定义启动服务。
Wi-Fi 使用 NetworkManager 原生连接文件，因为现有自定义脚本移除了 Netplan。
解密镜像和构建磁盘均属于敏感数据。归档加密不加密安装后的文件系统。

## 发布产物

私有模式发布加密 7z 压缩包，启用 AES-256 和文件名加密。
普通模式发布未加密 xz 压缩包，不执行加密步骤。
同时发布归档 SHA-256 校验文件，以及已有 Debian 软件包。
归档通过完整性检查后，才删除原始镜像。
不发布原始镜像、镜像元数据或构建日志。

私有镜像使用 7-Zip 解压。在密码提示处输入 IMAGE_PASSWORD 对应的值。
普通镜像直接解压，无需密码。
每次只上传当前模式对应的镜像格式。
已有 Release 附件不受影响。手动清理不再需要的历史产物。

## 本地构建

私有构建需将上述六项机密导出为环境变量。
普通构建无需设置机密。
使用 Python 3 运行[机密准备脚本](../../.github/scripts/prepare-mybuild.py)。
通过 [mybuild 构建配置](../config-mybuild.conf)启动构建，保留现有板卡和发行版参数。
选择 NetworkManager 网络栈，保留原始镜像输出；参数见[工作流](../../.github/workflows/build.yml)。
私有构建完成后，使用 Bash 运行[加密脚本](../../.github/scripts/encrypt-images.sh)。
普通构建使用 xz 压缩；完整命令见[工作流](../../.github/workflows/build.yml)。
构建结束后删除生成的私有目录；位置见[准备脚本](../../.github/scripts/prepare-mybuild.py)。
Git 忽略私有目录。
