---
title: HTML 倒计时自动跳转功能实现以及 setInterval() 方法介绍
title_url: understand-HTML-countdown-jump-setInterval-practice
date: 2019-10-11
tags: [HTML,JavaScript]
categories: HTML
description: HTML 倒计时自动跳转功能实现以及 setInterval() 方法介绍
---

## 1 概述

进行一些处理，进入到一个成功或者失败页面后实现倒计时 5 秒后跳转到其他页面。

## 2 方法

#### 2.1 设置 head 标签中的 meta 元素

```html
<meta http-equiv="refresh" content="5; url='http://ckjava.com'"/>
```

- content 属性值中的 5 表示 5秒钟，`url='http://ckjava.com'` 表示跳转到其他页面的地址


#### 2.2 用 javascript 实现

具体如下

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <!--<meta http-equiv="refresh" content="3;url='index.html#!/publishPlan'" >-->
    <title>确认成功</title>
    <script type="text/javascript">
        function countDown() {
            // 获取初始时间
            var time = document.getElementById("timeTotal");

            // 获取到id为time标签中的数字时间
            if (parseInt(time.innerHTML) == 0) {
                // 等于0时清除计时，并跳转该指定页面
                window.location.href = "index.html#!/publishPlan";
            } else {
                time.innerHTML = String(parseInt(time.innerHTML) - 1);
            }
        }

        window.onload = function() {
            // 1000毫秒调用一次
            window.setInterval(function () { countDown() }, 1000);
        }
    </script>
    <style type="text/css">
        .tip {
            font-size: 20px;
            font-family: "Microsoft YaHei UI";
            font-weight: bold;
            margin: 200px auto;
            text-align: center;
        }

        .mt20 {
            margin-top: 20px;
        }

        .bold {
            font-weight: bold;
            color: red;
            background-color: white;
        }

        .pr3 {
            padding-right: 3px;
        }
    </style>
</head>
<body>
<div class="tip">
    <div class="bold">给CTO发送紧急申请邮件成功！</div>
    <div class="mt20">
        <span id="timeTotal" class="pr3">5</span>秒后返回首页 或 <a href="index.html#!/publishPlan">点击链接直接返回</a>。
    </div>
</div>
</body>
</html>
```

## 3 setInterval() 方法

#### 3.1 setInterval() 方法介绍

1. setInterval() 方法可按照指定的周期（以毫秒计）来调用函数或计算表达式。
2. setInterval() 方法会不停地调用函数，直到 clearInterval() 被调用或窗口被关闭。由 setInterval() 返回的 ID 值可用作 clearInterval() 方法的参数。
3. 定义：`setInterval(function, milliseconds, param1, param2, ...)` 或者 `setInterval(code, milliseconds)`

参数 | 描述
---|---
code/function |	必需。要调用一个代码串，也可以是一个函数。
milliseconds  |	必须。周期性执行或调用 code/function 之间的时间间隔，以毫秒计。
param1, param2, ...  |	可选。 传给执行函数的其他参数（IE9 及其更早版本不支持该参数）。
 	
- 提示： 1000 毫秒= 1 秒。
- 提示： 如果你只想执行一次可以使用 setTimeout() 方法。

#### 3.2 使用实例

1. 每三秒（3000 毫秒）弹出 "Hello"，代码如下

```
setInterval(function(){ alert("Hello"); }, 3000);
```

2. 使用一个代码字符串的情况，代码如下

```
setInterval('alert("Hello");', 3000);
```

#### 3.3 setInterval() 方法需要注意的地方

对于上面的第二种方法，其中用了 `window.setInterval(function () { countDown() }, 1000);`，注意 setInterval 方法中的第一个参数是一个函数，如果写成 `window.setInterval(countDown(), 1000);` 是无法实现效果的。

因为写成 `countDown()` 其实是执行了一次 `countDown()` 函数，而该函数是没有返回值的，所以无法实现倒计时效果。

## 4 参考

- [window-setinterval-not-working](https://stackoverflow.com/questions/14549371/window-setinterval-not-working)
- [Window setInterval() 方法](https://www.runoob.com/jsref/met-win-setinterval.html)