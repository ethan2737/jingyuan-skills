## 第19节：JavaScript基础知识 - 上

---

`JavaScript`是能在浏览器运行的脚本语言。作为爬虫工程师，要了解的是`JavaScript`是如何发送请求的，又是如何处理返回的响应的。一般情况下都是对请求参数、请求头、`cookie`中的内容进行加密，响应返回`json`也会对数据进行加密。但是无论对数据怎么加密，在浏览器显示的时候一定是要解密的，不然无法正常显示。

**所以逆向的目标是：知道`JavaScript`的加密过程，能够发送出服务器接收的请求，知道`JavaScript`的解密过程，能够还原数据。**

在进行`JavaScript`逆向的时候很难受，因为前端工程师会把简单的`JavaScript`代码进行简化，然后在进行混淆，混淆后的代码看起来就比较恶心。但实际上，`JavaScript`其实并不难。

JavaScript 官方学习文档：https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference

### 19.1 引入方式

在`pycharm`中新建HTML文件，在HTML中任何地方引入`<script></script>`标签即可引入`JavaScript`代码。并且可以在浏览器中调试。

```javascript
<!-- 这是HTML的注释：这种方式是在HTML文件中通过标签直接写JavaScript -->
// javascrip 脚本引入方式1：
<script>
  // 这是JavaScript中的单行注释
  /* 多行注释 */ 
  // alert 是警告窗口
  alert("输出一句话到浏览器窗口");  //后面的分号表示一句话的结束
  // 目前都使用这样的方式输出内容 console叫做控制台，F12后可以看到Console
  console.log("在控制台输出一句话");
</script>

// 引入方式2：引入一个js文件，把这个文件引入进来，并自动执行。当网页加载时，逐行执行代码，当执行到这行代码时，发现是一个外部文件引入，所以他会自动请求这个src获取到js文件代码，并自动执行。所以，每一次js的加载都看作一次请求。
<Script src="JavaScript—name.js"></Script>
```

> 注意：很多时候，网站的数据会被包装在js文件中返回。所以，js就把它当作一次请求。



### 19.2 基本数据类型

```javascript
// javascript 中的几种数据类型
number  数字  不论是整数还是小数，数据类型都是number
string  字符串，这个没啥可聊的.就是很单纯的字符串
boolean  布尔值，只有两个，true和false.注意不是大写T和F
object 对象，这个比较特殊，你可以理解为所有被 new 出来的东西都是对象，除了基本数据类型外，都是对象比如：{}、[]等等
undefined，这个表示未定义，所有没有被定义过的东西默认都是该类型 类似像空一样的东西
```

变量命名规范：

- 区分大小写
- 第一个字符必须是字母、下划线或者美元符号（$）
- 其他字符可以是字母、下划线、美元符号或者数字

```javascript
// 声明变量:
var 变量名; // 创建变量, 此时该变量除了被赋值啥也干不了. 
var 变量名 = 值; // 创建一个变量, 并且有值. 
var 变量名 = 值1, 变量名2 = 值2, 变量名3 = 值3.....; // 一次创建多个变量.并都有值
var 变量名1, 变量名2, 变量名3 = 值3;  // 创建多个变量. 并且只有变量3有值

// 先声明，不赋值
var name;
console.log(typeof name) //在控制台查看name的类型
// 声明很多变量
var name,age,gender;
//综合声明变量:声明了很多变量，有的赋值了，有的没有，主要看是否有=
var a, b, c, d, e=5, f=8, g, h;
var a, b, c, d, e, f, g, h="hahahha"; 

```

> 结尾的 ；代表一句话的结束，通常网站的js代码都是通过压缩后显示的，显示在一行，所以要通过这个 ; 知道一句话在哪里结束。

```javascript
// 逻辑运算符 && || ！ 并且，或者，非
<script>
	var a=3，b=5，c=7;
	console.log(a>b && b>c)	// 并且 短路与 F
	console.log(a<c || a>b)	// 或者 短路或者 T
	console.log(!(a < c))	// 非 F

	// == 和 === 的区别
	var a = "123";
	var b = 123;
	console.log(a == b);   // true 两个变量的值是一样的，中间会有一次隐形的数据类型转换的过程
	console.log(typeof a); // string
	console.log(typeof b); // number
	console.log(a === b);  // false 三个等号表示 即判断类型，又判断数值，不会进行数据类型转换，常用

</script>
```

```javascript
// 数据类型转换
<script>
	var s = "1";
	console.log(s + 1)  // 11 +左右两端只要出现字符串，就是字符串的拼接
	s=parseInt(s);      // 强制把字符串s转化成十进制的数字，重点掌握
	console.log(s + 1)  // 结果是2
    
    var a = +"10";      // 当字符串前面出现加号或者减号，可以将字符串转化成数字
	var b = -"10";
    console.log(typeof a); // unmber
	console.log(typeof b); // number

	var s = "abc";      // 字符串
	ss = parseInt(s，16); // 把字符串转换成16进制数字，不支持中文转换数字
	console.log(ss);    // 2748
	ss=2748;
	console.log(ss.toString(16)) // 把16进制数字转换成字符串，逆向的时候能遇见

// number -> string : 数字.tostring() 或者 数字 + "",
	var a = 100;
	var b = a.toString(); //重点掌握
	var c = a + "";
	console.log(b); 
	console.log(c);
// 输出的都是String类型，数值都是100
// tostring(2) 小括号内容的数字代表转换成2、10、16进制转化
</script>
```

### 19.3 声明变量关键字

记住结论：见到 `var`  `let`  `const` 都是在声明变量

下面的案例中，先使用了变量，后面才声明了变量，在`JS`中是不会报错的。浏览器输出为 `undefined`未定义。原理是，在`JS`编译的过程中，审查代码发现，使用了未声明的变量，编译器会自动声明一个空变量 `var name`这种现象叫做变量提升。

```javascript
function fn(){
    console.log(name);
    var name = "大马猴";
}
fn() //undefined
```

在新版本的`JS`中，`ES6`以后对变量的提升进行了修复，使用 `let `声明的变量，不会被变量提升，运行程序就会报错

```javascript
function fn(){
    console.log(name);
    let name = "大马猴";
}
fn() // Cannot access 'name' before initialization
```

所谓常量，就是不希望后续程序去修改这个变量的值。通常情况下，变量名通过大写来说明这个变量是常量不要修改，但是依然是可以修改的。这只是一个君子协议，总会有人不遵守。比如：`BIRTH_DAY = 1998;`后来，使用 `const` 关键字声明的常量，是不允许修改的，如果程序修改了，则会报错。

```javascript
var BIRTH_DAY = 2000;
var BIRTH_DAY = 1998;
console.log(BIRTH_DAY) // 1998

const BIRTH_DAY = 2000;
var BIRTH_DAY = 1998;
console.log(BIRTH_DAY) // Uncaught SyntaxError: Identifier 'BIRTH_DAY' has already been declared 变量已被声明

// let 和 const 在同一个作用域中是不能重复声明的 
```

所以，以后见到 var / let / const 表示都是在声明变量



### 19.4 关于 + + 

`++`在前先运算，在赋值；`++`在后先赋值，后运算。如果没有`=`存在，也就是不在赋值操作中出现，无论是在前还是在后，都是对自身自增1。

```javascript
<scrlpt>
	var a = 10;
	a ++; //表示自己增加1 => a = a+1
	console.log(a); // 11

	++ a; //也是表示自己增加1 => a=a+1
	console.log(a); // 12

// 注意，++ 不论是在变量的前面还是在后面，它自己一定是增加1的
// a = 1
// b = a++ 执行逻辑：先复制，b=a=1，然后a自增运算，a=2
// b = ++ā 执行逻辑：a的值先自增1，此时a=2，然后在将a自增后的值赋值给b,此时b=2
// = 永远都是最后执行的
	var a = 1;
	var b = a++;// 原来a的值赋值纷b.a日增1
	console.log(b);//1
	console.log(a);//2

	var c = ++a;
	console.log(c); //2
	console.log(a); //2

// 以下代码，正常程序中是不会出现的
  a = a++; // a++的结局是1  a在这个过程中会自增1
  console.log(a); //a=1
  a = ++a; // ++a 的结局是2
  console.log(a); //2

  //a++这个表达式的值是a
  //++a这个表达式的值是a+1
</script>
```

> 在理解这个问题的时候，还要理解变量的作用域，全局变量和局部变量。当函数内没有局部变量时，就会向外找，最终找到全局变量。

### 19.5 字符串操作

```javascript
s.split()	字符串切割

s = s.replace("周杰伦","王安全") 字符串的替换，替换一个
s = s.replaceALL("周杰伦","王安全") 字符串的全部替换，只要出现就替换

s.substr(start，len)	字符串截取，从start开始切，切len个字符
s.substring(start,end) 字符串截取，从start开始切割到end结束

s.length 宁符串长度

// FromCharCode和charcodeAt 必须记住，逆向中常用
s.charAt(i) 第i索引位置的字符
s.charCodeAt(i) 第i索引位置的字符的ASCII码对应的编号，汉字则对应的是Unicode
String.fromCharCode(20320) 把对应编码的编号还原成字符或者汉字, 输出 你

s.index0f('xxx') 返回xxx开始位置的索引，如果没有xxx，则返回-1，顺序是由左往右查找
s.lastIndex0f("xxx") 返回xxx的最后一次出现的索引位置，如果没有xxx。则返回-1

s.includes("xxx") 判断xxx是否出现作s中，返回true或者false

s.toUppercase() 转换成大写字母
s.toLowercase() 转换成小写字母

s.startsWith("xxx" ) 判断是杏以xxx开头，返回true或者false
s.endsWith("xxx") 判断是否以xxx结尾，返回true或者false
```

> 关于`null`和`undefined`，这两个都是表示空，`null`表示什么都没有，`undefined`表示空变量，有变量但是没有值。转化成`boolean`的话都是`false`。

### 19.6  条件分支

#### 19.6.1 if语句

除了`html`以外，几乎所有的编程语言都有条件判断的功能。比如，`python`用`if`语句来做条件判断，那么`javscript`也是一样，使用`if`来做条件判断。

```javascript
//语法
if(条件1){
    代码块1
}
// 解读:当条件1成立时，执行代码块1中的内容，如果条件1不成立，则不执行该代码块1中的内容

if (条件)
	代码快1
//解读：如果代码块1中的内容只有一行，则可以省略代码快外面的大括号（注意：条件后面是没有冒号的）


if(条件1){
    代码块1
} else {
    代码块2
}
// 解读:当条件1成立时，执行代码块1中的内容，如果条件1不成立，则执行代码块2中的内容


if(条件1){
    代码块1
}else if(条件2){
    代码块2
}else if(条件3){
    代码块3
}...{
    代码块n
}else {
    代码块else
}
// 解读:当条件1成立时，执行代码块1中的内容，如果条件2成立。则执行代码块2中的内容...如果都不成立，则执行else中的内容.
```

#### 19.6.2 switch语句

该语句是`Python`中不存在的，但是在`Java`和`C`，以及`JavaScript`中依然是会使用的。

```javascript
switch(变量){
	  case 值1:
		    代码块1
		    break //可选
	  case 值2:
		    代码块2
		    break 
	  case 值3:
		    代码块3
		    break 
	  default:// 可选
		    default代码块
}
/*
解读:
1. 代码执行时，switch会判断变量的值是否完全等于（===）case1 后面的 值1;
2. 如果是true，则执行 case1 下面的 代码块1 以及 代码块1中的 break;
3. 如果是false，则继续向后判断;
4. 如果都没冇和变量相等的值，则执行 default代码块;

注意：
每一个 case 中都可以使用break，也可以不使用break。如果不写break，那么就会形成case穿透现象.
例如：变量的值如果和case1相等，并且case1中没有写break，则在执行的时候，会执行完case1中的代码，然后会自动穿透到case2中去执行里面的代码，而不会判断case2的值是否与变量相等。直到遇到break停止。
*/
```

`switch`语句小案例

```javascript
let daynumber = parseInt(prompt("请输入星期数字1-7："))
switch(daynumber){
    case 1:
        console.log("星期一");
        break;
    case 2:
        console.log("星期二");
        break;
    case 3:
        console.log("星期三");
        break;
    case 4:
        console.log("星期四");
        break;
    case 5:
        console.log("星期五");
        break;
    case 6:
        console.log("星期六");
        break;
    case 7:
        console.log("星期日");
        break;
}

//穿透案例
let num = 2;
switch(num){
    case 2:
        console.log("数字2")
    case 3:
        console.log("数字3")
    default:
        console.log("其他")
}
// 输出：数字2 数字3 其他
```



### 19.7   循环语句

#### 19.7.1 while循环

```javascript
// 语法
while(条件){
		循环体 -> 里面可以有break和continue等关键字
}

// 示例
let num = 1;
while(num < 10){
    console.log(num)
    num++;
}
/*
判断条件是否为真，如果真，则执行循环体，执行完循环体，会再次判断条件，直到判断条件不成立，退出循环;
循环体中也可以使用break和continue等关键字来控制循环的走问
*/


```

#### 19.7.2 do-while循环

与`while`循环的区别是无论条件成立与否，循环体至少执行一次。

```javascript
// 语法
do{
	循环体
}while(条件);

//示例
let num = 10;
do{
    console.log("中午吃什么呢？");
    num--;
}while(num > 1);

/*
解读:
先执行循环体，然后判断条件是否成立，如果成立，继续执行循环体。直到条件不成立，退出循环。
注意，由于do..while是先执行的循环体。所以，不论条件如何，至少执行一次循环体。
*/
```

#### 19.7.3 for循环

`for`循环与`python`中的循环完全不一样，注意区别。

```javascript
// 语法
for(表达式1; 表达式2; 表达式3){
	循环体
}
/* 解读：
首先for循环执行表达式1，然后判断表达式2的结果是否为真，如果为真，则执行循环体，然后再执行表达式3；
再然后，判断表达式2执行的结果是否为真，如果是真，执行循环体，再执行表达式3
……
直到，表达式2的执行结果为假，跳出循环。
*/


// 示例
for(var a=0 ; a<10 ; a++ ){
	  console.log(a); // 遇到比较复杂的循环就找for后面的分号
}
// 解读：先执行a=0，然后执行a<10,条件成立，执行循环体，在控制台输出a=0,然后执行a++,此时a=1,再执行a<10,条件依然成立，执行循环体……直到，a=10时，a<10不成立，退出循环


// 简单的嵌套
for(var a=0; a<10; a++){
	for(var b=0; b<10; b++){
		console.log("我爱你" + "," + a +"，"+ b)
  }
}
```

for循环的另外一种写法

```javascript
// 第二种写法
var a = [11,22,33,44,55,66]
for(let i in a){
    console.log(i + "_" + a[i])    
}
```

这样写法非常类似`python`中的`for`循环，但是需要注意，这里的`i`拿到的仅仅是数组a的索引信息，并非数组中的元素本身。如果需要数据则是`a[i]`

### 19.8  数组和对象（重点）

#### 19.8.1 数组

在`javascript`中创建数组非常简单，直接使用`[]`即可。也可以使用正规的方法`new Array()`方法创建数组对象，不过效果是一样的。数组完全可以理解为`python`中的列表。

```javascript
// 空数组
var arr = [];
var arr = new Array();

// 有元素的数组
var arr = [11, 22, 33, 44, 55, 66]
var arr = new Array(11, 22, 33, 44, 55, 66)
```

数组的常用操作

```javascript
arr.length; // 数组长度
arr.push(data); // 在数组尾部添加数据
arr.pop() // 删除数据，从数组后面删除（右向左），并返回被删除的内容，通过变量可以接收该内容
arr.shift() // 删除数据，从前面删除（左向右），并返回被删除的内容，通过变量可以接收该内容
arr.unshift(); // 在数组之前增加数据
arr.flat(depth); // 将嵌套的数组处理成一个数组，depth指定要提取嵌套数组的深度，默认为1
arr.slice(1,3); // 数组切片，开始索引，结束所有（不包含结束所有）
arr.join("连接符"); // 使用连接符将arr中的每一项拼接起来。和python中的"".join()同

// 遍历数组中的每一项元素。每一个元素分别去调用function函数，会白动的将数据传递给函数的第一个参
arr.forEach(function(e, i, a){ 
    //e数组元素，i元素索引，a数组本身，i 和 a 可选
	console.log(i +""+ e);
});

// map会拿arr中每一项数据去执行里面的函数，会收集每一项计算之后的结果
var r = arr.map(function(e, t){
    // e是元素， t是索引
    console.log(e, t);
    return e + t;
});
console.log(r);
```

#### 19.8.2 对象`object`

在`Javascript`中创建对象非常容易，和`Python`中的字典几乎一样

```javascript
// 创建对象，和Python中字典的区别就是key,既可以用引号包括，也可以省略掉引号。
var wf = {
	name:"汪峰",
	age:18,
	wife:{
		name:"章子怡",
		age:22,
         news:"没新闻"
	}
};

// 提取数据方式一:像字典一样
console.log(wf["wife"]["news"]);

// 提取数据方式二：既然是对象，那就可以用点来调用方法
console.log(wf.wife.news); // 提取wf的wife的news的值

// 所以这个 . 跟[] 在对象中是等同的
console.log(wf['wife'].name);
console.log(wf.wife['name']);

// 给对象设置属性
wf["child"] = [] 
wf.child = [] 

// 把对象转换成json字符串
var p={
	name: "alex",
	age: 18,
    hobby:"洗脚"
};
s = JSON.stringify(p) // 注意JSON是大写的

// 把json字符串转成对象
s = '{name:"alex", age:18, hobby:"洗脚"}'
var p = JSON.parse(s)


// 关于对象的补充
var wf = {
  name:"汪峰",
  age:199,
  songs:["冬天里","夏天里","秋天里"]
  // 除了属性，还可以给对象增加功能（函数）
  chi:function(){
    console.log("汪峰喜欢吃饭")；
  }
}
// 运行这个功能，直接对象点属性的功能
console.log(wf.chi())
// 指定对象自己的属性，即当前这个对象关键字this,相当于Python中的self
var wf = {
  name:"章子怡",
  age:199,
  songs:["冬天里","夏天里","秋天里"],
  // 除了属性，还可以给对象增加功能（函数）
  chi:function(){
    console.log(this.name + "喜欢吃饭")；
    this.he("北冰洋")；
  }
	he:function(yinliao){
    console.log(this.name + "在喝" + yinliao);
  }
}
// 也就是说 函数在对象内也是可以相互调用的。
```



### 19.9 函数（重点）

在`JavaScript`中声明函数和`Python`差不多，也要有一个关键字在前面。`Python`中是`def`，而在`JavaScript`中是`function`。只不过在`JavaScript`中没有那么死板，关键字后面不一定要有函数名才可以。所以，`JavaScript`函数的核心是：函数的运行不是依赖函数名，而是依赖于函数的内存地址。

```javascript
// 语法
// 声明函数
function 函数名(形参1，形参2，形参3....){
    函数体
	return 返回值
}

// 调用函数
函数名(实参1，实参2，实参3....)
// 除了写法换了一丢丢，其他的东西和python完全一致
```

先来看一个简单的案例

```javascript
function an(a,b){
  return a + b
}
ret = an(1,2)
console.log(ret); // 3
```

但为什么在网页上看到的函数非常复杂呢？其实，`JavaScript`没有一个非常严格的语法规则，只要能够形成`xxx()`的形式，并且`xxx`是一个函数的话就可以执行。例如：

```javascript
// an虽然是var声明的，但是它的指向是一个函数，那就可以执行
var an = function(a, b){
    return a + b 
}
an(1, 2)	

// $这个符号没有被JS使用，就可以用来做变量名
var $ = function(a, b){}
$(1，2) 

// 这个也很过分，这个东东要拆开来看，第一个括号里而放的就是一个函数啊，所以依然可以执行
(function(a, b){
    return a + b
})(1, 2)

c = (function(){
    var m = {
        name:'alex',
        age:'18',
        xijiao: function(a){
            console.log(a+"来帮我洗脚");
        }
    }
    return m
})
```

函数的返回值`return`在逆向中一定会遇到，例如下面的案例：

在`JS`中可以写多个返回值，但是最终只会返回最后一个的值。前面的如果是表达式，会执行表达式，但是表达式执行的结果如果没有被最后一个变量使用，就会被丢弃。最终直接返回最后一个表达式的结果。

也就是说，会把`return`后面的每一个表达式都执行一次，但是最终真正返回值其实是最后那个`"哈哈"`，这也就是 `JavaScript` 的逗号操作符特性——它会按顺序执行表达式，并返回最后一个值。

```javascript
var an = function(){
	  return console.log("我爱你"), console.log("爱你妹"),"哈哈”;
}

var an = function(){
    return "李慕婉","刘梅","南宫婉"; // 逗号操作符
};
console.log(an()) // 输出：南宫婉
```

> 注意：函数中的参数，是指局部变量，在一个函数体中如果使用一个变量的时候，首先，先在自己的作用域中查找，如果能找到就使用，如果找不到，则向外层寻找，如果找到了就使用，如果找不到，继续向外找。直到全局都没有，则报错。



**关于函数中的`Arguments`对象**

`arguments`是一个对应于传递给函数的参数的类数组对象。

```javascript
function func1(a, b, c) {
  console.log(arguments[0]);
  // Expected output: 1

  console.log(arguments[1]);
  // Expected output: 2

  console.log(arguments[2]);
  // Expected output: 3
}

func1(1, 2, 3);
```

`arguments`对象是所有（非箭头）函数中都可用的**局部变量**。你可以使用`arguments`对象在函数中引用函数的参数。此对象包含传递给函数的每个参数，第一个参数在索引 0 处。例如，如果一个函数传递了三个参数，你可以以如下方式引用他们：

```javascript
arguments[0];
arguments[1];
arguments[2];
```

通过索引赋值

```javascript
arguments[1] = "new value";
```

`arguments`对象不是一个 [`Array`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array) 。它类似于`Array`，但除了 length 属性和索引元素之外没有任何`Array`属性。例如，它没有 [pop](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array/pop) 方法。但是它可以被转换为一个真正的`Array`：

```javascript
var args = Array.prototype.slice.call(arguments);
var args = [].slice.call(arguments);

// ES2015
const args = Array.from(arguments);
const args = [...arguments];
```

如果调用的参数多于正式声明接受的参数，则可以使用`arguments`对象。这种技术对于可以传递可变数量的参数的函数很有用。使用 [`arguments.length`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Functions/arguments/length)来确定传递给函数参数的个数，然后使用`arguments`对象来处理每个参数。要确定函数[签名](https://developer.mozilla.org/zh-CN/docs/Glossary/Signature/Function)中（输入）参数的数量，请使用`Function.length`属性。



### 19.10 闭包函数（重要）

由变量的声明位置是否处于函数体内引出**作用域**的概念。函数体外声明的变量`var`会被放入`window`全局作用域中；函数体外声明的变量`let`不会进入全局作用域，而是进入块级作用域，也就是函数体内，称为局部作用域。而在函数体内声明的变量想在外界使用，就会通过`window`对象进行植入，例如`window.var = var`，那么在外界就可以直接使用`var`变量，由此，引出闭包的概念。

引出闭包函数的原因是，网站的前端代码不可能是一个人完成的，涉及到团队协作，就有很多人去参与。例如：一个功能需要两个人写不同的加密算法，一个是`MD5`，一个是`AES`，两个人写的函数如果都一样，会怎么样？

员工1号写的加密函数

```javascript
var key = "skskssksksks";
var jiami = function(data){
  console.log("自己的加密算法：" + data);
  console.log(key);
  return "结果";
}
jiami()
```

员工2号写的加密函数

```javascript
var key = "abababababab";
var jiami = function(data){
  console.log("自己的加密算法：" + data);
  console.log(key);
  return "结果";
}
jiami()
```

以上这样写，员工在自己本地调用运行的时候没有问题，但是如果第三个人，通过引用的方式，把两个人的代码引入第三个文件中，就会出现冲突。两个函数都是var全局变量，在引入的文件中都会进入window中。后引用的会把先引用的覆盖掉

```javascript
<script>
<script src="员工1号.js"></script>
<script src="员工2号.js"></script>

// 两个key都是全局变量，名字冲突，打印key的时候它调用的是谁?不好拿捏
jiami("我爱黎明");
</script>
```

为了解决上述出现的问题：怎样才能让自己的变量不被别人修改掉呢？使用 -- 局部变量

```javascript
(function(){
	// 在函数内部声明的变量是一个局部变量
	var jiami = function(data){
  }
})();
```

但问题是，外界想使用函数内部的变量，该如何使用，一种方式是`window`，另一种方式是`return`，但是需要一个变量接收`return`的内容，所以很少使用`return`这种方式。更多的是使用`window`传递参数的方式，形成闭包函数。

```javascript
(function(w){// 步骤1：创建立即执行函数，传入 window 并改名为 w
    // 步骤2：定义内部加密函数（此时外部无法访问）
	  var jiami = function(data){
        console.log("自己的加密算法：" + data);
  }
  // 步骤3：将内部函数挂载到 window 对象
  w.jiami = jiami;
})(window); // 步骤4：传入全局的 window 对象

/*
生活场景类比：工厂保密车间
假设你要开发一个加密工具库，但不想让他人随意修改内部代码：
搭建保密车间 → (function(w){ ... })
这个立即执行函数就像工厂的独立车间，内部操作对外部不可见
车间入口传递工具 → (window)
把车间需要的工具（这里指 window 对象）从窗口递进去，在车间内化名为 w 使用
车间内生产加密机 → var jiami = function(){...}
在车间内部制造了一台加密机器（函数），但外界不知道它的存在
对外开一个窗口 → w.jiami = jiami
只在车间的对外窗口（w 即传入的 window）挂出加密机的使用接口
*/
```

闭包函数在现实中的`JavaScript`代码中是这样出现的

```javascript
(function(){// 立即执行函数封装加密模块
    var key = "aes的key"; // 内部密钥，外部不可见
    // 内部base64编码方法（私有）
    var b64 = function(data){
        console.log("进行自定义base64编码");
        return data; // 示例：实际可用自定义算法替换
    };
    
    // 对外暴露的AES加密方法
    window.aes = function(data){
        var encoded = b64(data); // 内部调用私有b64方法
        console.log("开始AES加密流程");
        console.log("使用密钥:", key);
        return "加密结果[" + encoded + "]"; // 示例返回值
    };
})();

// 外部调用
let result = window.aes("XXXXX"); // 调用暴露的aes方法
console.log(result); // 输出：加密结果[]
```

总结，通过`window`全局作用域、参数对象、return三种方式在外界调用局部作用域中的变量内容。



