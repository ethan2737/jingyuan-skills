## 第28章：逆向之`webpack`技术

---

### 28.1 `webpack`定义

`webpack`是一个模块打包工具，它可以将多个模块打包成一个或多个文件，处理各种类型的模块（如`javascript`、`css`、图片等），并对这些模块进行优化和转换。`webpack`的核心逻辑是通过分析模块之间的依赖关系，将所有模块打包成一个文件或多个文件。通过`loader(加载器)`和`plugins(插件)`对资源进行处理，打包成符合生产环境部署的前端资源。所有的资源都是通过`javaScript`渲染出来的。

### 28.2 `webpack`基本结构

```javascript
!function(e){ //自运行函数
    // 函数aa 叫做加载器
    function aa(t){
        return e[t].call(); // 参数取下标0，就是列表中的函数，被调用，标志代码！！
    }
    aa(0); // 调用的时候数组通过下标，对象通过键值对
}(
    // 传递的参数 叫做模块/插件 
    // 模块的形式：数组、对象
    [function(){//参数是一个函数
    console.log("hello");
}]
)
```



### 28.3 打包步骤

模拟一个小项目，文件夹`Project-webpack`，项目里面有3个文件，分别是：`env.js`、`http.js`、`qiao_enc.js`，详细代码如下：

`env.js`

```javascript
/**
 * 这个js, 专门用来检测环境的. 当前的执行环境是node还是浏览器
 */

function check_env(){
    //  检测window对象, 是否存在.  node里面没有window, 但是浏览器下是有的
    return (typeof window) === "undefined" ? "fuck_env" : "ok_env";
}

// 定制导出的内容
// module.exports = check_env
// 你这边导出的东西. 是那边导入的东西

module.exports = {
    chenv : check_env,
}
```

`http.js`

```javascript
/**
 * 这里面负责发网络请求
 */
// 只要把env模块引入就可以了
var mm = require("./env"); // 1. 模块名和python差不多. 不用后面那个`.js` , 2. 告诉查找路径
var enc = require("./qiao_enc");

function send_req(){
    // 先拿到浏览器环境. 然后再发出去
    // check_env();
    var v = mm.chenv();
    // 把当前环境信息. 进行加密
    var mi = enc.encrypt(v);
    console.log("我发请求了.", mi); // 模拟
}
window.send_req = send_req; // 这样才是真的对外开放
module.exports = send_req

```

`qiao_enc.js`

```javascript
// 内容加密模块

var CryptoJS = require("crypto-js");

function encrypt(s){
    var key = CryptoJS.enc.Utf8.parse("1234567887654321");
    var iv = CryptoJS.enc.Utf8.parse("0000000000000000");
    var cif = CryptoJS.enc.Utf8.parse(s);
    return CryptoJS.AES.encrypt(cif, key, {
        iv: iv,
        mode:CryptoJS.mode.CBC,
        packing: CryptoJS.pad.Pkcs7
    }).toString();
}

module.exports = {
    encrypt
}
```

在项目同级目录中创建`webpack.config.js`文件，通过这个配置文件执行打包操作，我们要学习打包之后的代码逻辑，这里如何具体打包不是我们要关心的内容。这个配置文件中指定了入口和输出文件

```javascript
module.exports = {
    entry: "./qiaofu/http.js",  // 入口
    output:{
        filename: "./qiaofu/js/app.js" // 打包后的文件输出到哪里
    }
}
```

最终经过打包后的代码会输出到一个名为`dist`的文件夹，后面的路径与`"./qiaofu/js/app.js"`是相同的。最终输出的文件`app.js`就是打包后的结果。里面是一个大号的闭包函数。代码数量太多，这里罗列整体框架，以便理解分析即可：

```javascript
(() => {
    var t = {
        482: (t, e, r) => {
            var i = r(191), n = r(106);

            function o() {
                var t = i.chenv(), e = n.encrypt(t);
                console.log("我发请求了.", e)
            }

            window.send_req = o, t.exports = o
        }

    function r(i) {
        var n = e[i];
        if (void 0 !== n) return n.exports;
        var o = e[i] = {exports: {}};
        return t[i].call(o.exports, o, o.exports, r), o.exports
    }
    r.g = function () {
        if ("object" == typeof globalThis) return globalThis;
        try {
            return this || new Function("return this")()
        } catch (t) {
            if ("object" == typeof window) return window
        }
    }(), r(482)
})();
   
```

接下来对以上代码做逐行分析，整体结构是一个立即执行函数表达式`IIFE`。用于创建一个独立的作用域，避免污染全局变量。

模块定义：`t` 对象

```javascript
var t = {
    482: (t, e, r) => {
        var i = r(191), n = r(106);
        function o() {
            var t = i.chenv(), e = n.encrypt(t);
            console.log("我发请求了.", e)
        }
        window.send_req = o, t.exports = o
    }
};
```

`t` 是模块工厂函数集合：

- `t[482]` 是模块 ID 为 `482` 的工厂函数，负责生成模块的导出内容。
- 参数 `(t, e, r)` 是 `Webpack` 的模块接口约定
  - `t`：当前模块对象（`module`），包含`exports`属性
  - `e`：模块的导出对象（`exports`），最终会通过`r(i)`返回
  - `r`：模块加载器（`require`），用于加载其他模块

```javascript
function (module, exports, require) {
    // 模块代码逻辑
}
```

模块加载器：`r` 函数

```javascript
function r(i) {
    var n = e[i];
    if (void 0 !== n) return n.exports;
    var o = e[i] = { exports: {} };
    return t[i].call(o.exports, o, o.exports, r), o.exports
}
```

`r(i)` 是 `Webpack` 的模块加载器，负责按需加载模块`i`，关键逻辑如下

- 缓存检查
  - `e` 是模块缓存对象，键为模块 ID（如 `482`），值为模块对象
  - 如果 `e[i]` 已存在（`n` 不为 `undefined`），直接返回其导出内容 `n.exports`
- 初始化新模块
  - 创建新模块对象 `o = { exports: {} }`，并将其挂载到缓存 `e[i]`
- 执行工厂函数
  - 调用 `t[i]`（模块工厂函数），并通过 `call` 设置上下文
  - `this` 指向 `o.exports`（模块导出对象）
  - 参数依次为 `o`（模块对象）、`o.exports`（导出对象）、`r`（模块加载器）
- 返回导出
  - 返回 `o.exports`，即模块的导出内容



`t[i].call(o.exports, o, o.exports, r)`的具体执行逻辑：

```javascript
调用 t[i].call(...) 的过程：
1. this = o.exports （模块导出对象）
2. 参数 1: o （模块对象）
3. 参数 2: o.exports （导出对象）
4. 参数 3: r （模块加载器）

模块工厂函数内部逻辑：
function (module, exports, require) {
    // module 是 o
    // exports 是 o.exports
    // require 是 r
    exports.default = "Hello"; // 实际上是 o.exports.default = "Hello"
    module.exports = exports; // 确保 module.exports 指向正确
}
```

假设模块 `482` 的工厂函数如下：

```javascript
t[482] = function (module, exports, require) {
    exports.default = "Hello, Webpack!";
    console.log("模块 482 已加载");
};
```

执行 `t[i].call(...)` 的过程

- 创建模块对象

  ```javascript
  var o = { exports: {} };
  ```

- 调用工厂函数

  ```javascript
  t[482].call(o.exports, o, o.exports, r);
  ```

  - `this` 是 `o.exports`（即 `{}`）
  - 参数 `module` 是 `o`（即 `{ exports: {} }`）
  - 参数 `exports` 是 `o.exports`（即 `{}`）
  - 参数 `require` 是 `r`（模块加载器）

- 工厂函数内部逻辑

  ```javascript
  exports.default = "Hello, Webpack!"; // o.exports.default = "Hello..."
  console.log("模块 482 已加载");       // 打印日志
  ```

- 结果

  ```javascript
  o.exports 现在变成 { default: "Hello, Webpack!" }
  最终通过 r(482) 返回这个对象
  ```

全局对象获取：`r.g`

```javascript
r.g = function () {
    if ("object" == typeof globalThis) return globalThis;
    try {
        return this || new Function("return this")()
    } catch (t) {
        if ("object" == typeof window) return window
    }
}(), r(482)
```

- **作用**：确定当前环境的全局对象（`globalThis`、`window` 或 `this`），用于兼容不同运行环境（浏览器、`Node.js` 等）。
- 执行逻辑：
  1. 优先返回 `globalThis`（`ES2020` 标准的全局对象）。
  2. 如果失败，尝试通过 `this` 或 `new Function("return this")()` 获取全局对象。
  3. 最后回退到 `window`（浏览器环境）。
- **最终调用**：`r(482)` 启动模块加载流程，加载入口模块 `482`。

执行流程图示

```tex
1. 自执行函数启动
│
├── 定义模块工厂函数 t[482]
│
├── 定义模块加载器 r
│
├── 获取全局对象 r.g
│
└── 调用 r(482) 加载入口模块
    │
    ├── 检查缓存 e[482] 是否存在？ → 不存在
    │
    ├── 创建模块对象 o = { exports: {} }
    │
    └── 执行 t[482].call(o.exports, o, o.exports, r)
        │
        ├── 加载依赖模块 r(191) 和 r(106)
        │
        ├── 定义函数 o()，绑定到 window.send_req 和 t.exports
        │
        └── 返回 o.exports（即函数 o）
```

**关键点总结**

1. 模块系统：
   - `Webpack` 将每个文件封装为模块，通过 ID（如 `482`）管理。
   - 模块加载器 `r(i)` 负责按需加载和缓存模块。
2. 依赖解析：
   - 模块 `482` 依赖 `191` 和 `106`，通过 `r(191)` 和 `r(106)` 动态加载。
3. 导出绑定：
   - 模块导出通过 `t.exports` 或 `window.send_req` 暴露给外部。
4. 运行时兼容性：
   - `r.g` 确保代码在不同环境（浏览器、`Node.js`）下能正确获取全局对象。

**用一个例子说明下：**

场景设定

- 图书馆：相当于 `Webpack` 的模块系统。
- 书架（缓存 `e`）：存放已经借过的书（已加载的模块），下次直接取用。
- 图书管理员（函数 `r`）：负责根据书名（模块 ID）找书（加载模块）。
- 图书仓库（模块工厂 `t`）：存放所有书的原始内容（模块代码），管理员需要时从仓库取书。

书架（`缓存e`）的作用是记录已经借出的书，避免重复取书，比如小明第一次借书《JavaScript高级编程》，管理员从仓库取出书，放在书架上（`e[482]`）；小红第二次来借书《JavaScript高级编程》，管理员直接从书架上取书（`e[482].exports`），不需要再进仓库。

图书管理员（函数r）职责是根据书名（模块Id）找书。首先检查书架上是否有书存在（`e[i]`），如果有，直接交给用户（返回`e[i].exports`），如果没有书，从仓库`t[i]`中取书，放入书架，再交给用户。

书之间的依赖（模块之间的依赖），小明借《三明治制作指南》（模块 482），但是书中提到需要《面包制作》（`e[191]`）和《火腿腌制》（`e[106]`），管理员先检查书架上是否有《面包制作》（模块191）和《火腿腌制》（模块106）。如果没有，会从仓库取书，（调用`t[191]`和`t[106]`），并放入书架，最后将完整的内容交给小明。

```javascript
function r(i) {
    var n = e[i]; // 检查书架上是否有书
    if (void 0 !== n) return n.exports; // 有书 → 直接取
    var o = e[i] = { exports: {} }; // 没书 → 新建书架位置
    return t[i].call(o.exports, o, o.exports, r), o.exports; // 从仓库取书并放入书架
}
```



### 28.4 逆向案例

学习了`webpack`打包逻辑，是为了在逆向中快速定位突破口，方便我们解决问题。而之前写的小项目是非常简单的，但实际场景下是很复杂的，需要通过实际案例来练习一下：

网址：https://kuwo.cn/search/list?key=T.R.Y

目标：找到发送请求参数`reqID`的生成逻辑

通过搜索关键字参数、`url`路径、调用栈这些常规的方法找到核心代码就不再过多赘述了。经过搜索，`param`是参数，通过`object(o.a)`发送的请求，下断点刷新页面，进入函数内部

![image-20250614070720860](../media/27-1)

进入到`o.a`函数内部，下断点后释放断点，让作用于进来，观察发现`t.data.reqId = n`，而`n`是`var n = l()()`执行以后赋值的结果，通过作用于也观察到了现在`n`的值是已经计算完的，就是我们在浏览器`payload`中看到的结果。所以，`var n = l()()`就是计算的函数，因为`()`的意思是函数的执行，所以要找到的函数是`l()`，鼠标选中，进入函数内部

![image-20250614071638861](../media/27-2)

进入函数后，这就是`webpack`打包之后的加载器，特征结果`113: function(e, t, n)`编号对应函数，`e.exports`导出函数等等。而真正执行的加载器是`e.exports = function(e, t, n)`参数`n`，`n`是在上一行执行的，所以在上一行下断点刷新页面，进入`n`函数

![image-20250614072655015](../media/27-3)

进来之后，看到的代码结构是不是很熟悉，这就是加载器。一个完整的网站有很多内容，经过打包之后肯定会很复杂，不会就存在一个加载器。

![image-20250614072953691](../media/27-4)

在代码量不是非常多的时候，几千行左右的，就没必要一点点抠了，全部抠出去。这个案例很少，只有不到200行。

![image-20250614073138504](../media/27-5)

抠出来之后，直接运行代码，如果没有报错，说明是完整的。结果报错了，错误说：`window is not defind`，因为`window`在浏览器环境中顶级对象，但是在`node`环境中是没有`window`的，而在`node`环境中的顶级对象是`global`。

![image-20250614084911572](../media/27-6)

所以，在`node`环境中创建顶级对象就可以了，在代码顶部创建`var window = global;`再次运行，就可以解决这个问题

![image-20250614085413025](../media/27-7)

接下来要做的事情就是把加载器从闭包函数中引入全局进行使用，方法是声明一个全局变量`var loader;`，在加载器函数`f`执行结束后，将函数`f`赋值给全局变量`loader`，这样就可以随便使用这个加载器`f`了。运行加载后没有报错，一切正常。

![image-20250614090200131](../media/27-8)

加载器负责的是加载模块，而网站此时需要的是`113`号模块，应该如何把模块导入加载器中？

![image-20250614090614785](../media/27-9)

把代码拉到最顶部，`(window.webpackJsonp = window.webpackJsonp || []).push([[32], {}`这行代码的作用是给加载器分发模块，执行的就是`push()`函数，所以我们把模块放在这个分发器中就可以了。把代码全部拿出去，做一下整理，只留下我们需要的模块函数即可。

![image-20250614094922865](../media/27-10)

我们需要的是`113`号模块，所以其他的全部删除。整理之后，跟以前的代码做融合，放到闭包函数后面即可。到此，`console.log(loader("113"))`就可以去提取`113`号模板了。

![image-20250614095316381](../media/27-11)

补全代码后运行，报错` return e[r].call(t.exports, t, t.exports, f)`，` Cannot read properties of undefined (reading 'call')`，记住：如果加载器出现了这个错误，说明加载器中缺少模块，只要补充模块就可以了。解决的方法是在加载器中把模块号打印出来，按照提示的编号进行补充即可。

```javascript
function f(r) {
        // 输出加载的模块编号
        console.log(r)
        if (n[r])
            return n[r].exports;
        var t = n[r] = {
            i: r,
            l: !1,
            exports: {}
        };
        return e[r].call(t.exports, t, t.exports, f),
        t.l = !0,
        t.exports
    }
```

运行代码后，正常获取`113`号模块，但是没有找到`148`号模块，所以报错了。缺什么补什么就可以了，知道运行不再报错。

![image-20250614100057189](../media/27-12)

![image-20250614100446184](../media/27-13)

然后根据网站实际调用逻辑调用函数（`var n = l()()`），运行后直接出结果了。

```javascript
var l = loader(113)();
console.log(l);
```

![image-20250614100818939](../media/27-14)

到此位置，使用`webpack`技术逆向的逻辑就结束了，剩下的就使用`python`写程序发送请求就可以了。但是需要注意有时候如果浏览器检测环境，通过`webpack`是没有办法完成逆向的，还要结合补环境使用。所以，在逆向的过程要灵活使用。


