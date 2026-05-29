## 第27章：逆向之`sojson`

---

`sojson`是一种网站反调试技术，主要表现是当使用开发者工具调试网站时会出现`无限debugger`，并且在过掉`debugger`后，格式化代码依然会出现各种问题，直至浏览器彻底挂掉。

解决`sojson`加密后的网站通过有三种方式，使用抓包工具`Charles`进行本地`hook`：

- 方式一：`hook eval` 或者 `hook Function` 处理 `无限debugger`问题，执行的步骤是，先进入页面，打开`F12`，然后`HOOK`掉`setInterval`，`ctrl+shift+r`刷新页面，一般情况下就可以直接进行调试了。如果对本地代码进行了格式化，则还需要进行方式二的`hook`

  ```javascript
  // hook setInterval
  var setInterval_ = setInterval
  setInterval = function () {
      // debugger;
      // 不让它执行正常的了. 直接怼死
  }
  ```

  

- 方式二：`hook Function.prototype.toString`处理格式化代码出现的反调试问题。格式化就是检测函数是否格式化了，正常的代码经过压缩后会显示在一行内容，函数中是没有换行、空格之类的特殊符号，而如果格式化了代码，函数中一定会出现大量的空格、换行等特殊字符。一旦触发代码格式化的检测，代码逻辑就不走了，直接会报错或者没有程序入口。

  ```javascript
  var func_toString = Function.prototype.toString;
  
  Function.prototype.toString = function(){
      var s = func_toString.apply(this, arguments);
      console.log(s);
      // debugger;
      return s;
  };
  ```

  

- 方式三：禁用`console.log()`在控制台输出功能，在进行以上`hook`行为前，可以对`console.log()`提前备份

  ```javascript
  var Ethan = console.log;
  ```

遇到`sojson`的网站，无论是`sojson.v5版本`还是`sojson.v6版本`，甚至是`sojson.v7版本`，一般通过这三板斧基本上都可以搞定。

另外还一种网站会使用的反调试的手段就是跳出页面。当你打开调试工具时，会检测窗口的大小等事件触发反调试手段，直接跳出页面不让你调试，这种方式可以`hook onbeforeunload`事件解决，代码如下：

```javascript
window.onbeforeunload = function(){
    debugger;
};
```

通过监听`window.onberforeload`事件，当窗口即将跳转时触发`debugger`断点，从而可以在浏览器的调用栈中观察调用情况，但是这种方式有时好用有时不好用，要看浏览器的版本，太旧的或者太新的版本都有可能断不住


