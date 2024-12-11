1. 读取excel文件
2. 选取指定年份和城市
3. 整合年份和城市为一个二维列表，之后逐渐加入新的列表数据
4. 将数据写入excel文件


Tools类
1. 判断两个城市名称是否指代同一个城市
2. 将

ExcelReader类
1. 读取指定sheet中的指定列数据，返回列表
2. 整合年份和城市为一个二维列表，之后逐渐加入新的列表数据

ExcelWriter类
1. 将数据写入excel文件
2. 将数据写入新的 sheet

DataCleaning类
1. 删除不在选取范围内的年份
2. 删除不在选取范围内的城市
3. 将数据写入excel文件


初始化 DataTransform 类
1. 读取 excel文件中的指定 sheet
2. 初始化 writer 和 reader