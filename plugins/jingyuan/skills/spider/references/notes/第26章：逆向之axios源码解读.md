## 第26章：逆向之axios源码解读

---

有的时候通过搜索三件套并不会找到加密的入口，在`Initiator`中明明看到了`Promise.then`但是就搜索不到`interceptors`，这种情况是因为网站把`axios.interceptors.request.use`或者`axios.interceptors.response.use`进行了混淆。如果我们理解了`axios`底层逻辑，那么网站再怎么混淆，都可以快速定位入口。

### 26.1 `axios`核心逻辑

```javascript
var t =[o, undefined]; // t就是后面用来发送请求的
n = Promise.resolve(e);
this.interceptors.request.forEach((function(e) {
    t.unshift(e.fulfilled, e.rejected) // unshift 也是特征之一
}
)),

// t = [哈哈, 呵呵, o, undefined] // 怼完请求拦截器
this.interceptors.response.forEach((function(e) {
    t.push(e.fulfilled, e.rejected)  // push 也是特征之一
}
));
// // t = [哈哈, 呵呵, o, undefined, 哈尔滨, 牡丹江]  # 怼完响应拦截器

for (; t.length; ) //程序执行到这里时候,  t里面装的,就是axios完整的流程
    n = n.then(t.shift(), t.shift());
// 第一次循环
 n = n.then(哈哈, 呵呵); // 请求发送之前
 // 第二次循环
 n = n.then(o, undefined); // 发请求
  // 第三次循环
 n = n.then(哈尔滨, 牡丹江); // 响应回来之后, 干什么

// 使用拦截器 -> 请求
axios.interceptors.request.use(function(){哈哈}, function(){呵呵})
// 响应
axios.interceptors.response.use(function(){哈尔滨}, function(){牡丹江})

// t里面装的是完整的流程
[请求拦截器,  o, undefined,  响应拦截器]  // 这里的undefined是为了凑对的

```

举个小例子：

```tex
        快递车启动
          │
          ▼
┌───────────────────┐
│   请求拦截成功     │ ← 后添加的先执行
├───────────────────┤
│   请求拦截失败     │
├───────────────────┤
│     发车函数       │ ← 实际发送请求
├───────────────────┤
│     undefined      │ （占位符）
├───────────────────┤
│   响应拦截成功     │ ← 先添加的先执行
├───────────────────┤
│   响应拦截失败     │
└───────────────────┘
```

### 26.2 如何快速定位

- **找 `unshift` 操作**：这是请求拦截器的特征，会把拦截器插入到数组最前面
- **找 `push` 操作**：这是响应拦截器的特征，会把拦截器追加到数组末尾
- **找 `then` 的链式调用**：`n.then(...)` 是拦截器执行的关键
- **找 `interceptors` 数组**：`this.interceptors.request/response` 是拦截器存储的位置

记个小口诀

- 请求拦截倒着走（unshift插最前） 
- 响应拦截顺着跑（push加最后面） 
- then链式串起来 
- 执行顺序看数组



### 26.3 实战案例

七麦网址：https://www.qimai.cn/

搜索`interceptors`时直接显示的`axios`源代码，点击代码定位源代码位置，通过上面的分析已经知道了`axios`发送请求的原理，在循环中执行`.then`的就是发送请求的地方，而那个数组`t`里面就装载着请求拦截器和响应拦截器

![image-20250610202248307](../media/25-1)

在当前作用域下，控制台中输入`t`，显示一个数组` [ƒ, ƒ, ƒ, undefined, ƒ, ƒ]`，因为是成偶数对出现的，`undefined`和前面的`f`是发送请求的，第一个函数`f`是请求拦截器拦截成功后执行的函数，第二个函数是请求拦截器拦截失败后执行的函数，倒数第二个函数是响应拦截器拦截成功执行的函数，倒数第一个函数是响应拦截器拦截失败后执行的函数。

![image-20250610203149328](../media/25-2)

进入拦截器就可以正常逆向了

![image-20250610203324515](../media/25-3)


