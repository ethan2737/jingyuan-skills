## 第30章：逆向之WASM专题

---

### 30.1 简介

`WebAssembly`（简称`Wasm`）是一种现代的低级编程语言，设计用于在网页上运行高性能的代码。它可以被看作是一个编译目标，开发者可以将`C`、`C++`、`Rust`等语言编写的代码编译成`WebAssembly`格式，然后在浏览器中运行。

`WebAssembly`的主要特点包括：

- 高性能：接近原生性能，能够比`JavaScript`更快的执行计算密集型任务；
- 安全性：在沙箱环境中运行，保证了代码的安全性；
- 跨平台：可以在各种浏览器和操作系统上运行，支持多种硬件架构；
- 与`JavaScript`互操作：可以与`JavaScript`无缝协作，调用`JavaScript`函数，或者从`JavaScript`调用`Wasm`模块。

它广泛应用于游戏、图像处理、科学计算等领域，尤其是需要高性能的`web`应用。

### 30.2 浏览器执行`Wasm`原理

- 浏览器支持：现代浏览器（如：Chrome、Firefox、Safari）都原生支持`Wasm`，能够解析和执行`Wasm`二进制格式；
- 安全沙箱：`Wasm`在一个安全的沙箱环境中运行，确保了代码的安全性，避免了对主机系统的直接访问；
- 高效编译：`Wasm`代码在加载时可以快速编译为机器代码，确保高性能执行；
- 与JavaScript互操作：`Wasm`能够与JavaScript进行交互，可以通过JavaScript调用`Wasm`模块中的函数，增强了`Web`应用的功能。

`Wasm`语法：https://www.zhihu.com/column/c_1603119162976595968

### 30.3 `Wasm`调用方法

1. 网页加载过程
   - 创建`Wasm`模块：使用`C`、`C++`、`Rust`等语言编写代码，并编译成`Wasm`文件；
   - 加载`Wasm`模块：使用`JavaScript`的`Fetch API`获取`Wasm`文件，并用`WebAssembly.instantiate`或`WebAssembly.instantiateStreaming`进行加载`Wasm`文件，相当于`Python`中的`import`导包操作；
   - 调用`Wasm`导出函数：通过实例化`Wasm`模块，可以调用导出的函数并于`JavaScript`进行交互；



### 30.4`Fetch`模块

`Fetch`模块用于在浏览器中进行网络请求，主要作用是获取资源，如文本、`JSON`、图片或`Wasm`模块。它返回一个`Promise`，方便处理异步操作。是一个简洁版的`ajax`。是现代浏览器中推荐使用的方式，具有更好的灵活性和功能性。

**语法与使用：**

1. `fetch：`

   - 基于`Promise`，语法简洁，使用链式调用处理相应

   - ```javascript
     fetch('https://api.example.com/data').then(response => response.json()).then(data => console.log(data)).catch(error => console.error('Error:', error));
     ```

2. `Ajax(XMLHttpRequest)`

   - 使用回调函数，代码通常更复杂，特别是处理异步操作时

   - ```javascript
     var xhr = new XMLHttpRequest();
     xhr.open('GET', 'https://api.example.com/data', true);
     xhr.onload = function(){
         if (xhr.status >= 200 && xhr.status < 300){
             console.log(JSON.parse(xhr.responseText));
         } else {
             console.error('Error:', xhr.statusText);
         }
     };
     
     xhr.onerror = function(){
         console.log("Network Error");
     };
     
     xhr.send();
     ```

**支持的功能：**

1. `fetch`
   - 默认不发送`cookie`，需要额外配置；
   - 支持更丰富的请求和响应处理（如流、读取响应体的多种格式）
2. `Ajax`
   - 自动处理`cookie`，适合需要认证的请求
   - 支持较老的浏览器

**错误处理：**

1. `fetch`
   - 只会在网络错误时拒绝`Promise`，HTTP错误状态（如404、500）不会导致拒绝；
   - 需要手动检查响应的`ok`属性
2. `Ajax`
   - 通过状态吗判断成功与否，可以在`onload`回调中处理



### 30.5 `WebAssembly`模块

`WebAssembly.instantiate`是一个用于加载和实例化`WebAssembly`模块的函数。它可以接收一个字节数组（`Wasm`二进制数据）和可选的导入对象。

```javascript
WebAssembly.instantiate(bytes, importObject)
```

**`bytes`和`importObject`**

1. `bytes`

   - 类型：`ArrayBuffer`或`TypeArray`，通常由`fetch`请求得到二进制数据
   - 作用：包含编译好的`WebAssembly`模块的二进制表示。`Wasm`模块必须先编译成这种格式，才能被实例化

2. `importObject`

   - 类型：对象，用于提供模块所需要的外部依赖
   - 作用：包含了`WebAssembly`模块提供需要调用的外部函数或全局变量。这个对象的结构通常与模块中定义的导入相对应。例如，如果模块需要一个外部函数，你需要在这个对象中定义它（类似与创建类的初始化参数）。

   ```javascript
   const importObject = {
       env:{
           importedFunc:function(){
               console.log('Hello from javascript!');
           }
       }
   };
   
   // 假设bytes是从网络请求中获取的 ArrayBuffer
   WebAssembly.instantiate(bytes, importObject).then(results => {
       const instance = results.instance;
       instance.exports.yourFunction();
   });
   ```

   **`WebAssembly`返回值**

   `WebAssembly.instantiate`的返回值是一个`Promise`，该`Promise`解析为一个对象，包含以下属性：

   1. `instance`
      - 类型：`WebAssembly.instantiate`对象
      - 作用：表示实例化后的`WebAssembly`模块，包含模块的导出（即可以调用的函数和变量）
   2. `module`
      - 类型：`WebAssembly.Module`对象
      - 作用：表示编译后的`WebAssembly`模块，可以用于进一步的实例化。

   ```javascript
   fetch('module.wasm').then(response => response.arrayBuffer()).then(bytes => WebAssembly.instantiate(bytes)).then(results => {
       const instance = results.instance;
       console.log('Exports:', instance.exports);//访问导出函数
   }).catch(error => {
       console.log('Error:', err);
   });
   ```

   

   ### 30.6`Node`调用`Wasm`

   `Node`有提供`WebAssembly`库可以直接使用

   ```javascript
   const fs = require('fs');
   const wasmCode = fs.readFileSync('Wasm.wasm');
   console.log(wasmCode);
   
   WebAssembly.instantiate(wasmCode, {
       "env":{},
       "wasi_snapshot_previewl":{}
   }).then(result => {
       const instance = result.instance;
       const exportedFunc = instance.exports;
       console.log(exportedFunc);//调用wasm模块中的函数
       console.log(exportedFunc.encrypt(50, 1727186733));//调用wasm模块中的函数
   });
   ```

   

### 30.7`Python`调用`Wasm`

`python`需要使用`pywasm`库进行调用

```python
import pywasm
import time

t = int(time.time())
vm = pywasm.load("./Wasm.wasm", {
    "env":{},
    "wasi_snapshot_previewl":{}
})

print(vm)
sign = vm.exec("encrypt", [40, t])
print(sign)
```



### 30.8 `wasm`在逆向中的定位

1. `this`定位
   - 通过类名定位 ` = new a`
   - 通过属性定位 `this.$wasm`、`$wasm:`、`this.$wasm = `
   - 通过方法定位，方法一般在类的内部，
2. `wasm`参数定位
   - `fetch`
   - `WebAssembly.instantiate`



