# 校园网认证守护

这是一个用于 OpenWrt / ImmortalWrt 的校园网 Dr.COM / ePortal 认证工具，包含后端守护脚本和 LuCI 中文配置界面。

它适合把路由器接入需要网页认证的校园网：路由器负责登录、检测在线状态，断线后自动重新认证。

## 功能

- LuCI 中文配置界面
- 支持立即认证、检测状态、重启服务
- 支持守护模式，掉线后自动重试认证
- 支持多个账号保存和快速切换
- 支持配置认证接口、检测接口、运营商后缀、账号前缀、固定 IP、MAC、AC 参数等
- 运行时自动使用 `curl` 或 `uclient-fetch` 发送请求

## 软件包

项目包含两个包：

- `campus-auth-guardian`：后端脚本、UCI 配置、启动服务
- `luci-app-campus-auth-guardian`：LuCI 网页配置界面

当前发布包为：

- [`campus-auth-guardian_1.0.0-r4_all.ipk`](releases/v1.0.0-r4/campus-auth-guardian_1.0.0-r4_all.ipk)
- [`luci-app-campus-auth-guardian_1.0.0-r4_all.ipk`](releases/v1.0.0-r4/luci-app-campus-auth-guardian_1.0.0-r4_all.ipk)
- [`SHA256SUMS`](releases/v1.0.0-r4/SHA256SUMS)

校验值：

```text
1a01a950c935d2f5a12b4578c57734bcce22c9661cea97c1910d82a50bccad1f  campus-auth-guardian_1.0.0-r4_all.ipk
9b377541533c2297f59271a33b89343259b563e82b4d99bdd396651cbfacb92a  luci-app-campus-auth-guardian_1.0.0-r4_all.ipk
```

## 安装

先把两个 `.ipk` 上传到路由器，例如上传到 `/tmp`，然后 SSH 登录路由器执行：

```sh
cd /tmp
opkg install campus-auth-guardian_1.0.0-r4_all.ipk
opkg install luci-app-campus-auth-guardian_1.0.0-r4_all.ipk
/etc/init.d/rpcd reload
rm -f /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/
```

如果系统缺少 HTTP 客户端，请安装其中一个：

```sh
opkg update
opkg install curl
```

或者：

```sh
opkg update
opkg install uclient-fetch
```

## LuCI 使用方法

安装后进入 LuCI：

```text
服务 -> 校园网认证守护
```

建议配置顺序：

1. 在“基础设置”里填写认证接口地址和在线检测接口地址。
2. 在“账号管理”里添加一个或多个账号。
3. 回到“账号设置”，在“当前使用账号”里选择要使用的账号。
4. 点击“保存并应用”。
5. 点击“立即认证”测试登录。
6. 点击“检测状态”确认是否在线。
7. 确认可用后，开启“启用服务”和“启用守护模式”。

## 多账号切换

“账号管理”可以保存多个账号，每个账号包含：

- 名称
- 学号或账号
- 密码
- 运营商
- 运营商后缀
- 账号前缀
- 固定 IP

在“账号设置”的“当前使用账号”下拉框里选择账号后，后端认证会优先使用这个账号的信息。

如果选择“手动填写账号”，则使用“账号设置”里手动填写的学号、密码、运营商等字段，兼容旧版本的单账号配置。

## 运营商和账号格式

默认账号格式为：

```text
,0,学号@运营商
```

常见运营商值：

- `campus`：校园网
- `cmcc`：中国移动
- `unicom`：中国联通
- `telecom`：中国电信

如果学校要求特殊后缀，可以填写“运营商后缀”。

如果不需要追加 `@运营商`，把“运营商后缀”填写为：

```text
none
```

如果学校不需要 `,0,` 前缀，可以把“账号前缀”留空。

## 常见问题

### 点击按钮提示“没有权限”

请确认已经安装新版 LuCI 包，并刷新 rpcd 和 LuCI 缓存：

```sh
/etc/init.d/rpcd reload
rm -f /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/
```

然后重新登录 LuCI。

### 检测状态提示未确认在线

这通常是在线检测接口或关键词不匹配。请检查：

- “在线检测接口地址”是否能在浏览器或路由器上访问
- “在线成功关键词”是否出现在接口响应里
- “门户页关键词”是否符合学校认证页返回内容

可以查看日志：

```sh
cat /tmp/campus_auth_guardian.log
```

### 认证失败

请检查：

- 账号、密码是否正确
- 运营商后缀是否符合学校要求
- 认证接口地址是否正确
- 固定 IP 是否需要填写
- 路由器是否已经能访问认证服务器

## 命令行使用

立即认证：

```sh
/usr/bin/campus-auth-guardian.sh auth
```

检测在线状态：

```sh
/usr/bin/campus-auth-guardian.sh check
```

重启守护服务：

```sh
/etc/init.d/campus-auth-guardian restart
```

查看日志：

```sh
cat /tmp/campus_auth_guardian.log
```

## 开机自启

在 LuCI 里开启“启用服务”后，服务会随系统启动。

也可以通过命令行启用：

```sh
uci set campus-auth-guardian.main.enabled='1'
uci set campus-auth-guardian.main.guardian_enabled='1'
uci commit campus-auth-guardian
/etc/init.d/campus-auth-guardian enable
/etc/init.d/campus-auth-guardian restart
```

## 卸载

```sh
opkg remove luci-app-campus-auth-guardian
opkg remove campus-auth-guardian
rm -f /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/
/etc/init.d/rpcd reload
```

## 从源码构建

准备对应目标平台的 OpenWrt / ImmortalWrt SDK，把 `package/campus-auth-guardian` 和 `package/luci-app-campus-auth-guardian` 放到 SDK 的 `package/` 目录后执行：

```sh
make defconfig
make package/campus-auth-guardian/compile V=s
make package/luci-app-campus-auth-guardian/compile V=s
```

编译完成后，包会生成在 SDK 的 `bin/packages/` 目录下。

当前预构建包使用 ImmortalWrt 24.10.3 `mediatek/filogic` SDK 构建，包架构为 `all`。
