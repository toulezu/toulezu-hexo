---
title: 在 Linux 上监控 Tomcat 是否关闭, 如果关闭自动重启
title_url: Linux-monitor-Tomcat
date: 2017-05-15
tags: [Linux,系统监控,Tomcat]
categories: 技术
description: 在 Linux 上监控 Tomcat 是否关闭, 如果关闭自动重启
---

## 新建cron文件`auto.cron`如下

- 每分钟执行一次监控
- 每天早上10点清理Tomcat的 catalina.out 文件

```
# auto restart tomcat
*/1 * * * * sh /opt/AppData/cron/shell/tomcat_check_and_start.sh
0 10 * * * cat /dev/null > /opt/AppData/tomcat/logs/catalina.out
```

## crontab的文件格式

分 | 时 | 日 | 月 | 星期 | 要执行的命令
---|---|---|---|---|---
分钟0～59 | 小时0～23（0表示子夜）| 日1～31 | 月1～12 | 星期0～7（0和7表示星期天）| 要运行的命令

## 监控tomcat进程脚本如下

```
#!/bin/bash
# 首先找到tomcat根目录， 确保当前脚本在tomcat根目录下
tomcat_path=/opt/AppData/tomcat-datamonitor

# 找到tomcat的进程id
tomcat_pid=$(ps -ef|grep $tomcat_path|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ')
if [ -z "$tomcat_pid" ];then
  sh $tomcat_path/bin/startup.sh
  echo tomcat is dead,restart at `date "+%Y-%m-%d %H:%M:%S"` >> $tomcat_path/tomcat_auto_restart.log
fi
```

## 使定时监控生效

```
crontab auto.cron
```

**注意:执行该命令前先执行下`crontab -l`看看已经存在的定时任务,以避免覆盖已经存在的定时任务**

使用 `crontab -l`可以列出当前用户生效的定时任务

## 参考

- [linux下添加定时任务](http://blog.csdn.net/hi_kevin/article/details/8983746)
- [crontab 定时任务](http://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/crontab.html)