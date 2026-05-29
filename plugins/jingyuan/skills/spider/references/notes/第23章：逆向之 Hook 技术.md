## 第23章：逆向之 Hook 技术

---

### 23.1 技术简介

`Hook` 是一种钩子技术，在系统没有调用函数之前，钩子程序就先得到控制权，这时钩子函数既可以加工处理（改变）该函数的执行行为，也可以强制结束消息的传递。简单来说，修改原有的 `JS` 代码就是 `Hook`。

客户端拥有`JS`的最高解释权，可以决定在任何时候注入`JS`，而服务器无法阻止或干预。服务端只能通过检测和混淆的手段使`Hook`难度加大，但是无法直接阻止。除了上面的必要条件之外，还有就是`JS`是一种弱类型语言，同一个变量可以多次定义、根据需要进行不同的赋值，而这种情况如果在其他强类型语言中则可能会报错，导致代码无法执行。`JS` 的这种特性，为我们`Hook`代码提供了便利。

>  **注意：**`JS` 变量是有作用域的，只有当被`Hook`的函数在同一个作用域的时候，才能 `Hook` 成功。

当我们找到接口之后，发现数据是加密的，那我们肯定是需要想办法去找到数据加密的位置，`dom`断点和`xhr`断点都是可以用来定位加密的位置，但是定位的距离可能会有远有近，我们需要跟很多的栈，相对是比较麻烦的，那么`Hook`技术同样是用来定位数据加密的位置，可以帮助我们可以更快的去找到加密位置，`Hook`步骤如下：

- 寻找需要 `Hook` 的内容（请求头加密、请求参数加密、）
- 编写 `Hook` 逻辑
- 调试代码

```javascript
// Hook的逻辑
var _变量 = 被Hook函数;
被Hook的函数 = function(参数????){
    debugger; // 为了找在何处调用的`被`Hook`函数`

    return _变量(参数?????);
}
```

一般情况下 `hook`的逻辑是使用现成的代码，这里收录了常见的`hook`方式：

https://www.cnblogs.com/xiaoweigege/p/14954648.html



### 23.2 stringify or parse

站点：https://fanyi.youdao.com/index.html#

我们知道在`JavaScript`中 `JSON.stringify()` 方法用于将 `JavaScript` 对象或值转换为 `JSON` 字符串，`JSON.parse() `方法用于将一个 `JSON `字符串转换为`JavaScript `对象，某些站点在向` web `服务器传输用户名密码时，会用到这两个方法

```
所有的加密都要基于数字...
把字符串处理成数字 -> charCodeAt()
js中所有要加密的东西.都需要转化成字符串才可以
加密逻辑 对象 -> 字符串 -> 加密 -> 密文 -> 传输
服务器返回的密文(各种数字) -> 字节 -> 解密 -> 字符串 -> 对象 -> 正常用
```

```javascript
(function() {
    var _parse = JSON.parse;
    JSON.parse = function(ps) {
        console.log("Hook JSON.parse ——> ", ps);
        debugger;
        return _parse(ps);  // 不改变原有的执行逻辑 
    }
})();
```

首先定义了一个变量` stringify `保留原始` JSON.stringify `方法，然后重写` JSON.stringify `方法，遇到` JSON.stringify `方法就会执行 `debugger `语句，会立即断下，最后将接收到的参数返回给原始的` JSON.stringify `方法进行处理，确保数据正常传输。

### 23.3 cookie

webapi地址：https://developer.mozilla.org/zh-CN/docs/Web/API

`Object.defineProperty `为对象的属性赋值，替换对象属性

基本语法：`Object.defineProperty(obj, prop, descriptor)`，它的作用就是直接在一个对象上定义一个新属性，或者修改一个对象的现有属性，接收的三个参数含义如下：

- `obj`：需要定义属性的当前对象；
- `prop`：当前需要定义的属性名；

```javascript
user = {
    age: '123'
}
aa = user.age
Object.defineProperty(user, "age", {
    get: function () {
        return aa
    },

    set: function (newVal) {
        console.log("这个人来设置值了！！");
        aa = newVal
    }
})
console.log(user.age)
user.age = '23342'
console.log(user.age)
```

`Hook` cookie 示例

- 目标网址:  http://q.10jqka.com.cn/
- `cookie` 钩子用于定位 `cookie` 中关键参数生成位置，以下代码演示了当 `cookie` 中匹配到了 `v`， 则插入断点：

```javascript
(function () {
    cookieTemp = document.cookie;
    Object.defineProperty(document, 'cookie', {
        set: function (val) {
            if (val.indexOf('v') != -1) {
                debugger;
            }
            console.log('Hook捕获到cookie设置->', val);
            cookieTemp = val;
        },
        get: function () {
            return cookieTemp;
        },
    });
})();
```

> 注：正常`Hook` cookie`操作的时候需要清除下`cookie



### 23.4  xhr

案例地址：https://www.qimai.cn
定义了一个变量 `open` 保留原始 `XMLHttpRequest.open` 方法，然后重写 `XMLHttpRequest.open` 方法，判断如果 `rnd` 字符串值在 `URL` 里首次出现的位置不为 -1，即`URL` 里包含 `analysis`字符串，则执行 `debugger` 语句，会立即断下。

```javascript
// 如果是正数 表示存在里面
// 如果是-1 表示不在里面

(function () {
    var _open = window.XMLHttpRequest.prototype.open;
    window.XMLHttpRequest.prototype.open = function (method, url, async) {
        if (url.indexOf("analysis") != -1) {
            debugger;
        }
        return _open.apply(this, arguments);
    };
})();
```



### 23.5  debugger

通用方法

```javascript
1. 右键,never pause here
2. 在setInterval执行之前. 置空
下条件断点:
setInterval = function(){}; false;
```

第一种常见的无限`debugger`

```javascript
setInterval(function(){
    debugger;
}, 1000);

// 解决办法
1. 右键,never pause here
2. 在setInterval执行之前. 置空
下条件断点:
setInterval = function(){}; false;
```

第二种常见的无限`debugger`

```javascript
//利用Function构建一个新的函数.
setInterval(function(){
    Function("debugger")();
}, 1000);

//解决方案:可以通过Hook Function的方案来解决
var _Function = Function;
Function = function(){
    let arr = [];
    // 替换掉所有的参数中的debugger;
    for(var i = 0 ; i < arguments.length; i++){
        let arg = arguments[i];
        arg = arg.replaceAll("debugger", "");
        arr.push(arg);
    }
    // return _Function(arr); // 错误的
    return _Function.apply(this, arr); // 走回正常逻辑
}
```

第三种常见的无限`debugger`

```javascript
setInterval(function(){
    // 函数.__proto__.constructor
    // 原型对象上的constructor()
    (function(){}).constructor("debugger")();
}, 1000);

// 解决方法
var _Function_prototype_constructor = Function.prototype.constructor;
Function.prototype.constructor = function(){
    let arr = [];
    // 替换掉所有的参数中的debugger;
    for(var i = 0 ; i < arguments.length; i++){
        let arg = arguments[i];
        arg = arg.replaceAll("debugger", "");
        arr.push(arg);
    }
    // return _Function(arr); // 错误的
    return _Function_prototype_constructor.apply(this, arr); // 走回正常逻辑
}
```

`Hook` 某个属性

```javascript
(function(){
    var v;
    Object.defineProperty(document, "cookie", {
        set: function(val) {
            console.log("有人来存cookie了");
            v = val;
            if(val.indexOf("uuid")){debugger;}

            return val;
        },
        get() {
            console.log("有人提取cookie了");
            debugger;
            return v;
        }
    });
})();

```

剩下的咱就不再赘述了.  在逆向时, 常用的主要有: `Hook eval` 、`Hook Function`  、`Hook setInterval`,  `Hook setTimeout`, `Hook cookie`

### 23.6 案例

空气质量监测分析平台：https://www.aqistudy.cn/

网站的特点分析如下

```
1.网站特点，由两个大的iframe组成
    1.1 整个网站是一个iframe
    1.2 除去顶部和左侧的菜单栏，显示区域也是一个iframe
    1.3 通过左侧的菜单切换，在iframe中显示不同的内容

2. 网站禁用F12功能，点击F12，网站会弹窗提示“检测到非法调试，F12被管理员禁用”

3. 通过浏览器设置-->打开开发者工具进入调试页面，网站则直接显示 无限debugger
    3.1 设置 never pause here 后释放断点，页面疯狂显示“检测到非法调试, 请关闭调试终端后刷新本页面重试!Welcome for People, Not Welcome for Machine!”

4. 通过观察发现，这个无线debugger不是写在 JavaScript 文件中的，因为每次执行都会出现 vm ，应该是通过 eval函数执行的
    4.1 所以可以选择Hook这个eval, 植入我们自己的代码，过掉这个无线debugger
    4.2 一共有两次eval的无线debugger代码，一个是在HTML代码中，一个是在JavaScript文件中
    4.3 选可以选择使用Charles，也可以使用浏览器的Override

5. 过了反调试，这个网站的加密和解密很简单
```

按下`F12`出现弹窗提示，检测非法调试

![image-20250612053816981](../media/22-1)

通过浏览器右上角三个点 --> 更多工具 --> 开发者工具进入调试页面，出现`无限debugger`，通过调用栈溯源发现不是一个`xxx.js`文件，而是`VM……`，所以猜测被执行的那段代码大概率是使用了`eval`或者`Function()`执行的`JavaScript`代码

![image-20250612054150771](../media/22-2)

![image-20250612060808725](../media/22-6)

如果在`debugger`这一行打上不再此处停留的断点，页面会疯狂喷出提示内容，所以通过常规的手段是没有办法调试的

![image-20250612054506659](../media/22-3)

在前面分析的时候已经知道了，这个老网站并非一个完整的网页，而是通过很多个`iframe`嵌套出来的网站，所以我们就可以用哪个页面的时候，就专门看哪个页面，找到`iframe`对应的哪个`src`，在浏览器地址栏中跟域名做个拼接`https://www.aqistudy.cn/html/city_realtime.php?v=2.3`打开即可，这样就不用再处理最外面那层`iframe`的反调试内容。

![image-20250612055350725](../media/22-4)

目标页面已经找到了，要提取里面的数据，必然要通抓包工具看请求是如何发送，但是有反调试，没办法使用浏览器的调试工具。需要借助浏览器之外的抓包工具`charles`

![image-20250612060226497](../media/22-5)

通过观察发现，请求的参数是加密的，返回的响应内容也是加密的，所以我们还是得调试，才能找到加密与解密的位置。就必须要过掉反调试的内容。上面也分析了，可能是通过`eval`或者`Fcuntion()`执行的代码，所以，我们可以去`Hook`执行代码的`eval`或者`Function()`。`ctrl + shift + r`刷新浏览器页面后，在`Charles`中可以看到网站的页面源代码，并且可以找到第一个被引入的`javascript`文件。此时，我们就可以在这个文件中植入我们的代码。

![image-20250612061740384](../media/22-7)

找到这个`jQuery.min.js?v=1.3`文件，将代码全选后复制出去

![image-20250612061958515](../media/22-8)

回到我们的项目文件夹中新建一个`Hook文件.js`文件，把复制的完整代码粘贴进去。

![image-20250612061926163](../media/22-9)

接下来，在代码的最顶部就可以植入我们的代码了。代码的作用是：`eval` 执行后会断在这里，因为执行的是字符串，所以可以通过`arguments[0]`查看到具体的执行内容

![image-20250612063120636](../media/22-10)

接下来我们使用`Charles`进行本地替换，找到要被替换的文件，鼠标右键点击后在弹出的菜单中选择`map Local`，在弹窗`Edit Mapping`中点击`choose`，选择我们上面编辑好的`Hook文件.js`进行替换，点击确定即可。替换以后，在浏览器`ctrl + shift + r`刷新网站。

![image-20250612063307133](../media/22-11)

![image-20250612063556379](../media/22-12)

此时，程序就断在了我们写的代码处。通过调用栈我们可以知道哪里调用这个`eval`，并且也可以通过`arguments[0]`传递的参数知道里面执行的代码到底是什么。当前的这段代码是`Base64`相关的，跟`debugger`无关，可以放掉继续执行。

![image-20250612064307773](../media/22-13)

释放断点执行三次之后，搞事情的`debugger`出来了，通过调用栈可以定位到具体的代码，并且上面有注释表明。另外，通过`arguments[0]`可以观察到了具体执行的代码是什么。此时，通过观察还发现，这个`debugger`是写在了`jQuery.min.js`源文件里面的。这样的话我们就可以直接到替换文件里面把代码干掉即可。

![image-20250612065059042](../media/22-14)

`ctrl + shift + -`快速折叠代码，结果一目了然，5个`eval`，其中有两个是搞事情的。留着它干啥？？直接干掉，同时也要注意，将我们自己的`Hook`代码也要注释掉，不然会有影响。

![image-20250612065539859](../media/22-15)

回到网站刷新，然后……又出来`debugger`了……但这并不是之前的`eval`，而是潜伏在页面源代码中的`eval`，狗东西……

![image-20250612070419408](../media/22-16)

可以选择在这一行下断点处理它，然后一刷新页面发现，艹……咋变成了900行？？原来是940行啊……`fuck`!!是因为这个网站会植入很多空行，改变你断点的位置。

![image-20250612070817808](../media/22-17)

这样的话，就没道理可以讲了，直接`Hook`，干掉它！！

![image-20250612070959238](../media/22-18)

重复上述`Hook`的逻辑，本地替换页面源代码的内容，再次下断点，你会发现不会出现随机的空行了，把这段代码干掉后，刷新网站，就再也没有干扰的内容了。

![image-20250612071451596](../media/22-19)

到此位置，可以正常调试内容，反调试的内容就全部过掉了

![image-20250612072035336](../media/22-20)

接下来就是找加密、解密的入口，这个网站的调用栈非常少，一步步找就好了，点进去

![image-20250612084551650](../media/22-21)

参数`m37Yy4M7B`是`GETDATA`，参数`oDKCOdXIxq`是城市`city: "成都"`，经过`pvkWB5TRrM9kT5`处理之后变量`pUpOMOU`变成了密文，下一步就如这个函数里面

![image-20250612084835465](../media/22-22)

变量`appId`、`clienttype`是固定的，`timestamp`获取的是时间戳，`method`和`obj`是传进来的参数，`obj`经过处理后变成字典，再和这些参数拼接成字符串，经过`md5`计算，最后把整个`param`对象处理成字典进行加密，在经过`Base64`处理

![image-20250612085414710](../media/22-23)

剩下的就是抠代码了，因为这个网站所有的加密和解密逻辑都是通过`eval`执行的，本身就没有多少代码，所以直接全抠出来，直接发请求调用即可。

做个小小的总结，这个网站的关键点就是前面的反调试，使用浏览器的本地退换，或者使用抓包工具做替换都是可以的，逻辑相通。结局了反调试的问题，找到加密入口就非常容易了。另外就是需要注意一点，当使用`charles`调试后，发请求容易出现证书失效的报错，只要把`charles`关掉就可以了。如果还是不行，就在请求中设置关掉验证`verify = False`。



