---
title: Java 分段从文件中读取数据的一个例子
title_url: java-read-file-piece
date: 2016-10-31
tags: [Java]
categories: 技术
description: Java 分段从文件中读取数据的一个例子
---

```java

/**
 * 分段从文件中读取数据
 * 
 * @author chen_k
 *
 */
@Component
public class GrabDataService {
	
	/**
	 * 每次从文件中读取的行数，默认 5000 行
	 */
	public static final int LINE_COUNT = 5000;
	
	/**
	 * 文件默认编码
	 */
	public static final String FILE_ENCODING = "UTF-8";

	private static final Logger log = LoggerFactory.getLogger(GrabDataService.class);
	
	/**
	 * 文件的唯一标识Map，用于记录从文件的哪一行开始读取
	 */
	private Map<String, Integer> counterMap = Collections.synchronizedMap(new HashMap<String, Integer>());
	
	/**
	 * 每次从文件中读取固定行数的记录
	 * @param msgKey 文件的唯一标识
	 * @param filePath 文件路径
	 * @return List<Map<Integer, String>> 读取的文件内容
	 */
	public List<Map<Integer, String>> getFileData(String msgKey, String filePath) {
		List<Map<Integer, String>> dataList = new ArrayList<>();
		
		int line = 0;
		if (counterMap.get(msgKey) == null) {
			counterMap.put(msgKey, line);
		} else {
			line = counterMap.get(msgKey);
		}
		
		try {
			File file = new File(filePath);
			if (file.isFile() && file.exists()) { // 判断文件是否存在
				InputStreamReader read = new InputStreamReader(new FileInputStream(file), FILE_ENCODING);// 考虑到编码格式
				BufferedReader bufferedReader = new BufferedReader(read);
				String lineTxt = null;
				
				int index = 1;
				while ((lineTxt = bufferedReader.readLine()) != null) {
					// 每次取的时候从上次最后的行开始
					if (index > line) {
						Map<Integer, String> data = new HashMap<>();
						data.put(index, lineTxt);
						dataList.add(data);
						
						// 每次只取文件的 5000 条
						if ((index - line) == LINE_COUNT) {
							line = index;
							break;
						}
					}
					index ++;
				}
				// 说明文件已经读完，插入一个读完的标记, file.renameTo(file) 用于判断当前文件是否被其他程序写入内容或占用
				if (lineTxt == null && file.renameTo(file)) {
					Map<Integer, String> data = new HashMap<>();
					data.put(-1, "END OF FILE");
					dataList.add(data);
					
					line = index;
				}
				
				read.close();
				bufferedReader.close();
			} else {
				log.error("找不到指定的文件:{}", new Object[]{filePath});
			}
		} catch (Exception e) {
			log.error("读取文件内容出现异常", e);
		} finally {
			// 记录下一次从文件的哪一行开始读取
			counterMap.put(msgKey, line);
			log.info("msgKey={},filePath={},line={}", new Object[]{msgKey,filePath,line});
		}
		
		return dataList;
	}
	
	/**
	 * 重置从文件的开始读取行数
	 * 
	 * @param msgKey 文件的唯一标识
	 * @param offset 开始读取行数
	 */
	public void relocateTo(String msgKey, int offset) {
		counterMap.put(msgKey, offset);
	}
	
	public GrabDataService() {
	}

}
```