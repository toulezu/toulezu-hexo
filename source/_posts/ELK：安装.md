---
title: ELK：安装
date: 2016-06-10
tags: ELK
categories: 技术
description: ELK 初步认识和安装
---

#ELK：安装

ELK 是 Elasticsearch,Logstash,Kibana的合称，依赖Java才能运行。

- ElasticSearch 是开源分布式搜索引擎，能够实时处理，分析日志

- Logstash 统一对应用程序日志进行收集管理

- Kibana 是一个为 Logstash 和 ElasticSearch 提供的日志分析的 Web 接口。可使用它对日志进行高效的搜索、可视化、分析等各种操作

他们之间的依赖关系如下：

Kibana <- ElasticSearch <- Logstash

## 安装 Java

- 到`http://www.oracle.com/technetwork/java/javase/downloads/index.html`下载`jdk-8u91-linux-x64.gz`

- 上传到`Ubuntu`上的`/usr/local/soft`目录下，执行`tar -xvf jdk-8u91-linux-x64.gz`解压

- 将下面的Java配置追加到`/etc/profile`文件中，然后执行`source /etc/profile`让配置立即生效
```
# set Java environment
JAVA_HOME=/usr/local/soft/jdk1.8.0_91
PATH=$JAVA_HOME/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME
export PATH
export CLASSPATH
```
- 执行`java -version`和`javac -version`都能返回当前安装的Java的版本号，说明安装成功


- 如果当前用户对目录没有权限，执行`sudo chown -R dev:dev /usr/local/soft`，其中`dev:dev`表示dev用户在dev用户组。



## 安装 Elasticsearch

- 到`https://www.elastic.co/downloads/elasticsearch`下载 elasticsearch-2.3.3.tar.gz

- 上传到`Ubuntu`上的`/usr/local/soft`目录下，执行`tar -xvf elasticsearch-2.3.3.tar.gz`解压

- 执行`sh elasticsearch-2.3.3/bin/elasticsearch`

- 打开浏览器输入`http://localhost:9200/`，返回如下内容说明安装成功:
```
{
  "name" : "Earth Lord",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "2.3.3",
    "build_hash" : "218bdf10790eef486ff2c41a3df5cfa32dadcfde",
    "build_timestamp" : "2016-05-17T15:40:04Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.0"
  },
  "tagline" : "You Know, for Search"
}
```
## 安装 Logstash

- 在`https://www.elastic.co/downloads/logstash`下载`logstash-2.3.2.tar.gz`

- 上传到`Ubuntu`上的`/usr/local/soft`目录下，执行`tar -xvf logstash-2.3.2.tar.gz`解压

- 执行`sh logstash-2.3.2/bin/logstash -e 'input { stdin { } } output { stdout {} }'`，提示
```
Settings: Default pipeline workers: 1
Pipeline main started
```
说明安装成功，输入任意内容将会打印刚才的输入。

## 安装 Kibana

- 在`https://www.elastic.co/downloads/kibana`下载`kibana-4.5.1-linux-x64.tar.gz`

- 上传到`Ubuntu`上的`/usr/local/soft`目录下，执行`tar -xvf kibana-4.5.1-linux-x64.tar.gz`解压

- 编辑`vi kibana-4.5.1-linux-x64/config/kibana.yml`，确保kibana和elasticsearch 关联起来
```
elasticsearch.url: "http://localhost:9200"
```

- 编辑`vi elasticsearch-2.3.3/config/elasticsearch.yml`，追加下面一行，并重启elasticsearch服务
```
http.cors.enabled: true
```

- 执行`sh kibana-4.5.1-linux-x64/bin/kibana`启动kibana，在浏览器中输入`http://localhost:5601`，即可访问kibana

参考：
[CentOS下使用ELK套件搭建日志分析和监控平台](http://blog.csdn.net/i_chips/article/details/43309415)
[http://www.cnblogs.com/danbo/p/5220516.html](ELK日志分析系统)
[Logstash实践: 分布式系统的日志监控](http://www.cnblogs.com/yiwenshengmei/p/use_logstash_collect_log.html)