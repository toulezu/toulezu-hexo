---
title: 使用Maven的profiles和testResource进行Junit单元测试
title_url: Maven-profiles-testResource-Junit
date: 2016-07-11
tags: [Maven,Junit]
categories: 技术
description: 使用Maven的profiles和testResource进行Junit单元测试
---

## Maven的profiles配置使用

Maven的profiles可根据不同的环境将POM的配置应用到配置文件中的`${}`变量中，具体步骤如下：

- POM的profiles配置如下
```xml
<project>
	
	<profiles>
		<profile>
			<id>dev</id>
			<activation>
				<activeByDefault>true</activeByDefault>
			</activation>
			<properties>
				<!-- 日志 -->
				<log.root.level>DEBUG</log.root.level>
				<log.root.name>Service</log.root.name>
				<log.special>Console</log.special>
			</properties>
		</profile>
		<profile>
			<id>test</id>
			<properties>
				<!-- 日志 -->
				<log.root.level>DEBUG</log.root.level>
				<log.root.name>Service</log.root.name>
				<log.special>Console</log.special>
			</properties>
		</profile>
	</profiles>
</project>
```

- 为了在编译的时候就将POM的配置应用到文件中的`${}`变量中需要加入如下配置，具体会将profiles中的配置应用到`src/main/resources`目录下含有`${}`变量，
这些变量可以在xml或者properties文件中
```xml
<project>

	<build>
		<resources>
			<resource>
				<directory>src/main/resources</directory>
				<includes>
					<include>*/*</include>
					<include>*</include>
				</includes>
				<filtering>true</filtering>
			</resource>
		</resources>
	</build>
</project>
```

比如在`src/main/resources/log4j.properties`中有如下配置
```
log4j.rootLogger=${log.root.level},${log.root.name},${log.special}

#Console
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=%d{dd\u65e5 HH:mm:ss,SSS} : %-5p %C{1}.%M() - %m%n
```

那么编译后在`target\classes\log4j.properties`文件中的内容如下：
```
log4j.rootLogger=DEBUG,Service,Console

#Console
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=%d{dd\u65e5 HH:mm:ss,SSS} : %-5p %C{1}.%M() - %m%n
```

## 在Junit单元测试中利用profiles配置来区分不同环境

在上面的介绍中是通过profiles配置来区分不同环境方便打包发布，这里介绍通过profiles配置区分不同环境进行单元测试，确保系统在发布前不仅能通过本地环境的单元测试，还能够通过线上环境的单元测试。

- POM的profiles配置和上面的一样

- 在`build`节点下新增`testResources`，确保在本地执行`mvn test -Ptest` 的时候将profiles配置应用到`src/test/resources`目录下含有`${}`变量并执行Junit单元测试
```xml
<project>

	<build>
		<testResources>
			<testResource>
				<directory>src/test/resources</directory>
				<includes>
					<include>*/*</include>
					<include>*</include>
				</includes>
				<filtering>true</filtering>
			</testResource>
		</testResources>
	</build>
</project>
```

- 在`src/test/resources`目录下新建`test`文件夹，将properties文件移到该目录下，Maven在执行单元测试的时候默认从该目录读取properties文件

- **注意**，在 Eclipse 中右键项目执行`Maven->Update Maven Project`后，需要右键项目在`Java Build Path`节点中选择`Source`选项卡，
选中`src/main/resources`和`src/test/resources`下的`Excluded`选项点击右边的`Remove`按钮，最后点击下面的`Ok`按钮，才能将相关资源文件编译到`target`目录下

## 编写一个Spring MVC的Controller层Junit单元测试

- Controller层Junit单元测试与Service层有所不同，需要引入spring-test和spring-mock
```xml
<dependency>
	<groupId>org.springframework</groupId>
	<artifactId>spring-test</artifactId>
	<version>3.2.8.RELEASE</version>
</dependency>
<dependency>
	<groupId>org.springframework</groupId>
	<artifactId>spring-mock</artifactId>
	<version>2.0.8</version>
</dependency>
```

- Controller层代码如下
```java
@ResponseBody
@ApiOperation(value = "获取用户信息", notes = "获取用户信息", response = JsonResponses.class)
@RequestMapping(value = "/user_info", method = RequestMethod.GET, produces = "application/json; charset=utf-8")
public void getUserInfo(@ModelAttribute BasicInfoBean basicInfo, 
		HttpServletResponse response, HttpServletRequest request) throws Exception {
	
	// 验证uid是否存在
	Integer uid = basicInfo.getUid();
	if (uid == null) {
		HttpUtil.returnJson(new JsonResponses(API.CODE.kCodeParamsError, API.MESSAGE.PARAM_FAILED.concat(":uid为空")), response);
		return;
	}
	
	Users user = userServicebyUC.getUsersByUid(uid);
	final Map<String, Object> dataMap = new LinkedHashMap<>();
	setUserModelMap(user, dataMap, basicInfo);
	
	HttpUtil.returnJson(new JsonResponses(API.CODE.kCodeSuccess, API.MESSAGE.SUCCESS, dataMap), response);
}
```

- Junit代码如下
```java
@RunWith(SpringJUnit4ClassRunner.class)
@WebAppConfiguration
@ContextConfiguration(locations = { "classpath:spring/*-config.xml", "classpath:spring/*-servlet.xml" })
public class BaseController {
	
	protected static String uid;
	
	static {
		// 加载配置文件
		Properties config = new Properties();
		InputStream input = null;
		try {
			input = API.class.getClassLoader().getResourceAsStream("test/test.properties");
			Reader reader = new InputStreamReader(input, "UTF-8");
			config.load(reader);

			uid = config.getProperty("uid");

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (null != input) {
				try {
					input.close();
				} catch (IOException e) {
				}
			}
		}
	}

	// @Autowired
	// private WebApplicationContext wac;
	
}

public class TestUserController extends BaseController {
	
	private Logger logger = LoggerFactory.getLogger(this.getClass());
	
	@Autowired
	protected UserController userController;

	protected MockMvc mockMvc;

	@Before
	public void setup() {
		mockMvc = MockMvcBuilders.standaloneSetup(userController).build();
	}

	@Test
	public void testFindPageUsers() throws Exception {
		logger.info("uid is {}", uid);
		
		ResultActions ra = mockMvc.perform(MockMvcRequestBuilders.get("/user/user_info")
				.accept(MediaType.APPLICATION_JSON).param("test", "1").param("uid", uid));
		MvcResult mr = ra.andReturn();
		MockHttpServletResponse resp = mr.getResponse();
		Assert.assertEquals(resp.getStatus(), 200);
		
		JSONObject obj = JSONObject.parseObject(resp.getContentAsString());
		JSONObject dataObj = obj.getJSONObject("data");
		Assert.assertEquals(StringUtil.getStr(dataObj.get("uid")), uid);
	}

}
```

## 如何去掉单元测试

- 在执行Maven命令的时候加上`-Dmaven.test.skip=true`即可，比如`clean install -Dmaven.test.skip=true`，这样就会在执行的过程中跳过单元测试 `[INFO] Tests are skipped.`，也可以在profiles的properties中增加`<maven.test.skip>true</maven.test.skip>`，具体如下
```xml
<project>
	
	<profiles>
		<profile>
			<id>dev</id>
			<activation>
				<activeByDefault>true</activeByDefault>
			</activation>
			<properties>
				<maven.test.skip>false</maven.test.skip>
				<!-- 日志 -->
				<log.root.level>DEBUG</log.root.level>
				<log.root.name>Service</log.root.name>
				<log.special>Console</log.special>
			</properties>
		</profile>
		<profile>
			<id>test</id>
			<properties>
				<maven.test.skip>true</maven.test.skip>
				<!-- 日志 -->
				<log.root.level>DEBUG</log.root.level>
				<log.root.name>Service</log.root.name>
				<log.special>Console</log.special>
			</properties>
		</profile>
	</profiles>
</project>
```

## 参考如下
- [Maven的profiles介绍](https://maven.apache.org/guides/introduction/introduction-to-profiles.html)
- [MAVEN 属性定义与使用](http://www.tmser.com/post-178.html)
- [Maven的生命周期和插件](http://www.open-open.com/lib/view/open1452138592011.html)
- [利用maven中resources插件的copy-resources目标进行资源copy和过滤](http://xigua366.iteye.com/blog/2080668?utm_source=tuicool&utm_medium=referral)