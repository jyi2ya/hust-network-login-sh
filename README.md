把 [hust-network-login](https://github.com/black-binary/hust-network-login) 用 shell 抄了一遍

# HUST-Network-Login-sh

极简主义的华中科技大学校园网络认证工具，支持有线和无线网络。下载即用，大小约为 2.1k，有依赖。为路由器等嵌入式设备开发，支持所有带 posix shell 和 unix2dos、nc 等工具的主流硬件软件平台。No Python, Has Dependencies, Is Bullshit.

## 使用

src/main.sh 是可执行文件。

配置文件只有两行, 第一行为用户名，第二行为密码，例如

```text
M2020123123
mypasswordmypassword
```

保存为 my.conf

然后运行

```shell
./hust-network-login-sh ./my.conf
```

my.conf 是刚才的配置文件，你可以换成其他名字。

连接成功后，程序将会每间隔 15s 测试一次网络连通性。如果无法连接则进行重新登陆。

## 编译

编译本地平台只需要使用 `cp`。

```shell
cp src/main.sh ./hust-network-login-sh
```

## 依赖

`nc` `unix2dos` `awk` `grep` `printf` `sed` `sleep` 以及一个 POSIX 兼容的 `sh`。

## 相似项目

* 项目起源：[hust-network-login](https://github.com/black-binary/hust-network-login)
* 面向基于 busybox 的路由器的版本：[hust-network-login-sh](https://github.com/jyi2ya/hust-network-login-sh)
* 面向 MCU arduino 的嵌入式的版本：[hust-network-login-esp](https://github.com/vaaandark/hust-network-login-esp)
