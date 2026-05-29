## 第二章：Python基础 - 中

---

### 2.1 数据类型

​	在Python中数据类型可以分为 **数字型** 和 **非数字型**。数字型包括：int、float、Bool、复数型。非数字型包括：字符串、列表、元组、字典。而且在Python中，所有 **非数字型变量** 都支持以下特点：

```python
都是一个序列sequence，也可以理解为 容器
取值 []
遍历 for in 
计算长度、最大/最小值、比较、删除
链接 + 和 重复 *
切片
```



#### 2.1.1 列表

##### 2.1.1.1 列表的定义

1. List（列表）是Python中使用最频繁的数据类型，在其他语言中常用叫做数组
2. 专门用于存储一串信息
3. 列表使用`[]` 定义，数据之间使用`,` 分隔
4. 列表的索引从 0 开始，索引就是数据在列表中的位置编号，索引又可以成为下标。如果超出索引范围，程序会报错。

```python
# 定义列表
name_list = []
name_list = list()
name_list = ["张三","李四","王五"]
```

![image-20250427105619575](../media-unavailable/image-20250427105619575.png)

##### 2.1.1.2 列表的常用操作

| 序号 | 分类 | 关键字 / 函数 / 方法    | 说明                       |
| ---- | ---- | ----------------------- | -------------------------- |
| 1    | 增加 | 列表.insert(索引，数据) | 在指定位置插入数据         |
|      |      | 列表.append(数据)       | 在末尾追加数据             |
|      |      | 列表.extend(列表2)      | 将列表2的数据追加到列表中  |
| 2    | 修改 | 列表[索引] = 数据       | 修改指定索引的数据         |
| 3    | 删除 | del 列表[索引]          | 删除指定索引的数据         |
|      |      | 列表.remove[数据]       | 删除第一个出现的指定数据   |
|      |      | 列表.pop                | 删除末尾数据               |
|      |      | 列表.pop[索引]          | 删除指定索引数据           |
|      |      | 列表.clear              | 清空列表                   |
| 4    | 统计 | len(列表)               | 计算列表的长度             |
|      |      | 列表.count(数据)        | 计算数据在列表中出现的次数 |
| 5    | 排序 | 列表.sort()             | 升序排序                   |
|      |      | 列表.sort(reverse=True) | 降序排序                   |
|      |      | 列表.reverse()          | 逆序、反转                 |

> del 关键字（delete）本质上是用来将一个变量从内存中删除的。如果使用 del 关键字将变量从内存中删除，后续的代码就不能再使用这个变量了。所以在日常开发中，要从列表删除数据，建议使用列表提供的方法 

```python
list = [1,2,3,4,"张三","李四","王五"]

# 循环列表中的元素
for i in list:
  print(i)

# 循环列表的索引
for i in range(len(list)):
  print(list[i])
```



#### 2.1.2 元组

##### 2.1.2.1 元组的定义

`Tuple` (元组) 与列表类似，不同之处在于元素的 **元素不能修改**。元组表示多个元素组成的序列。元组使用`()` 定义，数据之间使用 ， 分隔，并且元组的索引是从 0 开始

```python
# 创建空元组
first_tuple = ()

# 有元素的元组
first_tuple = (1,3.14,"张三")

# 元组中只包含一个元素时，需要在元素后面添加逗号，否则报错
first_tuple = ("张三",)
```

##### 2.1.2.2 元组的常用操作

因为元素不能修改的原因，所以元组的操作比较少

| 序号 | 类别     | 关键字 / 函数 / 方法 | 说明                       |
| ---- | -------- | -------------------- | -------------------------- |
| 1    | 计算     | 元组.count(元素)     | 计算元素在元组中出现的次数 |
| 2    | 获取索引 | 元组.index(元素)     | 获取元素第一次出现的索引   |
| 3    | 取值     | 元组[索引]           | 从元组中取值               |
| 4    | 计算长度 | len(元组）           | 获取元组的长度             |



#### 2.1.3 字典

`dictionary (字典)` 是除列表以外，Python中最灵活的数据类型。字典同样可以用来存储多个数据，通常用于存储描述一个物体的相关信息。字典和和列表的区别：

1. 列表是 **有序** 的对象集合
2. 字典是 **无序** 的对象集合

##### 2.1.3.1 字典的用法

1. 使用 `{}` 定义
2. 字典使用**键值对** 存储数据，键值对之间使用逗号分隔
3. **键** `key` 是索引
4. **值** `value` 是数据
5. **键** 和 **值** 之间使用 `:` 分隔
6. **键**必须是唯一的
7. **值**可以取任何数据类型，但是**键**只能使用 **字符串、数字或元组**

```python
xiaoming = {
  "name":"小明",
  "age":18,
  "gender":"男",
  "height":1.75
}

# 字典中的循环遍历
for key in xiaming:
  print(k,xiaoming[k]) # k -> key ; xiaoming[k] -> value

# 利用解包思路获取key与value : a,b = (1,2) a=1,b=2
for key,value in dict.items():
  print(key,value)
```

![image-20250427122037516](../media-unavailable/image-20250427122037516.png)

##### 2.1.3.2 字典的常用操作

 `dict` 代指下表中的字典

| 序号 | 类别         | 关键字/函数/方法           | 说明                                                     |
| ---- | ------------ | -------------------------- | -------------------------------------------------------- |
| 1    | 查询         | len(dict)                  | 获取字典dict的键值对数量                                 |
|      |              | dict.keys()                | 获取字典dict中所有的key                                  |
|      |              | dict.values()              | 获取字典dict中所有的value                                |
|      |              | dict.items()               | 获取字典dict中的key,value,通过元组类型返回               |
|      | 解构（解包） | key,value = dict.items()   | key,value = ("key","value")                              |
| 2    | 取值         | dict[key]                  | 从字典dict中取值，key不存在会报错                        |
|      |              | dict.get(key)              | 从字典dict中取值，key不存在，不会报错，返回None          |
| 3    | 删除         | del dict[key]              | 删除指定键值对，key不存在会报错                          |
|      |              | dict.pop(key)              | 删除指定键值对，key不存在会报错                          |
|      |              | dict.popitem()             | 随机删除一个键值对                                       |
|      |              | dict.clear()               | 清空字典                                                 |
| 4    | 修改/新建    | dict[key] = value          | 如果key存在，修改数据<br />如果key不存在，新建键值对     |
|      |              | dict.setdefault(key,value) | 如果key存在，不会修改数据<br />如果key不存在，新建键值对 |
|      |              | dict.update(dict2)         | 将字典2的数据合并到字典1中                               |



#### 2.1.4 字符串

##### 2.1.4.1 字符串的定义

字符串就是一串字符，是编程语言中表示文本的数据类型。可以使用一对双引号，或者一对单引号定义一个字符串。字符串可以使用索引获取一个字符串中指定位置的字符，索引计数从 0 开始。

```python
str = "hello python"
str1 = 'hello python'
```



##### 2.1.4.2 字符串的常用操作

**判断类型**

| 方法            | 说明                                                         |
| --------------- | ------------------------------------------------------------ |
| str.isspace()   | 检查字符串**是否全是空白字符**（空格、/t、/n等），是则返回True |
| str.isalnum()   | 检查字符串**是否仅由字母或数字组成**（不能含符号或空格），是则返回 True |
| str.isalpha()   | 检查字符串**是否全是字母**（不区分大小写，中文字符也算字母），是则返回 True |
| str.isdecimal() | 检查字符串**是否全是十进制数字字符**（0-9），是则返回 True   |
| str.isdigit()   | 检查字符串**是否全是数字字符**（包括特殊数字如²、³），是则返回True。 |
| str.isnumeric() | 检查字符串**是否全是数字字符**（包括汉字数字、罗马数字等），是则返回 True |
| str.istitle()   | 检查字符串**是否每个单词首字母大写**，其余字母小写，是则返回 True |
| str.islower()   | 检查字符串**是否全为小写字母**（至少一个字母，且无大写），是则返回 True |
| str.isupper()   | 检查字符串**是否全为大写字母**（至少一个字母，且无小写），是则返回 True |

```python
print("   ".isspace())   # True（全空格）
print("/t/n".isspace())  # True（制表符+换行）
print("abc123".isalnum())  # True
print("Hello".isalpha())  # True
print("123".isdecimal())    # True
print("123".isdigit())      # True
print("²".isdigit())        # True（Unicode上标数字）
print("123".isnumeric())    # True
print("Ⅷ".isnumeric())      # True（罗马数字8）
print("三".isnumeric())      # True（汉字数字）
print("Hello World".istitle())  # True
print("hello".islower())    # True
print("HELLO".isupper())    # True
```

**查找和替换**

| 方法                                    | 说明                                                         | 示例                            |
| --------------------------------------- | ------------------------------------------------------------ | ------------------------------- |
| s.startswith(str)                       | 检查字符串**是否以指定子字符串开头**，是则返回True           | text.startswith("Hello")        |
| s.endswith(str)                         | 检查字符串**是否以指定子字符串结尾**，是则返回True           | text.endswith("World!")         |
| s.find(str, start=0, end=len(string))   | 查找子字符串在字符串中的**首次出现位置**，找不到返回 `-1`    | text.find("apple", 5)           |
| s.rfind(str, start=0, end=len(string))  | 查找子字符串在字符串中的**最后一次出现位置**，找不到返回 `-1` | text.rfind("banana", 0, 10)     |
| s.index(str, start=0, end=len(string))  | 与`find()`类似，但找不到子字符串时会**抛出`ValueError`异常** |                                 |
| s.rindex(str, start=0, end=len(string)) | 与`rfind()`类似，但找不到子字符串时会**抛出异常**            |                                 |
| s.replace(old_str, new_str, num）       | 将字符串中的`old_str`替换为`new_str`，可指定替换次数，`num`（可选，最多替换次数） | text.replace("cats", "dogs", 1) |

**大小写转换**

| 方法           | 说明                                                   | 示例                                                         |
| -------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| s.capitalize() | 将字符串的**第一个字符大写**，其余字符全部小写         | s = "hello WORLD" <br />print(s.capitalize())  # 输出: Hello world |
| s.title()      | 将字符串中**每个单词的首字母大写**，其余字母小写       | s = "hello world" <br />print(s.title())       # 输出: Hello World |
| s.lower()      | 将字符串中**所有大写字母转换为小写**                   | s = "HELLO World" <br />print(s.lower())       # 输出: hello world |
| s.upper()      | 将字符串中**所有小写字母转换为大写**                   | s = "Hello World" <br />print(s.upper())       # 输出: HELLO WORLD |
| s.swapcase()   | 将字符串中的**大写字母转换为小写，小写字母转换为大写** | s = "Hello World" <br />print(s.swapcase())    # 输出: hELLO wORLD |

**去除空白字符**

| 方法            | 说明                               | 示例 |
| --------------- | ---------------------------------- | ---- |
| string.strip()  | 截掉 string 左右两边的空白字符     |      |
| string.lstrip() | 截掉 string 左边（开始）的空白字符 |      |
| string.rstrip() | 截掉 string 右边（末尾）的空白字符 |      |

**拆分和连接**

| 方法                   | 说明                                                         | 示例                                                         |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| string.partition(str)  | 根据第一个匹配的 `str` 将字符串**分割为三部分**（左、分隔符、右），返回一个元组 `(左, 分隔符, 右)` | s = "Python-is-fun" print(s.partition("-"))  <br /># 输出: ('Python', '-', 'is-fun') |
| string.rpartition(str) | 与 `partition()` 类似，但**从右侧开始查找分隔符**            |                                                              |
| string.split("/", num) | 根据分隔符将字符串**分割为列表**，可指定分割次数 `num`（默认全部分割）。 | print(s.split(","))<br />print(s.split(",", 2))              |
| string.splitlines()    | 按**换行符**（`/n`、`/r`、`/r/n`）分割字符串为列表，`keepends` 控制是否保留换行符 | print(s.splitlines())<br />print(s.splitlines(True))         |
| string.join(seq)       | 将序列 `seq` 中的元素用当前字符串**连接成一个新字符串**。    | "-".join(words)                                              |

**字符串的切片**

切片方法适用于字符串、列表、元组。切片使用索引值来限定范围，从一个大的字符串中切出小的字符串。

```python
字符串[开始索引 : 结束索引 : 步长]
```



![image-20250427153744080](../media-unavailable/image-20250427153744080.png)

指定的区间属于 **左闭右开** 型 [ 开始索引，结束索引 )，就是从开始位置开始，到结束位置的前一位结束，并不包含结束位置

如果头开始，开始索引的数字是可以省略的，例如 [ : 10 ]

到末尾结束，结束索引的数字是可以省略的，列入 [ : ]

步长默认为 1 ，如果连续切片，数字和冒号都可以省略 例如：[ 0 : 10 : ]

倒序索引就是 **从右向左** 计算索引，最右边的索引值是 **-1**，依次递减

```python
# 小练习
str = "https://example.com"

# 1. 截取从 2 ~ 5 位置 的字符串
print(str[2:6])

# 2. 截取从 2 ~ 末尾的字符串
print(str[2:])

# 3. 截取从开始~ 5位置 的字符串
print(str[:6])

# 4. 截取完整的字符串
print(str[:])

# 5. 从开始位置，每隔一个字符截取字符串
print(str[::2])

# 6. 从索引1开始，每隔一个取一个
print(str[1::2])

# 倒序切片
# -1 表示倒数第一个字符
print(str[-1])

# 7. 截取从2 ~ 末尾-1的字符串
print(str[2:-1])

# 8. 截取字符串末尾两个字符
print(str[-2:])

# 9. 字符串的逆序（面试题）
print(str[::-1])
```



#### 2.1.5 集合

集合（Set）是一种无序、可变、元素唯一的容器，用于存储不重复的数据。

集合的特点：

1. 元素唯一性：几个钟的元素不可重复
2. 无序性：元素没有固定顺序，不支持索引操作
3. 元素不可变性：集合中的元素必须是不可变类型（如数字、字符串、元组），不能包含列表或者字典

##### 2.1.5.1 创建方式

```python
# 非空集合
s1 = {1,2,3}
s2 = set([1,2,2,3,4,3,2])  # 输出：{1,2,3,4}(自动去重)

# 空集合（必须用set()）
empty_set = set()
not_empty_dict = {} # 这是空字典，不是集合
```

##### 2.1.5.2 常用操作

集合 s = { 1 , 2 }

| 方法                | 说明                           | 示例                      |
| ------------------- | ------------------------------ | ------------------------- |
| s.add(3)            | 添加单个元素                   | {1,2,3}                   |
| s.update([4,5])     | 添加多个元素                   | {1,2,3,4,5}               |
| s.remove(2)         | 删除元素2，若不存在则报错      |                           |
| s.discard(4)        | 删除元素4，若不存在不报错      |                           |
| s.pop()             | 随机删除一个元素（因集合无序） |                           |
| s.clear()           | 清空集合 → set()               |                           |
| s1.intersection(s2) | 交集，集合1 & 集合2            | {1,2} & {2,3} → {2}       |
| s1.union(s2)        | 并集，集合1 /| 集合2           | {1,2} /| {2,3} -> {1,2,3} |
| s1.difference(s2)   | 差集，集合1 - 集合2            | {1,2} - {2,3} → {1}       |

需要重点掌握快速去重功能

```python
lst = [1,2,3,3,4]
unique_set = set(lst) # {1,2,3}
unique_lst = list(unique_set) # [1,2,3]
```



#### 2.1.6 字节

字节（Bytes）是Python中用于表示二进制数据的数据类型，由0-255之间的整数构成的**不可变序列**。

```python
# 字面量创建（前缀 b）
b1 = b"hello"  # 输出b'hello'

# 空字节对象
empty_bytes = bytes()  # 输出：b''
```

##### 2.1.6.1 与字符串之间的转换

```python
# 编码 encode 字符串 -> 字节
# 解码 decode 字节 -> 字符串

s = "你好"
bytes_data = s.encode("utf-8")  # 字符串转字节 --> b'/xe4/xbd/xa0/xe5/xa5/xbd'
s_back = bytes_data.decode("utf-8") # 字节转字符串 → "你好"
```

##### 2.1.6.2 字符集和编码

**核心概念**

字符集：定义字符与数字的映射关系（如ASCII、Unicode）
1. ASCII：编排了128个文字字符，1bytes = 8bit
2. Unicode：
3. UTF-8：可变长度的Unicode，最短的字节长度是8bit

编码：将字符转换为二进制数据的规则（如utf-8、GBK）



### 2.2 文件操作

​	文件操作指通过程序对计算机文件进行读取、写入、修改、删除等操作。保存爬取的网页、图片、视频等原始数据或者存储清洗后的结构化数据（csv、json）等。

#### 2.2.1 文件的打开与关闭

```python
# 打开文件
open(file,mode,encoding) # mode模式
```

| 模式 | 说明                                | 示例                                       |
| ---- | ----------------------------------- | ------------------------------------------ |
| r    | 只读（默认）                        | open("data.txt",mode="r",encoding="utf-8") |
| w    | 写入（覆盖文件）,文件不存在自动创建 | open("data.txt",mode="w",encoding="utf-8") |
| a    | 追加（在文件末尾添加内容）          | open("data.txt",mode="a",encoding="utf-8") |
| b    | 二进制模式（图片、视频），wb/rb     | open("imge.jpg",mode="rb")                 |

```python
# 关闭文件 使用close() 或 with 语句自动关闭

# 手动关闭
f = open("data.txt",mode="r",encoding="utf-8")
content = f.read()
f.close()

# 自动关闭
with open("data.txt",mode="r",encoding="utf-8") as f:
  content = f.read()
```

#### 2.2.2 常用操作内容

##### 2.2.2.1 读取全部内容

```python
with open("data.txt", "r", encoding="utf-8") as f:
    content = f.read() # 返回整个内容的字符串
```

##### 2.2.2.2 逐行读取

```python
with open("data.txt", "r", encoding="utf-8") as f:
    for line in f: # 逐行遍历
        print(line.strip()) # 去除两端的空白符

# 注意readline 和 readlines 的区别
readline() 逐行读取，返回单行字符串（包含换行符） 使用场景：处理大文件，逐行加载，避免内存不足
readlines() 全量加载，一次性读取所有行到列表中  使用场景：文件较小且需要一次性处理所有行

```

##### 2.2.2.3 写入内容

```python
# w模式下，每一次open都会清空文件中的内容重新写入
with open("output.txt", "w", encoding="utf-8") as f:
    f.write("Hello,World!/n")
    f.writelines(["line1/n","line2/n"]) # 写入多行
```

##### 2.2.2.4 二进制文件操作(图片、视频)

```python
# 下载图片并保存
import requests
url = "https://example.com/image.jpg"
response = requests.get(url)
with open("image.jpg", "wb") as f : # 使用二进制模式
    f.write(response.content)
```

##### 2.2.2.5 结构化数据存储（CSV/JSON）

```python
import csv
data = [["Name","Age"],["Alice",30],["Bob",25]]
with open("data.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(data)

# json文件
import json
data = {"nama":"alice","age":18}
with open("data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False) # 禁用ASCII转义，支持中文

# 字符串转换成字典
dic = json.loads(s)
# 字典转成字符串
s = json.dumps(dic)

# 在相互转换的时候需要注意一个问题：前端生成的JSON内容之间是没有空格的，但是Python程序生成的JSON使有空格，服务器在检验JSON的时候就会判断是否有空格，可以通过下面的方式解决这个问题：
separators 分隔符
s = json.dumps(dic, sparators=(',', ':')) # 用的时候按住Ctrl+单机，进入源码中可以直接复制
```



##### 2.2.2.6 检查文件是否存在

```python
import os
if os.path.exists("data.txt"):
    print("文件存在")
```

##### 2.2.2.7 创建目录

```python
os.makedirs("downloads",exist_ok=True) # 自动创建多级目录

file_path = "./abc/a/bn/c/f.txt"
os.path.basename(file_path) # f.txt   取路径下的文件名
os.path.dirname(file_path) # ./abc/a/bn/c  取路径，不包括文件名
os.path.isdir() # 判断是否为文件夹
```

##### 2.2.2.8 遍历目录文件

```python
for root, dirs, files in os.walk("downloads"):
    for file in files:
        print(os.path.join(root, file)) # 输出完整路径
```

##### 2.2.2.9 异常处理

程序出现错误的时候，别中断，继续执行

```python
try:
    with open("data.txt", "r", encoding="utf-8") as f:
        content = f.read()
except FileNotFoundError as e:# 针对不同的错误，对应做不同的处理
    print("文件不存在", e)
except PermissionError as e1:
    print("无权访问文件", e1)
finally：
    # 有没有报错，都会执行，收尾工作
```

e 接收错误信息比较笼统，如果想要看到哪个文件、文件中的哪一行出错了，则需要看堆栈信息

```python
# 需要堆栈信息包，可以看到当前程序的堆栈信息
import traceback

except PermissionError as e1:
    print("无权访问文件", e1)
    print(traceback.format_exc())
```

爬虫实战中的做法：之所以分开文件保存，就是为了方便后续利用程序去操作内容

```python
f1 = open("错误堆栈信息.txt", mode="a", encoding="utf-8")
f2 = open("报错信息.txt", mode="a", encoding="utf-8")
    
def send_request(page):
    for i in range(5): # 如果出现错误，重试次数
        try:
            print(10 / (page - 7)) # 第7页的时候会报错
            print(f"{page}页数据提取完成")
            time.sleep(2)
            return
        except Exception as e:
            f1.write(traceback.format_exc()) # 记录堆栈信息
            f1.write("/n")
            time.sleep(2)
    f2.write(f"{page}页出错了") # 记录报错的信息
    f2.write("/n")
def main():
    for i in range(1, 100):
        send_request(i)
        
if __name__ == "__main__":
    main()
```

> raise 主动抛出异常，raise + 错误异常，程序已经没有办法继续进行下去了，主动抛出异常。

##### 2.2.2.10 日志记录

```python
import logging
logging.basicConfig(filename="spider.log", level=logging.INFO)
logging.info("爬虫已启动")
```

##### 2.2.2.11 文件复制

```python
# 从源文件中读取出来，写入到新路径下文件的方式
with open("data.txt", mode="rb") as f1, open("image.jpg", mode="wb") as f2:
    f2.write()
```

##### 2.2.2.12 文件修改

```python
"""
操作步骤：
1. 在原文件中逐行读出内容
2. 在内存中对内容进行修改
3. 把修改后的内容写入新文件
4. 删除源文件
5. 把新文件命名为源文件的名字
"""
# 执行程序足够快，因此对用户而言是无感的，也就达到了直接修改的目的
with open("用户名单.txt", mode="r", encoding="utf-8") as f1, open("用户名单_副本.txt", mode="w", encoding="utf-8") as f2:
    for line in f1:
        line = line.strip() # 去掉两端的空白符
        if line.startswith("周"):
            line = line.replace("周", "张") # 修改
        f2.write(line)
        f2.write("/n")
# 删除源文件
os.remove("用户名单.txt")
# 把副本文件重命名为源文件
os.rename("用户名单_副本.txt","用户名单.txt")
```




