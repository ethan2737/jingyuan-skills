## 第13章：MongoDB

---

NoSQL，全称 Not Only SQL，意为不仅仅是 SQL，泛指非关系型数据库。NoSQL 是基于键值对的，而且不需要经过 SQL 层的解析，数据之间没有耦合性，性能非常高。非关系型数据库又可细分如下：

1. 键值存储数据库：代表有 Redis、Voldemort 和 Oracle BDB 等

2. 列存储数据库：代表有 Cassandra、HBase 和 Riak 等

3. 文档型数据库：代表有 CouchDB 和 MongoDB 等

4. 图形数据库：代表有 Neo4J、InfoGrid 和 Infinite Graph 等

对于爬虫的数据存储来说，一条数据可能存在某些字段提取失败而缺失的情况，而且数据可能随时调整。另外，数据之间还存在嵌套关系。如果使用关系型数据库存储，一是需要提前建表，二是如果存在数据嵌套关系的话，需要进行序列化操作才可以存储，这非常不方便。如果用了非关系型数据库，就可以避免一些麻烦，更简单高效。

### 13.1  MongoDB 存储

MongoDB 是由 C++ 语言编写的非关系型数据库，是一个基于分布式文件存储的开源数据库系统，其内容存储形式类似 JSON 对象，它的字段值可以包含其他文档、数组及文档数组，非常灵活。MongoDB主要由三部分组成：数据库database、集合collection、文档document。

#### 13.1.1  MongoDB 常用命令

按 `win + R` 组合键，在运行窗口中输入 `cmd` 启动交互式命令行，在黑窗口中使用如下命令。

| 命令名称             | 代码                                                         | 作用                                                         |
| -------------------- | :----------------------------------------------------------- | ------------------------------------------------------------ |
| 启动shell            | mongosh                                                      | 启动MongoDB交互式命令行                                      |
| 查看数据库           | show dbs                                                     | 显示所有可访问的数据库：默认数据库有admin、config、loacl。   |
| 使用数据库           | use database_name                                            | 切换到指定数据库，不存在则创建（但是如果不存内容，也不会创建） |
| 查看当前数据库       | db                                                           | 显示当前连接的数据库名称。test（默认的内存层面的一个数据库） |
| 查看数据库中所有集合 | show collections                                             | 显示当前数据库的所有集合                                     |
| 创建集合             | db.createCollection("集合名字")                              |                                                              |
| 插入一条数据         | db.collection_name.insertOne({"name":"ethan"})               | 向当前数据库的集合中插入1条数据（如果这个集合不存在，则创建这个集合） |
| 插入多条数据         | db.collection_name.insertMany([{"name":"ethan"}])            | 同上                                                         |
| 查找数据             | db.collection.find({'name':'张三'}).pretty()                 | 查询所有或者符合条件的数据，并格式化输出结果                 |
| 投影                 | db.collection.find({'name':'张三'},{"name": 1, "score": 1, "_id": 0}).pretty() | 在查询出的结果中，1代表显示什么字段，0代表不显示什么字段     |
| 更新1条数据          | db.collection_name.updateOne()                               | 不加set则修改整条数据，加set是指修改指定的内容，不更新整条数据 |
| 更新多条数据         | db.collection_name.updateMany()                              |                                                              |
| 删除1条数据          | db.collection_name.deleteOne()                               |                                                              |
| 删除多条数据         | db.collection_name.deleteMany()                              |                                                              |
| 删除集合             | db.collection_name.drop()                                    | 根据集合的名字删除                                           |
| 删除数据库           | db.dropDatabase()                                            | 删除当前数据库                                               |
| 保存                 | db.collection_name.save({待保存的数据})                      |                                                              |
| 退出                 | exit                                                         | 退出MongoDB交互式命令行                                      |

#### 13.1.2  数据类型

```sql
Object ID:主键ID
String:字符串
Boolean:布尔值
Integer:数字
Doube:小数
Arrays:数组
object:文档(关联其他对象){sname:李嘉诚，sage:18，class:{cccc}}
Nu11 :空值
Timestamp:时间戳
Date:时间H期
```

#### 13.1.3  比较运算

```sql
等于: 默认是等于判断， $eq
小于: $lt(less than)
小于等于: $lte(less than equal)
大于: $gt(greater than)
大于等于: $gte
不等于: $ne

# 例子
db.stu.find({age:28})查询年龄是28岁的学生信息
db.stu.find({age:{$eq:28}})查询年龄是28岁的学生信息
db.stu.find({age:{$lte: 38}})查询年龄小于等于30岁的学生
db.stu.find({age:{$gt:30}})查询年龄大于30岁的学生
db.stu.find({age:{$lt: 30}})查询年龄小于30岁的学生
db.stu.find({age:{$gte: 38}})查询作龄大丁等于30岁的学生
db.stu.find({age:{$ne: 38}})查询年龄不等于38的学牛
```

#### 13.1.4  逻辑运算符

```shell
1. and
$and:[条件1,条件2,条件3……]
查询年龄等于33，并且，名字是"人老王"的学生信息
db.stu.find({$and:[{age:{$eq:33}}，{name:'大老王'}]})
2.or
$or: [条件1,条件2,条件3]
条件1or条件2or条件3
查询名字叫"李嘉诚"的，或者，作龄超过100岁的人
db.stu.find({$or: [{name :'李嘉诚'}，{age:{$gt:100}}]})
3.nor
$nor: [条件1,条件2,条件3]
查询年龄尔小于38岁的人，名字还不能是朱璋
db.stu.find({$nor:[{age:{$lt:38}},{name:"朱元璋"}]})
```

#### 13.1.5  范围运算符

```shell
使用$in，$nin判断数据是否在某个数组内
db.stu.find({age:{$in:[28,38]}}) 年龄是28或者38的人
```

#### 13.1.6  正则表达式

```shell
使用$regex进行正则表达式匹配
db.stu.find({address: {$regex:'^北京'}}) 查询地址是北京的人的信息
db.stu.find({address:/^北京/}) 效果一样
```

#### 13.1.7  skip 和 limit

```shell
db.stu.find().skip(3).limit(3)
跳过3个.提取3个.类似limit 3,3 可以用来做分页
```

#### 13.1.8  投影(掌握)

```shell
# 投影可以控制最终査询的结果(字段筛选)
db.stu.find({}，{字段:1，字段:1})
# 需要看的字段给1就可以了
# 注意,除了 id外,0,1不能共存!
```

#### 13.1.8  排序

```shell
sort({字段:1,字段:-1})
1  表示升序
-1 表示降序
对查询结果排序，先按照age升序排列，相同项再按照score降序排列
db.stu.find().sort({age:1, score:-1})
```

#### 13.1.9  统计数量

```shell
count(条件)查询数量
db.stu.count(fage:33})
```



### 13.2 Python连接 MongoDB

#### 13.2.1 安装

```python
pip install pymongo
```

#### 13.2.2 连接

连接 MongoDB 时，我们需要使用 PyMongo 库里面的 MongoClient。一般来说，传入 MongoDB 的 IP 及端口即可，其中第一个参数为地址 host，第二个参数为端口 port（如果不给它传递参数，默认是 27017）：

```python
import pymongo
# 1.链接数据库
conn = pymongo.MongoClient(host='localhost', port=27017)
# 2.选择数据库
db = conn["python_4"]
# 3.开始操作
db.stu.insert_one({name:"alex"})
```

这样就可以创建 MongoDB 的连接对象了。另外，MongoClient 的第一个参数 host 还可以直接传入 MongoDB 的连接字符串，它以 mongodb 开头，例如：

```python
client = MongoClient('mongodb://localhost:27017/')
```

这也可以达到同样的连接效果。

#### 13.2.3   指定数据库
MongoDB 中可以建立多个数据库，接下来我们需要指定操作哪个数据库。这里我们以 test 数据库为例来说明，下一步需要在程序中指定要使用的数据库：


```python
db = client.test
```
这里调用 client 的 test 属性即可返回 test 数据库。当然，我们也可以这样指定：
```python
db = client['test']
```

这两种方式是等价的。

#### 13.2.4   指定集合

MongoDB 的每个数据库又包含许多集合（collection），它们类似于关系型数据库中的表。

下一步需要指定要操作的集合，这里指定一个集合名称为 students。与指定数据库类似，指定集合也有两种方式：

```python
collection = db.students

collection = db['students']
```

这样我们便声明了一个 Collection 对象。

#### 13.2.5  插入数据

使用 insert_one() 和 insert_many() 方法来分别插入单条记录和多条记录，示例如下：
```python
student = {
    'id': '20170101',
    'name': 'Jordan',
    'age': 20,
    'gender': 'male'
}

result = collection.insert_one(student)
print(result)
print(result.inserted_id)
```
运行结果如下：
```python
<pymongo.results.InsertOneResult object at 0x10d68b558>
5932ab0f15c2606f0c1cf6c5
```

与 insert() 方法不同，这次返回的是 InsertOneResult 对象，我们可以调用其 inserted_id 属性获取_id。

对于 insert_many() 方法，我们可以将数据以列表形式传递，示例如下：

```python
student1 = {
    'id': '20170101',
    'name': 'Jordan',
    'age': 20,
    'gender': 'male'
}

student2 = {
    'id': '20170202',
    'name': 'Mike',
    'age': 21,
    'gender': 'male'
}

result = collection.insert_many([student1, student2])
print(result)
print(result.inserted_ids)
```
运行结果如下：
```python
<pymongo.results.InsertManyResult object at 0x101dea558>
[ObjectId('5932abf415c2607083d3b2ac'), ObjectId('5932abf415c2607083d3b2ad')]
```

该方法返回的类型是 InsertManyResult，调用 inserted_ids 属性可以获取插入数据的_id 列表。

#### 13.2.6  查询
插入数据后，我们可以利用 find_one() 或 find() 方法进行查询，其中 find_one() 查询得到的是单个结果，find() 则返回一个生成器对象。示例如下：

```python
result = collection.find_one({'name': 'Mike'})
print(type(result))
print(result)
```
这里我们查询 name 为 Mike 的数据，它的返回结果是字典类型，运行结果如下：
```python
<class 'dict'>
{'_id': ObjectId('5932a80115c2606a59e8a049'), 'id': '20170202', 'name': 'Mike', 'age': 21, 'gender': 'male'}
```

可以发现，它多了_id 属性，这就是 MongoDB 在插入过程中自动添加的。

此外，我们也可以根据 ObjectId 来查询，此时需要使用 bson 库里面的 objectid：

```python
from bson.objectid import ObjectId

result = collection.find_one({'_id': ObjectId('593278c115c2602667ec6bae')})
print(result)
```
其查询结果依然是字典类型，具体如下：
```python
{'_id': ObjectId('593278c115c2602667ec6bae'), 'id': '20170101', 'name': 'Jordan', 'age': 20, 'gender': 'male'}
```

当然，如果查询结果不存在，则会返回 None。

对于多条数据的查询，我们可以使用 find() 方法。例如，这里查找年龄为 20 的数据，示例如下：

```python
results = collection.find({'age': 20})
print(results)
for result in results:
    print(result)
```
运行结果如下：
```python
<pymongo.cursor.Cursor object at 0x1032d5138>
{'_id': ObjectId('593278c115c2602667ec6bae'), 'id': '20170101', 'name': 'Jordan', 'age': 20, 'gender': 'male'}
{'_id': ObjectId('593278c815c2602678bb2b8d'), 'id': '20170102', 'name': 'Kevin', 'age': 20, 'gender': 'male'}
{'_id': ObjectId('593278d815c260269d7645a8'), 'id': '20170103', 'name': 'Harden', 'age': 20, 'gender': 'male'}
```

返回结果是 Cursor 类型，它相当于一个生成器，我们需要遍历取到所有的结果，其中每个结果都是字典类型。

|  符　　号 | 含　　义           | 示　　例                                                                 | 示例含义                                      |
| ---------- | ----------------- | ------------------------------------------------------ | ------------------------------------ |
|  $regex   | 匹配正则表达式 | {'name': {'$regex': '^M.*'}}                                     | name 以 M 开头                              |
|  $exists    | 属性是否存在    | {'name': {'$exists': True}}                                        | name 属性存在                             |
|  $type     | 类型判断           | {'age': {'$type': 'int'}}                                              | age 的类型为 int                            |
|  $mod     | 数字模操作        | {'age': {'$mod': [5, 0]}}                                            | 年龄模 5 余 0                                   |
|  $text      | 文本查询           | {'$text': {'$search': 'Mike'}}                                     | text 类型的属性中包含 Mike 字符串 |
|  $where   | 高级条件查询    | {'$where': 'obj.fans_count == obj.follows_count'} | 自身粉丝数等于关注数                  |

关于这些操作的更详细用法，可以在 MongoDB 官方文档找到：
[https://docs.mongodb.com/manual/reference/operator/query/](https://docs.mongodb.com/manual/reference/operator/query/)。

#### 13.2.7  其他操作
可以参见官方文档：[http://api.mongodb.com/python/current/api/pymongo/collection.html](http://api.mongodb.com/python/current/api/pymongo/collection.html)。

对数据库和集合本身等的一些操作，可以参见官方文档：[http://api.mongodb.com/python/current/api/pymongo/](http://api.mongodb.com/python/current/api/pymongo/)。



