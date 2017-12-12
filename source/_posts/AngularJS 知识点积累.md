---
title: AngularJS 知识点积累
title_url: AngularJS-basic
date: 2017-09-15
tags: AngularJS
categories: [AngularJS]
description: AngularJS 知识点积累
---

## [如何动态插入删除dom节点](http://yijiebuyi.com/blog/7702aba213aec9de43b129b3d2f3b30c.html)
```
$('div[name=father]').html(
  $compile('<input type="text" ng-model="person.name" /> <input type="input" ng-model="person.age" value="{{person.age}}" /><a ng-show="$index!=0" style="color:red;" ng-click="del($index)">移除</a>'
  )($scope)
);
```

- [HTML Compiler](https://docs.angularjs.org/guide/compiler)

## [ng-click 如何获取触发事件对象或者this](http://blog.csdn.net/a576736858/article/details/62039286)

`ng-click="addPackage($event,111)"` 传递一个$event对象
通过事件对象 `$event.target`  获取事件源
```
//动态添加数据  
$scope.addPackage = function(myevent,deviceType){  
    //获取item对象  
    var htmlObj = $(myevent.target).closest(".float_left");  
    var deviceName = htmlObj.find("div.font_16").html();  
    var jsonObj = {  
        "deviceType":deviceType,//设备类型，唯一标识，用于判断是否已经添加  
        "deviceName":deviceName //设备的名称  
    };  
    //判断数据是否已经选中了  
    if(!this.hasDevice(deviceType)){  
        //给$scope.lists添加数据  
        this.lists.push(jsonObj);  
    }  
};  
```

## [如何在页面加载的时候执行一个方法](https://stackoverflow.com/questions/15458609/how-to-execute-angular-controller-function-on-page-load)

使用 [`ng-init`](https://docs.angularjs.org/api/ng/directive/ngInit) 指令

```
// register controller in html
<div data-ng-controller="myCtrl" data-ng-init="init()"></div>

// in controller
$scope.init = function () {
    // check if there is query in url
    // and fire search in case its value is not empty
};
```

## [使用 `ng-repeat` 来实现增加一行/删除一行的效果](http://lib.csdn.net/article/angularjs/33158)

```javascript
$scope.printInfo = function () {
        for (var i = 0; i < $scope.showVBs.length; i++) {
            console.log($scope.showVBs[i]);
        }
    };

$scope.showVBs = [{
    "Tag": "Tag1",
    "NO": "No1",
    "remarks": "remarks1"
}, {
    "Tag": "Tag2",
    "NO": "No2",
    "remarks": "remarks2"
}];
$scope.BDetailsAdd = function () {
    $scope.showVBs.push({});
};
$scope.BDetailsDel = function (Count) {
    $scope.showVBs.splice(Count, 1);
};

```

```html
<form role="form" name="editForm">
    <div class="row">
        <div class="col-md-12">
            <div class="row  panel panel-default panel-body">
                <div class="col-md-offset-1 panel panel-default">
                    <label>{{'Details'}}</label>
                    <input type="button" class="btn btn-info" value="增加" ng-click="BDetailsAdd()">
                    <input type="button" class="btn btn-danger" value="打印信息" ng-click="printInfo()">
                </div>
                <div class="vBaggages" ng-repeat="vba in showVBs">
                    <div class="form-group col-md-2 col-md-offset-1">
                        <input type="button" class="btn btn-info" value="删" ng-click="BDetailsDel($index)">
                        <input type="text" class="form-control pull-right" ng-model="vba.Tag"
                               placeholder="Tag" style="width:70%">
                    </div>
                    <div class="form-group col-md-2 col-md-offset-1">
                        <input type="text" class="form-control pull-right" ng-model="vba.NO"
                               placeholder="No.">
                    </div>
                    <div class="form-group col-md-5 col-md-offset-1">
                        <input type="text" class="form-control pull-right" ng-model="vba.remarks"
                               placeholder="Remarks">
                    </div>
                </div>
            </div>
        </div>
    </div>
</form>
```

## [如何构建一个 SpringBoot + angularJS web 应用](http://websystique.com/spring-boot/spring-boot-angularjs-spring-data-jpa-crud-app-example/)

## [如何安装 AngularJS 的 ngStorage 模块](http://blog.legacyteam.info/2014/12/ngstorage-localstorage-module-for-angularjs/)

错误提示如下

```
Error: [$injector:modulerr] Failed to instantiate module ngStorage due to:
Error: [$injector:nomod] Module 'ngStorage' is not available! You either misspelled the module name or forgot to load it. If registering a module ensure that you specify the dependencies as the second argument.
```

解决方法如下

在项目根目录下执行安装(uninstall 是卸载)

```
bower install ngstorage
```
```
bower ngstorage#*               cached https://github.com/gsklee/ngStorage.git#0.3.11
bower ngstorage#*             validate 0.3.11 against https://github.com/gsklee/ngStorage.git#*
bower ngstorage#^0.3.11        install ngstorage#0.3.11

ngstorage#0.3.11 bower_components\ngstorage
└── angular#1.5.11

```
然后在项目中的 bower.json 文件中添加相关依赖

```
"dependencies": {
    "ng-js-tree": "~0.0.7",
    "angular-ui-select": "^0.19.6",
    "ngstorage": "0.3.11"
  },
```

## [AngularJS 如何跨域访问 SpringBoot API](https://stackoverflow.com/questions/19825946/how-to-add-a-filter-class-in-spring-boot)

错误描述如下

```
XMLHttpRequest cannot load http://localhost:8011/api/task_main. No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:3000' is therefore not allowed access.
```

解决方法

添加一个 Filter 配置

```java
import javax.servlet.Filter;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

import com.ctrip.payment.filter.RemoteAccessFilter;

@Configuration
@EnableWebMvc
public class WebAppConfig extends WebMvcConfigurerAdapter {

	@Bean
	public FilterRegistrationBean someFilterRegistration() {
	    FilterRegistrationBean registration = new FilterRegistrationBean();
	    registration.setFilter(remoteAccessFilter());
	    registration.addUrlPatterns("/api/*");
	    //registration.addInitParameter("paramName", "paramValue");
	    registration.setName("remoteAccessFilter");
	    registration.setOrder(1);
	    return registration;
	} 

	public Filter remoteAccessFilter() {
	    return new RemoteAccessFilter();
	}
}
```

具体 Filter 如下

```java
import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;

public class RemoteAccessFilter implements Filter {
	@Override
	public void init(FilterConfig filterConfig) throws ServletException {

	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
		
		// ref:http://www.cnblogs.com/1000px/p/4666247.html
		HttpServletResponse resp = (HttpServletResponse) response;
		resp.setHeader("Access-Control-Allow-Origin", "*");
		resp.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT");
		resp.setHeader("Access-Control-Allow-Headers", "Accept,x-requested-with,content-type");
		
		chain.doFilter(request, response);
	}

	@Override
	public void destroy() {
	}

}
```

- [AngularJS跨域请求](http://www.cnblogs.com/1000px/p/4666247.html)

## AngularJS 如何判断字符串或者对象是否为空

在 AngularJs 中判断对象是否为空，可以使用 angular.equals，如下

```
if (obj == null || angular.equals({}, obj)) {
 // 为空
}
```

如果是一个字段

```
if (obj == null || angular.equals('', obj.trim())) {
 // 为空
}
```

## [关于 datePicker 和 timePicker 的组合使用](https://angular-ui.github.io/bootstrap/)

- html

```
<div class="row datepicker">
	<div class="col-md-2">
	   <label>开始时间</label>
	   <p class="input-group">
		  <input type="text" readonly class="form-control" uib-datepicker-popup="yyyy-MM-dd" datepicker-options="datePickerOptions" ng-model="clogDateTime.clogFromDate" is-open="fromDateStatus.isOpen" close-text="Close" />
		  <span class="input-group-btn">
			 <button type="button" class="btn btn-default" ng-click="fromDateOpen()"><i class="glyphicon glyphicon-calendar"></i></button>
		  </span>
	   </p>
	</div>
	<div class="col-md-2">
	   <uib-timepicker show-seconds="true" ng-change="clogFromTimeChanged()" ng-model="clogDateTime.clogFromTime" show-meridian="false"></uib-timepicker> {{ (clogDateTime.clogFromDate != null && clogDateTime.clogFromTime != null) ? (taskSubInfo.fromDate = (clogDateTime.clogFromDate | date:'yyyy-MM-dd')  + ' ' + (clogDateTime.clogFromTime | date:'HH:mm:ss')) : null }}
	</div>
	<div class="col-md-2">
	   <button type="button" class="btn btn-sm btn-danger" ng-click="resetFromDateTime()">重置开始时间</button>
	</div>
	<div class="col-md-2">
	   <label>结束时间</label>
	   <p class="input-group">
		  <input type="text" readonly class="form-control" uib-datepicker-popup="yyyy-MM-dd" datepicker-options="datePickerOptions" ng-model="clogDateTime.clogToDate" is-open="toDateStatus.isOpen" close-text="Close" />
		  <span class="input-group-btn">
			 <button type="button" class="btn btn-default" ng-click="toDateOpen()"><i class="glyphicon glyphicon-calendar"></i></button>
		  </span>
	   </p>
	</div>
	<div class="col-md-2">
	   <uib-timepicker show-seconds="true" ng-change="clogToTimeChanged()" ng-model="clogDateTime.clogToTime" show-meridian="false"></uib-timepicker> {{ (clogDateTime.clogToDate != null && clogDateTime.clogToTime != null) ? (taskSubInfo.toDate = (clogDateTime.clogToDate | date:'yyyy-MM-dd')  + ' ' + (clogDateTime.clogToTime | date:'HH:mm:ss')) : null }}
	</div>
	<div class="col-md-2">
	   <button type="button" class="btn btn-sm btn-danger" ng-click="resetToDateTime()">重置结束时间</button>
	</div>
</div>
```

- js

```
// 将日期和时间作为对象进行考虑
$scope.clogDateTime = {};

$scope.resetFromDateTime = function () {
  $scope.clogDateTime.clogFromDate = null;
  $scope.clogDateTime.clogFromTime = null;
  $scope.taskSubInfo.fromDate = null;
};

$scope.resetToDateTime = function () {
  $scope.clogDateTime.clogToDate = null;
  $scope.clogDateTime.clogToTime = null;
  $scope.taskSubInfo.toDate = null;
};
	  
// 提交的时候
if ($scope.taskSubInfo.fromDate == null || angular.equals($scope.taskSubInfo.fromDate.trim(), '')) {
  $scope.taskSubInfo.fromDate = null;
}
if ($scope.taskSubInfo.toDate == null || angular.equals($scope.taskSubInfo.toDate.trim(), '')) {
  $scope.taskSubInfo.toDate = null;
}

// 加载的时候	  
var dateTimeReg = /^(?:19|20)[0-9][0-9]-(?:(?:0[1-9])|(?:1[0-2]))-(?:(?:[0-2][1-9])|(?:[1-3][0-1])) (?:(?:[0-2][0-3])|(?:[0-1][0-9])):[0-5][0-9]:[0-5][0-9]$/;

if ($scope.taskSubInfo.fromDate != null
  && !angular.equals($scope.taskSubInfo.fromDate.trim(), '')
  && dateTimeReg.test($scope.taskSubInfo.fromDate)) {
  try {
	  $scope.clogDateTime.clogFromDate = new Date($scope.taskSubInfo.fromDate);
	  $scope.clogDateTime.clogFromTime = new Date($scope.taskSubInfo.fromDate);
  } catch (e) {
	  console.log('invalid fromDate:'+$scope.taskSubInfo.fromDate);
  }
}
if ($scope.taskSubInfo.toDate != null
  && !angular.equals($scope.taskSubInfo.toDate.trim(), '')
  && dateTimeReg.test($scope.taskSubInfo.toDate)) {
  try {
	  $scope.clogDateTime.clogToDate = new Date($scope.taskSubInfo.toDate);
	  $scope.clogDateTime.clogToTime = new Date($scope.taskSubInfo.toDate);
  } catch (e) {
	  console.log('invalid fromDate:'+$scope.taskSubInfo.fromDate);
  }
}

/*$scope.clogFromDate = new Date($filter('date')(new Date($scope.taskSubInfo.fromDate),'yyyy-MM-dd'));
$scope.clogToDate = new Date($filter('date')(new Date($scope.taskSubInfo.toDate),'yyyy-MM-dd'));
$scope.clogFromTime = new Date($filter('date')(new Date($scope.taskSubInfo.fromDate),'HH:mm:ss'));
$scope.clogToTime = new Date($filter('date')(new Date($scope.taskSubInfo.toDate),'HH:mm:ss'));*/
```

## 如何在 ngRepeat 中设置 name 属性的 $index

具体如下

```
<div class="form-group"
     ng-class="{'has-error': taskSubForm['variableName_'+$index].$invalid && (taskSubForm['variableName_'+$index].$dirty || taskSubForm.$submitted)}">
    <label>变量名称</label>
    <input type="text" class="form-control" name="variableName_{{$index}}" placeholder="变量名称 必填" ng-model="taskSubvariable.variableName" required>
    <span class="help-block error-block basic-block">此字段必填</span>
</div>
```

- [angular ngRepeat $index in name attribute](https://stackoverflow.com/questions/21631456/angular-ngrepeat-index-in-name-attribute)

## [如何知道 $http 请求成功了](http://www.cnblogs.com/xing901022/p/4928147.html)

```
<script type="text/javascript">
     var myAppModule = angular.module("myApp",[]);
     myAppModule.controller("myctrl",["$scope","$q",function($scope, $ q ){
        $scope.test = 1;//这个只是用来测试angularjs是否正常的，没其他的作用

        var defer1 = $q.defer();
        var promise1 = defer1.promise;

        promise1
        .then(function(value){
            console.log("in promise1 ---- success");
            console.log(value);
        },function(value){
            console.log("in promise1 ---- error");
            console.log(value);
        },function(value){
            console.log("in promise1 ---- notify");
            console.log(value);
        })
        .catch(function(e){
            console.log("in promise1 ---- catch");
            console.log(e);
        })
        .finally(function(value){
            console.log('in promise1 ---- finally');
            console.log(value);
        });

        defer1.resolve("hello");
        // defer1.reject("sorry,reject");
     }]);
</script>
```

也可以简写成如下方式

```
promise1
.then(function(value){
    console.log("in promise1 ---- success");
    console.log(value);
},function(value){
    console.log("in promise1 ---- error");
    console.log(value);
});
```

或者

```
promise1
.then(function(value){
    console.log("in promise1 ---- success");
    console.log(value);
});
```

- [AngularJS 中的Promise --- $q服务详解](http://www.cnblogs.com/xing901022/p/4928147.html)

## [Modal 弹出框如何传值](http://www.cnblogs.com/acmilan/p/3672184.html)

- 通过 resolve

```
angular.module('modaltest')
.controller('testModalTestController',function($scope,$modal){
        $scope.addModal = function () {
            var newWarn = $modal.open({
                templateUrl: 'views/part/add.html',
                controller: 'C_add_Warn',
                resolve:{
                    header : function() { return angular.copy("新增"); },
                    msg : function() { return angular.copy("这是消息"); }
                }
            });
        }  
}) 
.controller('C_add_Warn',function($scope,header,msg){
       $scope.header = header;
       $scope.msg = msg;
})
```

- 通过 scope 传递

```
angular.module('modaltest')
 .controller('testModalTestController',function($rootScope,$scope,$modal){
          var scope = $rootScope.$new();
           scope.data = {
                msg:"test",
                header:"header"
           }
          $scope.addModal = function () {
              var newWarn = $modal.open({
                  templateUrl: 'views/part/add.html',
                  controller: 'C_add_Warn',
                  scope:scope
             });
         }  
 }) 
 .controller('C_add_Warn',function($scope){
        var data = $scope.data;

 })
```

## [Controller 之间如何跳转](https://yehuang.me/angularjs/2015/11/01/how-to-pass-parameters-in-angularjs/)

- 在AngularJS的app.js中用ui-router定义路由，比如现在有两个页面，一个页面producers.html放置了多个producers，点击其中一个目标，页面跳转到对应的producer.html页，同时将producerId这个参数传过去。

```
//定义producers状态
.state('producers', {
    url: '/producers',
    templateUrl: 'views/producers.html',
    controller: 'ProducersCtrl'
})
//定义producer状态
.state('producer', {
    url: '/producer/:producerId',
    templateUrl: 'views/producer.html',
    controller: 'ProducerCtrl'
})
```
- 在producers.html中，定义点击事件，比如ng-click=”toProducer(producerId)”，在ProducersCtrl中，定义页面跳转函数 (使用ui-router的$state.go接口)：

```
.controller('ProducersCtrl', function ($scope, $state) {
    $scope.toProducer = function (producerId) {
        $state.go('producer', {producerId: producerId});
    };
});
```

- 在 ProducerCtrl 中，通过 ui-router 的 $stateParams 获取参数 producerId，譬如：

```
 .controller('ProducerCtrl', function ($scope, $state, $stateParams) {
   var producerId = $stateParams.producerId;
});
```

- [AngularJS - 页面跳转传参](https://yehuang.me/angularjs/2015/11/01/how-to-pass-parameters-in-angularjs/)

## [如何截取字符串(filter的使用介绍)](https://stackoverflow.com/questions/18095727/limit-the-length-of-a-string-with-angularjs)

在模块中定义 cut filter

```
angular.module('ng').filter('cut', function () {
        return function (value, wordwise, max, tail) {
            if (!value) return '';

            max = parseInt(max, 10);
            if (!max) return value;
            if (value.length <= max) return value;

            value = value.substr(0, max);
            if (wordwise) {
                var lastspace = value.lastIndexOf(' ');
                if (lastspace !== -1) {
                  //Also remove . and , so its gives a cleaner result.
                  if (value.charAt(lastspace-1) === '.' || value.charAt(lastspace-1) === ',') {
                    lastspace = lastspace - 1;
                  }
                  value = value.substr(0, lastspace);
                }
            }

            return value + (tail || ' …');
        };
    });
```

使用如下

```
{{some_text | cut:true:100:' ...'}}
```

参数说明

- wordwise (boolean) - if true, cut only by words bounds,
- max (integer) - max length of the text, cut to this number of chars,
- tail (string, default: ' …') - add this string to the input string if the string was cut.

## [checkbox 中的 ng-model 不起作用了](https://stackoverflow.com/questions/18642371/checkbox-not-binding-to-scope-in-angularjs)

先看看下面错误的做法

- html

```
<label class="checkbox-inline custom-checkbox nowrap">
    <input type="checkbox" ng-model="checkJobAll" ng-click="checkAllJob(checkJobAll)">
    <span></span>
</label>
```

- js

```
$scope.checkJobAll = false;

$scope.checkJobAll = true;
```

当 ng-model 绑定的是一个普通变量的时候, Controller 中的变量无法和页面上的变量值同步,只有改成对象的形式才可以,正确的做法如下

- html

```
<label class="checkbox-inline custom-checkbox nowrap">
    <input type="checkbox" ng-model="checkJobAll.flag" ng-click="checkAllJob(checkJobAll.flag)">
    <span></span>
</label>
```

- js

```
$scope.checkJobAll = { 'flag':false };

$scope.checkJobAll.flag = true;
```

## [Modal 弹出框如何使用](https://angular-ui.github.io/bootstrap/#!#modal) 

点击页面上的按钮弹出一个 Modal 对话框

- html 

```
<input type="button" ng-disabled="(item.status == 'EXECUTING' ? false : true) || showLoading" ng-click="openStopModal('app/pages/job/modal/stopJobModal.html', 'md', item.id)" class="btn btn-danger btn-sm" value="停止">
```

- js

```javaScript
// 打开停止job的对话框
$scope.openStopModal = function (page, size, id) {
    $scope.showLoading = true;
    $scope.stopJobExecuteId = id;

    // 弹出是否关闭job的对话框 ///////////////////////////////////////////////////////////////////////
    var modalInstance = $uibModal.open({
        animation: true,
        templateUrl: page,
        scope: $scope,
        //controller: 'StopJobModalInstanceCtrl',
        size: size
    });

    modalInstance.result.then(function () { // close
        console.log('modal close');
        $scope.showLoading = false;

        // 后台调用 stopJob 服务
        JobExecuteService.stopJob($scope.stopJobExecuteId).then( // 点击确定关闭job 按钮的回调
            function (response) {
                console.log(" stopJobExecute response = "  + JSON.stringify(response));

                $scope.stopJobDetail = response.data.stopDetail;

                // 关闭job成功后的modal //////////////////////////////////////////////////////////////////////////////////////////////
                var successModalInstance = $uibModal.open({
                    animation: true,
                    templateUrl: 'app/pages/job/modal/stopJobSuccessModal.html',
                    scope: $scope, // 控制弹出的 Modal 框使用同样的 $scope
                    size: 'md'
                });

                successModalInstance.result.then(function () { // close
                },function () { // dismiss或者Modal框消失
                    // 刷新列表数据
                    $scope.callServer($scope.jobExecuteTableState);
                });
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            },
            function (errResponse) {
                console.error('Error while getJobExecute ' + id + ', Error :' + errResponse.data);
                toastr.error('Error while getJobExecute ' + id + ', Error :' + errResponse.data, '提示', $scope.notificationConfig);
            }

        );

    }, function () { // dismiss
        console.log('modal dismiss');
        $scope.showLoading = false;
    });
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
};
```

## [关于 form 的使用, 涉及 $submitted 和 $setPristine() 应用 ](https://code.angularjs.org/1.5.8/docs/api/ng/directive/form)

- html

```
<div ba-panel
     ba-panel-class="with-scroll">

    <form name="taskMainForm" ng-submit="submit()" ng-init="initForm()" novalidate>
        <div class="form-group has-feedback"
             ng-class="{'has-error': taskMainForm.taskName.$invalid && (taskMainForm.taskName.$dirty || taskMainForm.$submitted)}">
            <label>任务名称</label>
            <input type="text" class="form-control" name="taskName" placeholder="任务名称 必填" ng-model="taskMainInfo.taskName" required>
            <span class="help-block error-block basic-block">必填</span>
        </div>
        
        <div class="form-group">
            <label>备注</label>
            <textarea placeholder="填写备注" class="form-control" ng-model="taskMainInfo.remarks"></textarea>
        </div>

        <div class="form-group">
            <input type="submit" ng-disabled="taskMainForm.$submitted && submitFlag" value="{{!taskMainInfo.id ? '添加' : '修改'}}" class="btn btn-primary btn-sm">
            <button type="button" ng-click="initForm(taskMainForm)" class="btn btn-warning btn-sm">重置</button>
        </div>

    </form>

</div>

```

- js

```javaScript
// 重置form
$scope.initForm = function (form) {
  if (form != null && typeof form !== 'undefined') {
      form.$setPristine();
  }

  $scope.taskMainInfo = {};
  $scope.taskSubs = [];
  $scope.deleteTaskSubs = [];
  $scope.taskMainInfo.executeType = '0';
  $scope.taskMainInfo.taskStatus = '0';

  $scope.taskSubAdd();
  // 2 所有, 用于创建主任务模块
  $scope.loadAllTaskSubDict($scope.loadTaskSubFlag);

  console.log('init form success');
};
```

```
$scope.taskMainForm = {}

$scope.submitFlag = true;
$scope.submit = function() {
      $scope.submitFlag = true;
      if (this.taskMainForm.$invalid) { // this.taskMainForm 表示当前操作的form
          $scope.submitFlag = false;
          return;
      }

      $scope.taskMainForm = this.taskMainForm; // 把当前 form 作为全局的 form 来看

      // 保存成功
      if (createSuccess) {
        $scope.initForm($scope.taskMainForm);    
      }
      // 修改成功
      if (updateSuccess) {
        $scope.initForm($scope.taskMainForm);    
      }
      
  };
```

在 form submit 后 $submitted 会变成 true 并禁用 submit 按钮, 然后再调用上面的 initForm 方法来将 $submitted 状态重置为 false.

关键在于点击提交按钮后通过 ng-submit 中定义的 submit 函数中的 `this.taskMainForm` 来获取到当前的 form 对象, 在保存或者修改成功后再调用 `form.$setPristine()` 将 $submitted 状态重置为 false.

- 参考 [Angular $setPristine() not working](https://stackoverflow.com/questions/32029889/angular-setpristine-not-working)


## [如何给一组 CheckBox 绑定值](https://stackoverflow.com/questions/14514461/how-do-i-bind-to-list-of-checkbox-values-with-angularjs)

```
<div ng-controller="MainCtrl">
  <label ng-repeat="(color,enabled) in colors">
      <input type="checkbox" ng-model="colors[color]" /> {{color}} 
  </label>
  <p>colors: {{colors}}</p>
</div>

<script>
  var app = angular.module('plunker', []);

  app.controller('MainCtrl', function($scope) {
      $scope.colors = {Blue: true, Orange: true};
  });
</script>
```