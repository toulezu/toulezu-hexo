---
title: 一个从 Jar 文件中获取所有的类路径的工具类
title_url: load-jar-file-class
date: 2016-11-17
tags: [Java]
categories: 技术
description: 一个从 Jar 文件中获取所有的类路径的工具类
---

```java
import java.io.File;
import java.io.IOException;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 关于类的工具类
 * 参考 @see org.apache.jorphan.reflect.ClassFinder
 * 
 * @author chen_k
 *
 * 2016年11月17日-上午10:30:59
 */
public class ClassUtil {
	
	private static final Logger log = LoggerFactory.getLogger(ClassUtil.class);
	
	private static final String DOT_CLASS = ".class";
	private static final int DOT_CLASS_LEN = DOT_CLASS.length();

	/**
	 * 从指定的 jar 文件中获取类的路径列表
	 * @param jarFile File jar 文件对象
	 * @param parents Class<?>[] 继承或者实现的接口
	 * @param inner 是否包含内部类
	 * @param contain 类路径中含有的字符串，比如 .function.
	 * @param notContain 类路径中不含有的字符串 .gui.
	 * @return List<String>
	 * @throws IOException
	 */
	public static List<String> getClassList(File jarFile, Class<?>[] parents, boolean inner, String contain, String notContain) throws IOException {
		Set<String> listClasses = new TreeSet<>();

		ZipFile zipFile = null;
		try {
			zipFile = new ZipFile(jarFile);
			Enumeration<? extends ZipEntry> entries = zipFile.entries();
			while (entries.hasMoreElements()) {
				String strEntry = entries.nextElement().toString();
				if (strEntry.endsWith(DOT_CLASS)) {
					String fixedClassName = fixClassName(strEntry);
					if (accept(parents, fixedClassName, contain, notContain, inner)) {
						listClasses.add(fixedClassName);
					}
				}
			}
		} catch (IOException e) {
			throw e;
		} finally {
			if (zipFile != null) {
				try {
					zipFile.close();
				} catch (Exception e) {
				}
			}
		}
		
		return new ArrayList<>(listClasses);
	}
	
	public static String fixClassName(String strClassName) {
		strClassName = strClassName.replace('\\', '.');
		strClassName = strClassName.replace('/', '.');
		// remove ".class"
		strClassName = strClassName.substring(0, strClassName.length() - DOT_CLASS_LEN);
		return strClassName;
	}

	public static boolean accept(Class<?>[] parents, String className, String contains, String notContains,
			boolean inner) {

		if (contains != null && !className.contains(contains)) {
			return false; // It does not contain a required string
		}
		if (notContains != null && className.contains(notContains)) {
			return false; // It contains a banned string
		}
		if (!className.contains("$") || inner) { // $NON-NLS-1$
			if (isChildOf(parents, className, Thread.currentThread().getContextClassLoader())) {
				return true;
			}
		}
		return false;
	}

	public static boolean isChildOf(Class<?>[] parentClasses, String strClassName, ClassLoader contextClassLoader) {
		// might throw an exception, assume this is ignorable
		try {
			Class<?> c = Class.forName(strClassName, false, contextClassLoader);

			if (!c.isInterface() && !Modifier.isAbstract(c.getModifiers())) {
				for (Class<?> parentClass : parentClasses) {
					if (parentClass.isAssignableFrom(c)) {
						return true;
					}
				}
			}
		} catch (UnsupportedClassVersionError | ClassNotFoundException | NoClassDefFoundError e) {
			log.debug(e.getLocalizedMessage());
		}
		return false;
	}

}

```

比如 jar 文件在 `D:/soft/apache-jmeter-3.0/lib/ext/ApacheJMeter_functions.jar`
``` java
List<String> classes = ClassUtil.getClassList(new File("D:/soft/apache-jmeter-3.0/lib/ext/ApacheJMeter_functions.jar"), new Class[] { Function.class }, true, ".functions.", ".gui.");
// Function.class 是 org.apache.jmeter.functions.Function
```

打印 classes，输出如下：
```
org.apache.jmeter.functions.BeanShell
org.apache.jmeter.functions.CSVRead
org.apache.jmeter.functions.CharFunction
org.apache.jmeter.functions.EscapeHtml
org.apache.jmeter.functions.EscapeOroRegexpChars
org.apache.jmeter.functions.EvalFunction
org.apache.jmeter.functions.EvalVarFunction
org.apache.jmeter.functions.FileToString
org.apache.jmeter.functions.IntSum
org.apache.jmeter.functions.IterationCounter
org.apache.jmeter.functions.JavaScript
org.apache.jmeter.functions.Jexl2Function
org.apache.jmeter.functions.Jexl3Function
org.apache.jmeter.functions.JexlFunction
org.apache.jmeter.functions.LogFunction
org.apache.jmeter.functions.LogFunction2
org.apache.jmeter.functions.LongSum
org.apache.jmeter.functions.MachineIP
org.apache.jmeter.functions.MachineName
org.apache.jmeter.functions.Property
org.apache.jmeter.functions.Property2
org.apache.jmeter.functions.Random
org.apache.jmeter.functions.RandomString
org.apache.jmeter.functions.RegexFunction
org.apache.jmeter.functions.SamplerName
org.apache.jmeter.functions.SetProperty
org.apache.jmeter.functions.SplitFunction
org.apache.jmeter.functions.StringFromFile
org.apache.jmeter.functions.TestPlanName
org.apache.jmeter.functions.ThreadNumber
org.apache.jmeter.functions.TimeFunction
org.apache.jmeter.functions.UnEscape
org.apache.jmeter.functions.UnEscapeHtml
org.apache.jmeter.functions.UrlDecode
org.apache.jmeter.functions.UrlEncode
org.apache.jmeter.functions.Uuid
org.apache.jmeter.functions.Variable
org.apache.jmeter.functions.XPath
```