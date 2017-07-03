---
title: Phabricator 在 Windows 环境上的部署与二次开发
title_url: Phabricator-Windows-setup
date: 2017-07-03
tags: Phabricator
categories: [技术,PHP]
description: Phabricator 在 Windows 环境上的部署与二次开发
---

## 基本开发工具

- [eclipse-php-oxygen-R-win32-x86_64.zip](http://mirror.rise.ph/eclipse/technology/epp/downloads/release/oxygen/R/eclipse-php-oxygen-R-win32-x86_64.zip)
- [wampserver3.0.6_x64_apache2.4.23_mysql5.7.14_php5.6.25-7.0.10.exe](https://wampserver-64bit.en.softonic.com/)
- [git-for-windows-2.13.2](https://git-for-windows.github.io/)

其中 wampserver 安装在 `C:\wamp64`

eclipse-php 需要在 `Window -> Preferences -> PHP` 设置安装好的 PHP,Debug,Execution Environments 等信息,具体参考->[这里](http://tiame.iteye.com/blog/1454234)

## Phabricator 部署

在 eclipse-php 中新建一个 php 项目, 地址在 `D:\php-workspace\phabricator`, 在 Git Bash 中进入该目录, 执行如下命令拉取 Phabricator 代码

```
git clone https://github.com/phacility/libphutil.git
git clone https://github.com/phacility/arcanist.git
git clone https://github.com/phacility/phabricator.git
```

完毕后, 将 arcanist, libphutil, phabricator 三个文件夹 以 File System 的形式导入到php项目中

启动 wampserver, 在浏览器中打开 `http://localhost/index.php` 进入 WampServer 管理页面,在下面的 Tools 栏中点击 `Add a Virtual Host` 链接创建一个VirtualHost, 

第一栏填写 test.pha.com
第二栏不填
第三栏填写 D:\php-workspace\phabricator\phabricator\webroot

点击保存, 成功后会在 WampServer 主页下面的 Your VirtualHost 栏中增加 test.pha.com 站点, 这时候在 `C:\Windows\System32\drivers\etc` 中会增加如下信息

```
::1 test.pha.com
```

在 `C:\wamp64\bin\apache\apache2.4.23\conf\extra\httpd-vhosts.conf` 中会增加如下信息

```
<VirtualHost *:80>
	ServerName test.pha.com
	DocumentRoot "d:/php-workspace/phabricator/phabricator/webroot"
	
	RewriteEngine on
    RewriteRule ^(.*)$          /index.php?__path__=$1  [B,L,QSA]
	<Directory  "d:/php-workspace/phabricator/phabricator/webroot/">
		Options +Indexes +Includes +FollowSymLinks +MultiViews
		AllowOverride All
		Require local
	</Directory>
</VirtualHost>
```

这个时候就可以通过 `test.pha.com` 访问 Phabricator 了,如果提示数据库未配置,或者需要执行 `upgrade` 操作

那么通过 Git Bash cd 到 `D:\php-workspace\phabricator\phabricator` 目录, 执行如下命令来设置 mysql 的相关信息

```
php setup/manage_config.php set mysql.host localhost
php setup/manage_config.php set mysql.port 3306
php setup/manage_config.php set mysql.user root
php setup/manage_config.php set mysql.pass 123
```

通过如下命令进行 upgrade

```
php scripts/sql/manage_storage.php upgrade
```

这里之所以不能和官方wiki那样通过 `./bin/config set mysql.host localhost` 的原因是 bin 目录下面在 Linux 环境中都是符号链接, 通过 Git Clone 到 Windows 环境后变成了文件

## 扩展phabricator验证

- [扩展phabricator验证](https://popozhu.github.io/2016/05/31/扩展phabricator验证/)

## 参考

- [Phabricator 用户手册](https://admin.phacility.com/book/phacility/)
- [VirtualHost 配置参考](https://httpd.apache.org/docs/2.4/vhosts/examples.html)
- [Eclipse集成PDT+XDebug调试PHP脚本](http://pjdong1990.iteye.com/blog/1610305)
- [Phabricator 技术文档](https://secure.phabricator.com/diviner/)
- [Phabricator 二次开发入门](https://secure.phabricator.com/book/phabcontrib/)
