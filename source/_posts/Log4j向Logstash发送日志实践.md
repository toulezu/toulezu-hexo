---
title: Log4j向Logstash发送日志实践
title_url: log4j-logstash-practice
date: 2016-07-05
tags: log4j,logstash
categories: 技术
description: Log4j向Logstash发送日志实践
---

## 在logstash中配置log4j

- 在logstash的配置文件中增加如下配置
```
input {
  stdin {
  }
  log4j {
    type => "log4j-test"
    port => 4560
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}

output {
  elasticsearch {
        hosts => ["localhost:9200"]
        index => "logstash-%{type}-%{+YYYY.MM.dd}"
		document_type => "%{type}"
  }
  stdout { codec => rubydebug }
}
```
- 其中`input`下的`port`表示本机开放4560端口接收网络中其他主机应用程序中log4j发送过来的日志，也可以指定其他未被占用的端口，`type` 为接收的日志起的别名

- `output`下的`elasticsearch`部分表示logstash将接收的日志发送给本机的elasticsearch，其端口为9200，`index` 表示生成索引的名称

- 这里的配置是服务器模式，也就是logstash作为日志服务器开放一个端口，网络中其他主机主动发送日志

## 在应用中配置 log4j

- log4j用SocketAppender将日志发送到指定的主机和端口，在log4j.xml中配置如下
```
<appender name="LOGSTASH" class="org.apache.log4j.net.SocketAppender">
	<param name="RemoteHost" value="192.168.37.118"/>
	<param name="Port" value="4560"/>	
	<param name="ReconnectionDelay" value="10000"/>
	<param name="LocationInfo" value="true"/>
	<param name="Threshold" value="INFO"/>
	<param name="Application" value="web-api" />
</appender>
```

- 其中`RemoteHost`和`Port`表示logstash主机的ip和开放的端口，`Threshold` 表示将何种等级的日志发送到logstash，`Application`表示日志来源于哪个应用

- 如果使用log4j.properties文件，配置如下
```
log4j.appender.socket=org.apache.log4j.net.SocketAppender  
log4j.appender.socket.RemoteHost=192.168.37.118
log4j.appender.socket.Port=4560
log4j.appender.socket.ReconnectionDelay=10000
log4j.appender.socket.LocationInfo=true
log4j.appender.socket.Threshold=INFO
log4j.appender.socket.Application=web-api
```

- 关于`SocketAppender`中的`RemoteHost`和`Port`等字段的含义参考`SocketAppender`的源码


参考如下：

[logstash的log4j插件使用说明](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-log4j.html)

