---
title: JavaScript 中对闭包和匿名函数的理解
title_url: understand-JavaScript-closure-anonymous-function
date: 2017-11-29
tags: JavaScript
categories: [JavaScript]
description: JavaScript 中对闭包和匿名函数的理解
---

## 从一个例子带出的问题

完整的使用如下

```
function checkTaskMainJobStatus() {
      for (var i=0; i <$scope.taskMains.length; i ++) {
          (function (taskMain) {
              JobInfoService.searchJob({ 'param':taskMain.id })
                  .then(
                      function (response) {
                          if (response != null && response.length > 0) {
                              if (response[0].activity) {
                                  taskMain.jobStatus = true;
                                  taskMain.jobStatusLabel = '开启';
                              } else {
                                  taskMain.jobStatus = false;
                                  taskMain.jobStatusLabel = '关闭';
                              }
                          } else {
                              taskMain.jobStatus = false;
                              taskMain.jobStatusLabel = '关闭';
                          }
                      },
                      function (errResponse) {
                          console.error('loadJobDetail has error, errResponse = ' + JSON.stringify(errResponse));
                      }
                  );
          })($scope.taskMains[i]);
    
      }
}
```

简写如下

```
function checkTaskMainJobStatus() {
      for (var i=0; i <$scope.taskMains.length; i ++) {
            (function (taskMain) {
                JobInfoService.searchJob({ 'param':taskMain.id })
                  .then(
                      function (response) {
                         // 使用 taskMain 的逻辑
                      },
                      function (errResponse) {
                         // 使用 taskMain 的逻辑
                      }
                  );
            })($scope.taskMains[i]);
      }
}
```

如果按照下面的写法就会出现问题 

```
function checkTaskMainJobStatus() {
      for (var i=0; i <$scope.taskMains.length; i ++) {
            JobInfoService.searchJob({ 'param':$scope.taskMains[i].id })
                  .then(
                      function (response) {
                         // 使用 $scope.taskMains[i] 的逻辑
                      },
                      function (errResponse) {
                         // 使用 $scope.taskMains[i] 的逻辑
                      }
                  );
      }
}
```

原因在于 `$scope.taskMains[i]` 是 for 循环带来的一个局部变量, 而 searchJob 函数返回的 `$promise` 对象在循环结束后仍然使用了无效的局部变量.

而通过匿名函数的方式将 `$scope.taskMains[i]` 局部变量传递给 `$promise` 使用, 在 `$promise` 中使用 `$scope.taskMains[i]` 变量就是闭包使用. 

闭包可以维持（keep alive）这些变量。在上面的例子中，外部函数创建局部变量 `$scope.taskMains[i]` ，并且最终退出；但是，如果任何一个或多个内部函数在外部函数退出后却没有退出，那么内部函数就维持了外部函数的局部数据, 这里的内部函数就是匿名函数.

## 对闭包的理解

只要在一个函数内部出现了另一个函数, 那么内部的函数就是闭包, 外部函数即使已经执行完毕退出了,内部的函数仍然可以使用外部函数的变量,并且该变量对于内部函数来说是不变的.

类似 Java 中的内部类, 外部传递给内部类中方法的变量是 final 修饰过的.

## 对匿名函数的理解

基本形式如下

```
(function ([p1,p2...pN]) {
    // 使用 param1,param2...paramN 的业务逻辑
    // p1 对应 param1, p2 对应 param2, PN 对应 paramN
})([param1,param2...paramN]);
```

在 JavaScript 中 `();` 表示执行, 写成  `(function(){});` 也可以执行, 写成 `(function(){})();` 也可以执行,
如果在第二个小括号中传入参数就相当于给第一个小括号中的函数传入对应的参数.

## 参考

- [闭包，懂不懂由你，反正我是懂了](http://www.cnblogs.com/frankfang/archive/2011/08/03/2125663.html)
- [How do JavaScript closures work?](https://stackoverflow.com/questions/111102/how-do-javascript-closures-work)