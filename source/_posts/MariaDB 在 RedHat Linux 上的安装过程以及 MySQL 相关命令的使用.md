---
title: MariaDB 在 RedHat Linux 上的安装过程以及 MySQL 相关命令的使用
title_url: Linux-MariaDB-setup-MySql
date: 2017-05-15
tags: [Linux,MariaDB,MySql]
categories: MariaDB
description: MariaDB 在 RedHat Linux 上的安装过程以及 MySQL 相关命令的使用
---

## 安装

```
yum install mariadb-server mariadb
```
如果提示已经有存在的包了,通过以下命令卸载

```
yum -y remove mysql-libs*
```

## 启动 MariaDB.service

```
systemctl start mariadb.service
```

## 设置开机启动 MariaDB.service

```
systemctl enable mariadb.service
```

## 验证是否安装成功

```
ps -wef | grep mariadb | grep -v grep
```

## 修改root密码

MariaDB Server 默认root密码为空,这里通过登入mysql后修改密码

```
[root@localhost ~]# mysql -u root
```

输入上面的命令后提示 `MariaDB [(none)]>`,然后输入以下命令:

```
use mysql;
update user set password=PASSWORD('new_password') where User='root';
flush privileges;
quit
```

## 通过命令登录mysql

```
[root@localhost ~]# mysql -u root -p
```

输入上面的命令后提示输入密码.


## mysql 命令行窗口基本使用

- `show databases;` 显示数据库列表
- `use datamonitor;` 切换到指定的数据库
- `show tables;` 显示某个数据库下所有
- `desc dm_mail_info;` 显示某个表的详细信息
- `source /etc/appData/datamonitor.sql` 将sql备份数据导入到数据库中

## 参考

- [RedHat Linux RPM方式安装MySQL5.6](http://blog.csdn.net/chenjinge7/article/details/46582527)