## 第3章：Python基础 - 下

---

### 3.1  函数

#### 3.1.1 函数的概念

所谓函数，就是把具有独立功能的代码快进行封装，成为一个小模块，在需要的时候调用即可。函数的使用包含两个步骤，第一步，定义函数，封装独立的功能；第二步，调用函数，享受封装的成果。函数的作用，在开发程序时，使用函数可以提高编写效率以及代码的重用。

```python
# 函数的定义
def 函数名():
    函数体 --> 被封装的代码块
    return --> 返回值

# 函数的调用
函数名()

# 创建第一个函数
fruit = "苹果"

# 解释器知道这里定义了一个函数
def eat_fruit():
    print("吃苹果")
# 只有在调用函数时，之前定义的函数才会被执行
print(fruit)
# 调用函数
eat_fruit()
# 函数执行完成之后，会重新回到之前的程序中，继续执行后续的代码
print(name)
```

> 注意：不能将函数调用放在函数定义的上方，因为在使用函数名调用函数之前，必须保证，Python已经知道函数的存在，否则程序报错：NameError: name 'eat_fruit' is not defined

#### 3.1.2 函数的参数

在调用函数的时候，可以给函数传递一些信息，这些信息就是参数。有了参数，就可以增加函数的通用性，针对相同的数据处理逻辑，能够适应更多的数据。参数分为 **实参** 和 **形参** 两类。

**形参**：定义函数时，小括号中的参数，是用来接收参数用的，在函数内部作为变量使用；

```python
# 形参
def func(a, b):

# 默认值形参， 如果实参不传递信息，默认值参数生效，如果实参传递参数，则默认值被修改，默认值参数放在最后面
def student(name, age, gender="male"):
  
# 动态传参
# *args 表示接收所有的位置参数动态传参,接收到位置参数会被处理成元祖类型
# **kwargs 表示接收所有关键字动态传参,接收到的关键字参数都会被处理成字典类型
def func(*args, **kwagrs):
```

**实参**：调用函数时，小括号中的参数，用来把数据传递到函数内部使用；

```python
# 定义函数
def func1(a, b, c):
    print(a, b, c)
# 调用函数并传参: a=1, b=2, c=3
# 位置参数，按照位置进行参数传递，实参与形参位置一一对应。
func1(1,2,3)


# 定义函数（关键字参数）
def func2(name="ethan", age=18, gender="male"):
    print(name, age, gender)
# 关键字参数，不用理会参数的位置，按照参数的名字进行传递参数，比如：name="Eric"
dunc2(name="Eric", gender="male", age=20)

# 混合参数:动态传参，参数数量没有限制，多少都可以，只要位置对应即可。
def func3(*args, **kwargs):
    print(args, kwargs)
# 混合参数，位置参数在前面，关键字参数在后面。如果顺序颠倒，程序会报错
func3("大米饭", name="五常大米")


# 通过实参进行动态传参
stu_list = ["张三","李四","王五","甲六","丙七","乙八"]
stu_dict = {"name":"张三","age":20}
def func4(*args, **kwargs):
    print(args)
    print(kwargs)

# 函数调用时，通过 * 或者 ** 传递实参位置，可以把列表 或者 字典 打散成位置参数 或者 关键字参数进行传递
func4(*stu_list) # 列表--位置参数
func4(**stu_dict)# 字典-- 关键字参数
```

> 参数的顺序问题：位置参数 > *args  >  默认值形参  >  **kwargs

#### 3.1.3 函数的返回值

函数执行后，告诉调用者一个结果，以便调用者对具体的结果做后续的处理，这个结果就是返回值。在函数中使用`return` 关键字返回结果。在调用函数一方，使用变量来接收函数的返回结果。返回值使用的逻辑：

1. 如果函数内没有`return` ，此时函数的返回值是 `None` ;
2. 如果函数内有 `return` ，当程序执行到 `return` 时会立刻停止并放回内容，`return` 后面的代码不会执行；
3. 定义函数时，如果函数内有逻辑代码，需要用 `return` 返回执行的结果；
4. 在调用函数时，把函数返回的结果赋值给变量，方便后续继续使用；

```python
# 实际使用return时的几种情况

# 1. 函数中存在return，后面没有数据，此时函数返回None
def func1():
    print("hello python")
    return
result = func1() # None


# 2. 函数中存在return，后面有一个数据，此时函数返回这个数据
def func2(a):
    a += 1
    return a
result = func1(1) # 2


# 3. 函数中存在return，后面有多个数据，此时函数通过元组的形式返回这些数据
def func3(a, b, c):
    a += 1
    b -= 2
    c == a
    return a, b, c
result = func3(1,2,3) # 2,0,2
```

> 综上所述：函数名实际上就是一个变量名，都表示一个内存地址。所以，函数可以作为返回值返回，也可以作为参数进行传递。

#### 3.1.4 函数的嵌套

一个函数里面又调用了另外一个函数，这就是函数嵌套调用。

```python
# 体验函数的嵌套
def func1():
    print(123)
    def func2():
        print(456)
        def func3():
            print(789)
        print(1)
        func3()
        print(2)
    print(3)
    func2()
    print(4)
func1()

# 打印结果
123 -> 3 -> 456 -> 1 -> 789 -> 2 -> 4

# 把函数作为返回值返回
def func():
    def inner():
        print(123)  # <function func.<locals>.inner at 0x0000017330629620>
    print(inner)
    return inner # 此时把inner函数当作返回值，注意没有小括号，如果加了小括号则是inner函数执行的结果

result = func()  # 此时result 就是 inner()函数
print(result) # <function func.<locals>.inner at 0x0000017330629620>
result() # 123

# 最终打印的的结果是
<function func.<locals>.inner at 0x0000017330629620>
<function func.<locals>.inner at 0x0000017330629620>
123


# 还有一种情况是函数的代理模式，就是实参是一个函数
def func(a): #此时a 收到的是一个函数
    a() # 执行传进来的函数

def target():
    print("我是target")

c = 123
func(target) # 实参是函数
# 输出内容
我是target

```

### 3.2 变量的作用域

​	作用域（Scope）是指变量在程序中可被访问的区域。Python中作用域分为以下四层（由内到外）：变量的查找顺序遵循LEGB规则：Local → Enclosing → Global → Built-in

局部作用域（Local）：函数内部定义的变量

```python
# 局部变量（Local Variable）在函数内部定义的变量，仅在函数内部有效
def func():
    local_var = 200  # 局部变量
    print(local_var)
    
func() # 输出：200
print(local_var) # 报错：NameError（无法访问局部变量）
  
```

外层函数作用域（Enclosing）：嵌套函数的外层函数变量

全局作用域（Global）：模块（文件）顶层定义的变量

```python
# 全局变量：（Global Variable）在函数外部定义的变量，可在整个模块中访问
global_var = 100  # 全局变量

def func():
    print(global_var)  # 可以访问全局变量

func() # 输出 100
```

内置作用域（Built-in）: Python内置的变量，如print、len

#### 3.2.1 `global`关键字、`nonlocal`关键字的使用

```python
# global 关键字,在函数内部声明并修改全局变量
x = 10
def modify_global():
    global x
    x = 20 # 修改全局变量x

modify_global()
print(x)  # 输出：20


# nonlocal 关键字，在嵌套函数中修改外层函数的局部变量
def outer():
    y = 30
    def inner():
        nonlocal y
        y = 40  # 修改外层函数的变量
    inner()
    print(y) # 输出40
outer()
```

> 全局变量与局部变量的冲突：如果局部变量与全局变量同名，函数内部优先使用局部变量。局部变量在函数执行结束后销毁，全局变量在程序执行结束后销毁。

### 3.3. 闭包和装饰器

#### 3.3.1  闭包

**概念：**当一个内层函数引用了其外层函数的变量，且外层函数返回内层函数时，内层函数与其引用的外层变量共同构成闭包。此时内层函数就被称为闭包函数

##### 3.3.1.1 闭包作用

可以让一个变量常驻在内存中

可以避免局部变量被修改，被污染，当多人协作完成程序时，很容易出现变量被修改的情况。

```python
# 闭包函数的实现

def outer():
    message = "Hello"  # 外层函数的局部变量
    def inner():       # 内存函数
        print(message) # 引用外层变量
    return inner       # 返回内部函数

closure_func = outer() # 调用外层函数，返回inner函数
closure_func()         # 输出：Hello（仍能访问message变量）
```

##### 3.3.1.2 使用场景

保持状态，比如实现计数器、缓存等需要保留状态的逻辑；装饰器，扩展函数功能；需要注意的是，闭包捕获的是变量的引用，而非值。若变量后续被修改，闭包中看到的是最终值。



#### 3.3.2 装饰器

##### 3.3.2.1 定义

装饰器是一个用于扩展函数功能的工具，它接受一个函数作为输入，返回一个新的函数。装饰器通过闭包实现，语法上使用`@decorator` 的形式

##### 3.3.2.2 核心作用

不修改原函数代码：通过包裹函数，添加额外功能（如日志、计时、权限校验）

代码复用：将逻辑通用（如异常处理）封装成装饰器，应用于多个函数

##### 3.3.2.3 装饰器实现

```python
# 定义一个装饰器，打印函数执行时间
import time

def timer(func):  # func 是目标函数 ->heavy_task
    def wrapper(*args, **kwargs):
        start = time.time() # 在目标函数前执行
        result = func(*args, **kwargs) # 执行目标函数
        end = time.time() # 在目标函数后执行
        print(f"{func.__name__}执行耗时：{end - start:.2f}秒")
        return result
    return wrapper

# 使用装饰器
@timer
def heavy_task():
    time.sleep(2)

heavy_task() # 输出：heavy_task 执行耗时：2.00秒

# 装饰器可以叠加使用，执行顺序从下到上
@decorator1
@decorator2
def func():
    pass

# 等价于：
func = decorator1(decorator2(func))


# 实际应用场景：权限校验
def check_login(func):
    def wrapper(user, *args, **kwargs):
        if not user.is_authenticated:
            raise PermissionError("请先登录")
        return func(user, *args, **kwargs)
    return wrapper

@check_login
def view_profile(user):
    print(f"用户信息: {user.name}")
```



### 3.4  迭代器和生成器

#### 3.4.1 迭代器（Iterator）

**迭代器：**可以逐个访问集合元素的对象，遵循迭代器协议（实现`__iter__()`和`__next__()`方法）

**可迭代对象（Iterable）：**能够返回迭代器的对象（如列表、元组、字典等）

**获取迭代器的两种方案：**

1. `iter()`内置函数可以直接拿到迭代器

2. `_ _iter_ _ ()`特殊方法 

**从迭代器中拿到数据：**

1. `next()`内置函数
2. `__next ()__`特殊方法

`for`里面一定是要拿迭代器的，所以，所有不可选代的东西不能用`for循环`for循环里面一定有`__next__` 出现

**迭代器的特性**

1. 惰性计算：逐个生成元素，节省内存
2. 一次性遍历：遍历结束后需重新创建迭代器

**总结：迭代器统一了所有不同数据类型的遍历工作**

**迭代器的实现**

```python
# 手动创建迭代器类
class Counter:
    def __init__(self, start, end):
        self.current = start
        self.end = end

    def __iter__(self):    # 返回迭代器自身
        return self

    def __next__(self):    # 定义迭代逻辑
        if self.current >= self.end:
            raise StopIteration
        else:
            self.current += 1
            return self.current - 1

# 使用迭代器
counter = Counter(1, 5)
for num in counter:
    print(num)  # 输出：1 → 2 → 3 → 4
    

# 内置迭代器
numbers = [1, 2, 3]
it = iter(numbers)    # 将列表转为迭代器
print(next(it))       # 输出：1
print(next(it))       # 输出：2
```



#### 3.4.2 生成器（Generator）

**定义与核心概念**：生成器是一种特殊的迭代器，使用 `yield` 关键字动态生成值。生成器函数，就是包含 `yield` 的函数，调用时返回生成器对象。生成器表达式，类似列表推导式，但返回生成器。

**生成器的特性**：

1. 惰性计算：仅在需要时生成值，适合处理大规模数据。
2. 状态保存：每次 yield 后保存当前执行状态，下次继续执行。
3. 内存高效：无需预先生成所有数据。

**生成器的实现**

```python
# 生成器函数
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        yield a	 # 生成值并暂停
        a, b = b, a+b

# 使用生成器
fib_gen = fibonacci(5)
for num in fib_gen:
    print(num)  # 输出：0 → 1 → 1 → 2 → 3

# 生成器表达式
squares = (x**2 for x in range(5))  # 生成器表达式
print(list(squares))                # 输出：[0, 1, 4, 9, 16]


# 实际应用场景：处理大型文件，生成器逐行读取文件
def read_large_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            yield line.strip()  # 逐行生成，避免内存溢出

for line in read_large_file("data.txt"):
    print(line)
```

> `yield` 与 `return` 的区别：`yield` 暂停函数执行并返回值，下次从暂停处继续。`return` 终止函数执行并返回值。

### 3.5  推导式

```python
# 推导式:作用就是用来简化代码

# 语法:
列表推导式:[数据 for循环 if判断]
集合推导式:{数据 for循环 if判断}
字典推导式:{k:v for循环 if判断}

不要把推导式妖魔化.
(数据 for循环 if判断) -> 不是元组推导式，根本就没有元组推导式,这玩意叫生成器表达式


# 示例
lst = [i for i in range(10)]
print(lst)

lst = ["迪丽热巴","迪丽冷巴","迪丽不冷巴"]
dic = {i:lst[i] for i in range(len(lst))}
print(dic)
```

### 3.6 匿名函数

​	**匿名函数**（Lambda函数）是使用 lambda 关键字定义的单行小型函数，无需显式命名。

​	**语法**：lambda 参数列表: 表达式

​	**特点**：没有函数名，适合临时使用；只能包含一个表达式，不能包含复杂逻辑（如循环、条件分支需用三元表达式）

​	**基本用法示例**

```python
# 简单计算
add = lambda x, y : x + y
print(add(1,2)) # 输出3

# 结合内置函数使用，例如：map() 和 filter()
# 对列表中的每个元素进行平方计算
numbers = [1, 2, 3, 4, 5]
squared = list(map(lambda x:x**2,number))
print(squared) # 输出: [1, 4, 9, 16, 25]

# 使用filter()筛选偶数
even = list(filter(lambda x:x%2 == 0, numbers))
print(even) # 输出：[2,4]
```

### 3.7 递归函数

**递归**：函数直接或间接调用自身，通过分解问题为更小的子问题来解决问题。

**核心要素**：递归的终止条件，防止无限递归；递归步骤，将问题分解为更小的同类问题

```python
# 递归的简单实现

# 1.计算阶乘
def factorial(n):
    if n ==0: # 终止条件
        return 1
    else:
        return n * factorial(n-1) # 递归调用

print(factorial(5)) # 输出120
```

### 3.8 内置函数

所谓内置函数，就是可以省去定义的步骤，直接拿来用即可。

##### 3.8.1 数据处理类

| 函数        | 说明                             | 示例                                                         |
| ----------- | -------------------------------- | ------------------------------------------------------------ |
| enumerate() | 返回索引和元素组成的枚举对象     | for idx, url in enumerate(urls): <br />print(f"索引{idx}: {url}") |
| len()       | 返回对象的长度（元素个数）       | len([1,2,3]) → 3                                             |
| zip()       | 将多个可迭代对象的元素配对为元组 | names = ["a", "b"]; ages = [20, 30]; <br />list(zip(names, ages)) → [('a',20), ('b',30)] |
| map()       | 对每个元素应用函数处理           | list(map(str.upper, ["a", "b"])) → ['A', 'B']                |
| filter()    | 过滤出满足条件的元素             | list(filter(lambda x: x > 0, [-1, 2, -3, 4])) → [2, 4]       |
| sorted()    | 返回排序后的列表                 | sorted([3,1,2], reverse=True) → [3, 2, 1]                    |
| range()     | 生成整数序列                     | list(range(1, 5)) → [1, 2, 3, 4]                             |

##### 3.8.2 类型转换类

| 函数        | 说明                           | 示例                                           |
| ----------- | ------------------------------ | ---------------------------------------------- |
| str()       | 将对象转换为字符串             | str(3.14) → '3.14'                             |
| bytes()     | 将对象转换为字节序列           | bytes("hello", "utf-8") → b'hello'             |
| int()       | 将字符串或数字转换为整数       | int("100") → 100                               |
| dict()      | 创建字典或转换键值对为字典     | dict([('a',1), ('b',2)]) → {'a':1, 'b':2}      |
| list()      | 将可迭代对象转换为列表         | list("abc") → ['a', 'b', 'c']                  |
| tuple()     | 将可迭代对象转换为元组         | tuple([1,2,3]) → (1,2,3)                       |
| float()     | 将字符串或数字转换为浮点数     | float("3.14") → 3.14                           |
| bool()      | 返回对象的布尔值               | bool("") → False                               |
| set()       | 将可迭代对象转换为集合（去重） | set([1,1,2]) → {1, 2}                          |
| bytearray() | 创建可变的字节数组             | bytearray(b"abc")[0] = 100 → bytearray(b'dbc') |
| chr()       | 返回Unicode码对应的字符        | chr(65) → 'A'                                  |
| ord()       | 返回字符的Unicode码            | ord('A') → 65                                  |

##### 3.8.3 文件操作类

| 函数   | 说明                   | 示例                                                         |
| ------ | ---------------------- | ------------------------------------------------------------ |
| open() | 打开文件并返回文件对象 | with open("data.txt", "r", encoding="utf-8") as f: <br />print(f.read()) |
|        |                        |                                                              |

##### 3.8.4 辅助调试类

| 函数         | 说明                     | 示例                                  |
| ------------ | ------------------------ | ------------------------------------- |
| print()      | 输出调试信息             | print("当前URL:", url)                |
| type()       | 返回对象的类型           | type(100) → <class 'int'>             |
| isinstance() | 检查对象是否为指定类型   | isinstance(100, int) → True           |
| id()         | 返回对象的内存地址       | id("abc") → 140000000（示例值）       |
| dir()        | 返回对象的属性列表       | dir(list) → ['append', 'extend', ...] |
| help()       | 查看函数或模块的帮助文档 | help(str.split)                       |

##### 3.8.5 数据统计类

| 函数     | 说明                             | 示例                    |
| -------- | -------------------------------- | ----------------------- |
| sum()    | 计算数值迭代器的总和             | sum([1,2,3]) → 6        |
| min()    | 返回迭代器中的最小值             | min([3,1,4]) → 1        |
| max()    | 返回迭代器中的最大值             | max([3,1,4]) → 4        |
| abs()    | 返回数值的绝对值                 | abs(-10) → 10           |
| round()  | 对浮点数四舍五入                 | round(3.1415, 2) → 3.14 |
| divmod() | 返回商和余数的元组               | divmod(10, 3) → (3, 1)  |
| pow()    | 计算幂运算（等价于 `**` 运算符） | pow(2, 3) → 8           |

##### 3.8.6 动态执行类

了解即可，慎用，存在安全隐患和代码维护风险，如注入攻击

| 函数   | 说明                     | 示例                          |
| ------ | ------------------------ | ----------------------------- |
| eval() | 执行字符串表达式并返回值 | eval("3 + 5 * 2") → 13        |
| exec() | 执行动态代码块           | exec("a = 10"); print(a) → 10 |




