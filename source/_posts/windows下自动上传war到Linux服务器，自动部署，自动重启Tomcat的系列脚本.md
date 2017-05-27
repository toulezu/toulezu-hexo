---
title: Windows下自动上传war到Linux服务器，自动部署，自动重启Tomcat的系列脚本
title_url: Windows-auto-deploy-war-to-Linux
date: 2016-12-20
tags: [自动部署]
categories: 技术
description: Windows下自动上传war到Linux服务器，自动部署，自动重启Tomcat的系列脚本,用于本地自动化部署
---

## Windows 下自动上传 war 到 Linux 服务器

- 下面的 cmd 脚本通过 Maven 命令执行打包，生成 war
- 通过 pscp 将 war 上传到服务器
- 通过 plink 远程调用 Linux 上的 shell 脚本
- 其中 pscp 来自 PUTTY
- putty_privatekey 用于 plink 无密码登录 Linux，也可以通过用户名和密码的方式
- 其中 test-web-deploy.sh 用于自动部署 war

```
@echo off
set project_path=D:\svn-workspace\test-web
set local_file=%project_path%\target\test-web.war
set putty_privatekey=D:\soft\keys\test-privatekey.ppk
set deploy-shell=test-web-deploy.sh
 
set server_user_1=dev
set server_passwd_1=123
set server_ip_1=10.32.22.61
 
set server_path=/usr/local/apps

echo ---------------------------------------------- execute mvn clean install
D:
cd %project_path%
call mvn clean install -Dmaven.test.skip=true -Ptest
 
echo ---------------------------------------------- upload war file to server 
call pscp -l %server_user_1% -pw %server_passwd_1% -r %local_file% %server_ip_1%:%server_path%

echo ---------------------------------------------- execute %deploy-shell%
call plink -i %putty_privatekey% %server_user_1%@%server_ip_1% sh %deploy-shell%
 
pause
```

## Linux 自动部署 war

- 在下面的脚本是 test-web-deploy.sh，会调用 tomcat_restart.sh，用于重启 Tomcat

```
#!/bin/bash
app_name=test-web
app_path=/usr/local/apps
tomcat_path=/usr/local/soft/tomcat-test-web

cd $app_path
if [ -f ${app_name}.war ];then
    echo find ${app_name}.war, unpack the file then restart the tomcat
    rm -rvf ./${app_name}/*
    mv ./${app_name}.war $app_path/${app_name}/
    cd $app_path/${app_name}
    jar -xvf ${app_name}.war
    rm -rvf ${app_name}.war
  else
    echo not find ${app_name}.war, only restart the tomcat
fi

cd $tomcat_path
sh tomcat_restart.sh
```

## 自动重启 Tomcat

- 下面的脚本是 tomcat_restart.sh，基本思路是通过 Tomcat 安装路径找到进程pid，杀死后再重启

```
#!/bin/bash
# 首先找到tomcat根目录， 确保当前脚本在tomcat根目录下
tomcat_path=/usr/local/soft/tomcat-test-web
echo tomcat path is $tomcat_path

# 找到tomcat的进程id
tomcat_pid=$(ps -ef|grep $tomcat_path|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ')
if [ "$tomcat_pid" ];then
  echo tomcat process id is $tomcat_pid
  # 杀掉tomcat进程
  if
    kill -9 $tomcat_pid
  then
    echo kill tomcat process success
  else
   echo kill tomcat process fail
  fi
else
  echo tomcat is already dead
fi

# 启动tomcat并重定向到日志输出
sh $tomcat_path/bin/startup.sh
tail -f $tomcat_path/logs/catalina.out
```

## 可能遇到的问题

### 执行 `jar -xvf xxx.war` 的时候提示:`/bin/bash: jar: command not found`
### 解决如下

```
cd /usr/bin
sudo ln -s -f /usr/lib/jvm/jdk1.6.0_30/bin/jar
```
**jdk安装目录按自己实际情况更改**

如果提示`javah：commond not found`，于是照葫芦画瓢，输入命令

```
cd /usr/bin
ln -s -f /usr/lib/jvm/jdk1.6.0_30/bin/javah
```

## 总结

- 该系列脚本解决了自动部署问题，非常适用于敏捷开发
- 基于该系列脚本可以实现自动发布系统的开发 :)