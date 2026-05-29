## 第12章：MySQL数据存储

---

### 12.1 MySQL概览

数据库：存储数据的仓库，数据是有组织的进行存储，简称database（DB）。数据库管理系统：（Database Management System 简称：DBMS）是一种用于管理和操作数据库的软件系统。它提供了一系列功能，包括数据定义、数据操作、数据存储、查询、更新、安全性控制、并发控制和事务管理等。

#### 12.1.1 数据库类型

- 关系型数据库（Relational Database） ：基于关系模型，数据以表格形式存储，通过SQL语言进行查询和操作。常见的关系型数据库有MySQL、Oracle、PostgreSQL和Microsoft SQL Server等。

- 非关系型数据库（NoSQL Database） ：不依赖传统表格结构，支持键值对、文档存储、列族存储和图形存储等多种数据模型。常见的非关系型数据库包括MongoDB、Redis、Cassandra和Neo4j等。

#### 12.1.2 SQL语言

SQL（Structured Query Language，结构化查询语言）是一种用于管理关系型数据库的标准化语言，主要用于数据查询、数据插入、数据更新和数据删除等操作。

- DDL：数据定义语言
- DML：数据操作语言
- DQL：数据查询语言
- DCL：数据控制语言

#### 12.1.3  常用终端命令

| 命令           | SQL                                  | 命令       | SQL                                 |
| -------------- | ------------------------------------ | ---------- | ----------------------------------- |
| 启动服务       | net start mysql80;                   | 停止服务   | net stop mysql80;                   |
| 登录数据库     | mysql -u root -p；回车后输入root密码 | 退出数据库 | exit;                               |
| 显示所有数据库 | show databases;                      | 选择数据库 | use 数据库名;                       |
| 创建数据库     | create database 数据库名;            | 删除数据库 | drop database 数据库名;             |
| 显示所有表     | show tables;                         | 创建表     | create table 表名(列名 类型);       |
| 删除表         | drop table 表名;                     | 插入数据   | insert into 表名 values(值);        |
| 查询数据       | select* from 表名 where 条件;        | 更新数据   | update 表名 set 字段=值 where 条件; |



### 12.2 SQL通用语法

#### 12.2.1 语法概述

- SQL语句可以单行或多行书写，以分号结尾；
- SQL语句可以使用空格或缩进来增强语句的可读性；
- MySQL数据库的SQL语句不区分大小写，增强阅读性可以使用小写字母；
- SQL语句中的注释：
   - 单行注释：- - 注释内容 或 # 注释内容 （MySQL特有）
   - 多行注释：/* 注释内容 */

#### 12.2.2 数据库和表的创建

创建数据库：

```sql
# （注意：中括号里的内容是可以省略的）
create database [if not exists] 数据库名 [default charset 字符集] [collate 排序规则]; 
```

创建表

```sql
# comment注释可有可无
create table student(
	sno int(10) primary key auto_increment comment"注释",		 
    sname varchar(50) not null comment"注释",					
    sbirthday date not null comment"注释",					
    saddress varchar(255) comment"注释",
    sphone varcahr(12) comment"注释",
    class_name varchar(50) comment"注释"
);
```

数据库和表的使用：

```sql
# 使用数据库
use 数据库名;
# 查询当前数据库所有表：
show tables;
# 查询表结构：
desc 表名;
# 查询指定表的建表语句：
show create table 表名;
```

| 数据类型 |                      | 约束条件       |                          |
| -------- | -------------------- | -------------- | ------------------------ |
| int      | 整数                 | primary key    | 主键，全表唯一值         |
| varchar  | 字符串               | auto_increment | 主键自增，必须是整数类型 |
| date     | 时间                 | not null       | 不可以为空               |
| double   | 小数                 | null           | 可以为空                 |
| datetime | 时间（年月日时分秒） | default        | 设置默认值               |
| text     | 大文本               |                |                          |

### 12.3 数据操作-增删改查（重点）

SQL的执行顺序：

​	from 表名➡️where 条件➡️group by 分组字段➡️select 字段➡️order by 排序字段➡️limit 分页参数

#### 12.3.1 增加数据

```sql
# 给指定字段添加数据，列名顺序需要与值的顺序是一一对应的。
insert into 表名 (列名1,列名2,……) values (值1,值2,……);
# 给全部字段添加数据：
insert into 表名 values  (值1,值2,……);
# 批量添加数据：
insert into 表名 (列名1,列名2,……) values (值1,值2,……),(值1,值2,……),(值1,值2,……);
insert into 表名 values  (值1,值2,……),(值1,值2,……),(值1,值2,……),(值1,值2,……);
```

#### 12.3.2 删除数据

```sql
# 如果不添加条件，则会删除整张表的数据；
delete from 表名 where 条件;
```

#### 12.3.3 修改数据

```sql
update 表名 set 字段名1 = 值1, 字段名2 = 值2, …… where 条件;
```

修改表的列名、数据类型等

```python
# 添加列：
alter table 表名 add 列名 类型（长度） [comment 注释] [约束];
# 修改列类型：
alter table 表名 modify 列名 新数据类型（长度）;
# 修改字段名和字段类型：
alter table 表名 change 旧列名 新列名 类型（长度）[comment 注释] [约束];
# 删除字段：
alter table 表名 drop 列名;
# 修改表名：
alter table 表名 rename to 新表名;
# 删除表：
drop table [if exists] 表名;
# 删除指定表，并重新创建该表,（相当于删除了表里面的所有数据）：
truncate table 表名;
```



#### 12.3.4 查询数据

```sql
# 基本查询：
select 列名 from 表名
# 查询多个字段：
select 列名1，列名2，列名3，…… from 表名；
select * from 表名；
# 设置别名：
select 字段1 as 别名1 ，字段2 as 别名2 from 表名；
# 去除重复记录，distinct 必须紧跟 select 之后，且作用于所有选择的字段：
select distinct 字段列表 from 表名；
# 多字段去重 
select distinct 列名1,列名2 from table_name
```

#### 12.3.5 where条件

```sql
select 列名 from 表名 where 条件1 and 条件2 or 条件3；
# between ……and……  在……之间（包含两边的）
# like 模糊匹配 '_张%' %匹配任意字符, _匹配一个字符
```

#### 12.3.6 分组查询

会根据 by 后面给出的列名进行分组，把相同的数据分为一组。

```sql
# 语法：group by 分组字段  having 分组后条件字段
select 字段列表 from 表名 where 条件 group by 分组条件 having 分组后过滤条件；

# 这里注意where 与 having的区分
   1. 执行时机不同，where是分组之前进行过滤，不满足where条件，不参与分组；
   2. having是分组之后对结果进行过滤；
   2. 判断条件不同：where不能对聚合函数进行判断，而having可以；
   3. 执行顺序：where > 聚合函数 > having
   4. 分组之后，查询的字段一般为聚合函数和分组字段，查询其他字段无任何意义;
```

#### 12.3.7 聚合函数

将一列数据作为一个整体，进行纵向计算

```sql
# 语法：
select 聚合函数(列名) from 表名；
# 常见聚合函数：需要注意的是所有的聚合函数是不参与null值计算的
   1. 求总数 count()
   2. 最大值 max()
   3. 最小值 min()
   4. 平均值 avg()
   5. 求和 sum()
```

#### 12.3.8 常见其他函数

```sql
# 条件判断器 case when 语法：根据不同条件返回不同的值，只能出现在select 字段后，从上到下判断条件，满足第一个条件后直接返回结果，后续条件不再检查。如果省略 ELSE，不满足任何条件时默认返回 NULL。
case 列名 when 条件1 then 结果1 when 条件2 then 结果2 …… else 默认结果 end

# 日期函数
提取年/月/日  year()/month()/day()
# 在日期基础上加天数：
date_add(日期字段，interval 2 day) 加2天
# 对指定起始时间进行减操作
date_sub(date,interval expr type)
# 计算两个日期之间间隔的天数
datediff(date1,date2)
# 将日期和时间格式化
date_format(date,format)

# 四舍五入:将数值按指定小数位数四舍五入,小数位数：可选参数，默认值为0（即取整）
round(数值, 小数位数)

# 字符串函数
# 拼接：
concat(字符串1, 字符串2, ..., 字符串N)
# 替换
replace(s,s1,s2)
# 从左截取字符串一部分
left(s,n)
# 从右截取字符串一部分
right(s,n)
# 从指定位置截取字符串一部分
substring(s,n,len)
```

#### 12.3.9 高级函数之窗口函数

执行顺序是where--group by--窗口函数--select选择展示字段。在排名问题、趋势分析、对比分析、去重保留最新记录场景中使用

```python
# 1.排序窗口函数
# 并列排名并且跳过序号：
rank()	例如（1,1,3）
# 并列排名不跳号：
dense_rank()	例如：（1,1,2）
# 连续序号：
row_number()	例如：（1,2,3）
# 使用方法：partition by 字段 【按这个字段分组】，order by 字段 【在上一步分组后，在按这个字段排序】
窗口函数 over(partition by 字段名 order by 字段名 asc|desc)
```

```sql
# 聚合窗口函数
#累计求和：
SUM() 
# 移动平均：
AVG()
# 累计计数：
COUNT() 
# 使用方法：partition by 字段 【按这个字段分组】，order by 字段 【在上一步分组后，在按这个字段排序】
聚合类窗口函数 over(partition by 字段名 order by 字段名 asc|desc)
```

```sql
# 偏移类窗口函数
# 取当前行向前第N行的值：
LAG(字段, N)
# 取当前行向后第N行的值：
LEAD(字段, N)
# 使用方法：partition by 字段 【按这个字段分组】，order by 字段 【在上一步分组后，在按这个字段排序】
偏移类窗口函数 over(partition by 字段名 order by 字段名 asc|desc)
```

#### 12.3.10 排序

```sql
# 语法：
select 列名 from 表名 order by 列名1 排序方式1，字段2 排序方式2；
# 排序方式：
   1. asc：升序（默认值）
   2. desc：降序
# 注意：如果是多字段排序，当第一个字段值相同时，才会根据第二个字段进行排序；
```

#### 12.3.11 分页查询

```sql
# 语法：
select 列名 from 表名 limit 起始索引，查询记录数；
# 起始索引从0开始，起始索引 = （查询页码 -1）* 每页显示记录数；
# 分页查询是数据库的方言，不同的数据库有不同的实现，MySQL中是limit；
# 如果查询的是第一页数据，起始索引可以省略，直接简写为limit 10；
```

### 12.4 多表联合查询

#### 12.4.1 表链接

```sql
# 内连接,通过相同字段连接两个表的所有数据,但是会删除不能连接上的null数据
table1 inner join table2 on
# 左连接,保留左边数据表的所有行数据
table1 left join table2 on
# 右连接,保留右边数据表的所有行数据
table1 right join table2 on 
```

#### 12.4.2 子查询

```sql
# 子查询就是“先问一个小问题，再用答案解决大问题”的套娃操作
# 相当于在 SQL 里先写一个临时的小表格，再拿这个小表格去做主查询。
步骤1：明确最终目标,你最终要查什么？
步骤2：拆解依赖关系,检查是否有隐藏条件
步骤3：先写小问题（子查询）
步骤4：把答案套用到主查询
# 子查询最后返回查询出的结果给主查询
# 子查询可以在select，from，where，having子句（同where）中使用，但要注意不同子句能接受的子查询种类有差别
```




### 12.5 Python链接MySQL数据库

#### 12.5.1 pymysql模块安装

```python
安装：pip install pymysql
```

#### 12.5.2 新增、删除、修改操作

```python
# -------------------------新增--删除--修改--都一样，只是SQL不同-------------------------
# 1.导入数据库莫哭
import pymysql  
# 2.链接数据库
conn = pymysql.connect(
    host='localhost',	# localhost 指本机 或者 127.0.0.1
    port=3306,
    user='root', 
    password=<REDACTED_CREDENTIAL>, 
    database="数据库名"
)
# 3.创建游标 cursor 发送SQL去执行，以及获取SQL执行的结果
cur = conn.cursor()  
sql = "insert into men(name,age,address) values('燕归来','18','八宝山三')"
# 4.执行这个SQL
cur.execute(sql)
print('执行完毕')
# 5.提交事物,如果只是查询，不需要提交  rollback()表示回滚。
conn.commit()
# 6.断开游标和数据连接
cur.close()
conn.close()

```

#### 12.5.3 查询操作

```python
# -------------------------查询-------------------------------------
# 1.导入数据库莫哭
import pymysql  
from pymysql.cursors import DictCursor

# 2.链接数据库
conn = pymysql.connect(
    host='localhost',	# localhost 指本机 或者 127.0.0.1
    port=3306,
    user='root', 
    password=<REDACTED_CREDENTIAL>, 
    database="数据库名"
)
# 3.创建游标 cursor 发送SQL去执行，以及获取SQL执行的结果
# 为了方便处理，可以用dictCursor把数据进行格式化处理[{},{},{}]
cur = conn.cursor(DictCursor)  
sql = "select * from men"
# 4.执行这个SQL
cur.execute(sql)
print('执行完毕')
# 5.获取结果。
one = cur.fetchone()	# 拿一个结果，继续拿的话，是接着拿
print(one)
all = cur.fetchall()	# 拿所有结果
print(all)
# 6.断开游标和数据连接
cur.close()
conn.close()
```




