## 第11章：Selenium 的使用

---

Selenium 是一个自动化测试工具，利用它可以驱动浏览器执行特定的动作，如点击、下拉等操作，同时还可以获取浏览器当前呈现的页面的源代码，做到可见即可爬。对于一些 JavaScript 动态渲染的页面来说，此种抓取方式非常有效。

### 11.1  ChromeDriver的安装

1. 查看Chrome版本：点击Chrome菜单“帮助” --关于Google Chrome -- 查看Chrome的版本号。

2. 下载ChromeDriver，链接地址：https://chromedriver.storage.googleapis.com/index.html，下载对应版本号的驱动即可。

3. 环境变量配置：直接将 chromedriver.exe 文件拖到 Python 的 Scripts 目录下。

4. 验证安装：配置完成后，运行cmd，输入命令chromedriver即可。能看到ChromeDriver对应的版本号则证明安装完成。

5. 在程序中测试：运行之后弹出一个空白的Chrome浏览器，证明安装成功；如果没有弹出或者弹出后闪退，检查版本号是否正确。

   ```python
   from selenium import webdriver
   web = webdriver.Chrome()
   ```

   

### 11.2  基本使用

首先体验一下 Selenium。示例如下：

```python
# 导入谷歌浏览器驱动
from selenium.webdriver import Chrome
# 配置浏览器选项的包
from selenium.webdriver.chrome.options import Options

# 配置 Chrome 选项
options = Options()
options.add_experimental_option("detach", True)  # 关键：禁止自动关闭
# 如果遇到浏览器自动关闭的情况，可以这样配置
browser = Chrome(options=options)
# 向百度发送请求
browser.get("https://www.baidu.com/")
# 获取百度的标题
print(browser.title)
# 浏览器窗口最大化
browser.maximize_window()
```

运行代码后发现，会自动弹出一个 Chrome 浏览器。浏览器首先会跳转到百度。

```
E:/PythonInterpreter/Python12/python.exe E:/PythonCodes/19_selenium/11_selenium入门.py
百度一下，你就知道

Process finished with exit code 1
```

下面来详细了解一下 Selenium 的用法。

### 11.3  声明浏览器对象

Selenium 支持非常多的浏览器，如 Chrome、Firefox、Edge 等，还有 Android、BlackBerry 等手机端的浏览器。另外，也支持无界面浏览器 PhantomJS。可以用如下方式初始化：

```python
from selenium.webdriver import Chrome

browser = webdriver.Chrome()
browser = webdriver.Firefox()
browser = webdriver.Edge()
browser = webdriver.PhantomJS()
browser = webdriver.Safari()
```

这样就完成了浏览器对象的初始化并将其赋值为 browser 对象。接下来，我们要做的就是调用 browser 对象，让其执行各个动作以模拟浏览器操作。

### 11.4  访问页面

可以用 get() 方法来请求网页，参数传入链接 URL 即可。比如，这里用 get() 方法访问淘宝，然后打印出源代码，代码如下：

```python
from selenium.webdriver import Chrome

browser = webdriver.Chrome()
browser.get('https://www.taobao.com')
print(browser.page_source)
browser.close()
```

运行后发现，弹出了 Chrome 浏览器并且自动访问了淘宝，然后控制台输出了淘宝页面的源代码，随后浏览器关闭。

通过这几行简单的代码，我们可以实现浏览器的驱动并获取网页源码，非常便捷。

### 11.5  查找节点

Selenium 可以驱动浏览器完成各种操作，比如填充表单、模拟点击等。比如，我们想要完成向某个输入框输入文字的操作，总需要知道这个输入框在哪里吧？而 Selenium 提供了一系列查找节点的方法，我们可以用这些方法来获取想要的节点，以便下一步执行一些动作或者提取信息。

#### 11.5.1 单个节点

比如，想要从淘宝页面中提取搜索框这个节点，首先要观察它的源代码

![image-21251513153457513](../media/image-21251513153457513.png)

可以发现，它的 id 是 q，name 也是 q。此外，还有许多其他属性，此时我们就可以用多种方式获取它了。Selenium 通过 `find_element()` 方法结合 `By` 类实现元素定位，返回第一个匹配的节点。若未找到，抛出 `NoSuchElementException`。

我们用代码实现一下：


```python
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By

browser = Chrome()
browser.get("https://www.taobao.com")
input_first = browser.find_element(By.ID,"q")
input_second = browser.find_element(By.CSS_SELECTOR,"#q")
input_third = browser.find_element(By.XPATH, "//*[@id='q']")
print(input_first, input_second, input_third)
browser.close()
```
这里我们使用 3 种方式获取输入框，分别是根据 ID、CSS 选择器和 XPath 获取，它们返回的结果完全一致。运行结果如下：
```python
<selenium.webdriver.remote.webelement.WebElement (session="2a83f95722d66311162571fb499fa911", element="f.D2324B996E9F24FB4EE7C5E23F943A6C.d.A953D1214E1F48E861DC2664C8E184A8.e.2")> <selenium.webdriver.remote.webelement.WebElement 

(session="2a83f95722d66311162571fb499fa911", element="f.D2324B996E9F24FB4EE7C5E23F943A6C.d.A953D1214E1F48E861DC2664C8E184A8.e.2")> <selenium.webdriver.remote.webelement.WebElement 

(session="2a83f95722d66311162571fb499fa911", element="f.D2324B996E9F24FB4EE7C5E23F943A6C.d.A953D1214E1F48E861DC2664C8E184A8.e.2")>
```

可以看到，这 3 个节点都是 WebElement 类型，是完全一致的。

这里列出所有获取单个节点的方法：

```
element = browser.find_element(By.ID, "element_id")
element = browser.find_element(By.NAME, "element_name")
element = browser.find_element(By.CLASS_NAME, "class_name")
element = browser.find_element(By.LINK_TEXT, "完整链接文本")
element = browser.find_element(By.PARTIAL_LINK_TEXT, "部分链接文本")
element = browser.find_element(By.TAG_NAME, "tag_name")
element = browser.find_element(By.CSS_SELECTOR, "css_selector")
element = browser.find_element(By.XPATH, "xpath_expression")
```
另外，在 Selenium 4+ 版本中新增了相对定位器，用于基于其他元素位置的定位（需要导入 `RelativeBy`）。支持的方法：`above()`, `below()`, `to_left_of()`, `to_right_of()`, `near()`。

```python
from selenium.webdriver.support.relative_locator import RelativeBy

# 示例：在已知元素下方查找
reference_element = driver.find_element(By.ID, "reference_id")
target_element = driver.find_element(RelativeBy(By.TAG_NAME, "div").below(reference_element))
```

> **优先级**：优先使用唯一性强的定位方式（如 `ID` > `CSS Selector` > `XPath`）



#### 11.5.2 多个节点

如果查找的目标在网页中只有一个，那么完全可以用 find_element() 方法。但如果有多个节点，再用 find_element() 方法查找，就只能得到第一个节点了。如果要查找所有满足条件的节点，需要用 find_elements() 这样的方法。注意，在这个方法的名称中，element 多了一个 s，注意区分。比如，要查找淘宝左侧导航条的所有条目

![image-21251513161244688](../media/image-21251513161244688.png)

就可以这样来实现：

```python
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By

browser = Chrome()
browser.get("https://www.taobao.com/")
browser.implicitly_wait(5)
lis = browser.find_elements(By.CSS_SELECTOR, ".service-bd--LdDnWwA9 li")
print(lis)
```
运行结果如下：
```python
[<selenium.webdriver.remote.webelement.WebElement (session="c26291835d4457ebf7d96bfab3741d19", element="1.19221144133125613-1")>, <selenium.webdriver.remote.webelement.WebElement (session="c26291835d4457ebf7d96bfab3741d19", element="1.19221144133125613-2")>, <selenium.webdriver.remote.webelement.WebElement (session="c26291835d4457ebf7d96bfab3741d19", element="1.19221144133125613-3")>...<selenium.webdriver.remote.webelement.WebElement (session="c26291835d4457ebf7d96bfab3741d19", element="1.19221144133125613-16")>]
```

可以看到，得到的内容变成了列表类型，列表中的每个节点都是 WebElement 类型。

也就是说，如果我们用 find_element() 方法，只能获取匹配的第一个节点，结果是 WebElement 类型。如果用 find_elements() 方法，则结果是列表类型，列表中的每个节点是 WebElement 类型。这里列出所有获取多个节点的方法：

```
element = browser.find_elements(By.ID, "element_id")
element = browser.find_elements(By.NAME, "element_name")
element = browser.find_elements(By.CLASS_NAME, "class_name")
element = browser.find_elements(By.LINK_TEXT, "完整链接文本")
element = browser.find_elements(By.PARTIAL_LINK_TEXT, "部分链接文本")
element = browser.find_elements(By.TAG_NAME, "tag_name")
element = browser.find_elements(By.CSS_SELECTOR, "css_selector")
element = browser.find_elements(By.XPATH, "xpath_expression")
```
### 11.6  节点交互

Selenium 可以驱动浏览器来执行一些操作，也就是说可以让浏览器模拟执行一些动作。比较常见的用法有：输入文字时用 send_keys 方法，清空文字时用 clear 方法，点击按钮时用 click 方法。示例如下：

```python
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
import time

browser = Chrome()
browser.get("https://www.taobao.com/")
input = browser.find_element(By.ID, "q")
input.send_keys("手机")
time.sleep(2)
input.clear()
input.send_keys("电脑")
# 这里需要注意一定：网页中class="btn-search tb-bg" 表示该元素同时拥有两个 class：btn-search 和 tb-bg。这是 HTML 中定义多个 class 的标准写法，多个 class 之间用空格分隔
# CSS 选择器的正确写法 .btn-search.tb-bg
button = browser.find_element(By.CSS_SELECTOR, ".btn-search.tb-bg")
button.click()

```

这里首先驱动浏览器打开淘宝，然后用 find_element(By.ID) 方法获取输入框，然后用 send_keys() 方法输入手机文字，等待2秒后用 clear() 方法清空输入框，再次调用 send_keys() 方法输入 电脑文字，之后再用find_element(By.CSS_SELECTOR, ".btn-search.tb-bg")方法获取搜索按钮，最后调用 click() 方法完成搜索动作。

通过上面的方法，我们就完成了一些常见节点的动作操作，更多的操作可以参见官方文档的交互动作介绍
：[http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.remote.webelement](http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.remote.webelement)。

### 11.7  动作链

在上面的实例中，一些交互动作都是针对某个节点执行的。比如，对于输入框，我们就调用它的输入文字和清空文字方法；对于按钮，就调用它的点击方法。其实，还有另外一些操作，它们没有特定的执行对象，比如鼠标拖曳、键盘按键等，这些动作用另一种方式来执行，那就是动作链。

比如，现在实现一个节点的拖曳操作，将某个节点从一处拖曳到另外一处，可以这样实现：

```python
from selenium import webdriver
from selenium.webdriver import ActionChains
import time

browser = webdriver.Chrome()
url = 'http://www.runoob.com/try/try.php?filename=jqueryui-api-droppable'
browser.get(url)
browser.switch_to.frame('iframeResult')
source = browser.find_element_by_css_selector('#draggable')
target = browser.find_element_by_css_selector('#droppable')
actions = ActionChains(browser)
actions.drag_and_drop(source, target)
actions.perform()
time.sleep(5)
browser.close()
```

首先，打开网页中的一个拖曳实例，然后依次选中要拖曳的节点和拖曳到的目标节点，接着声明 ActionChains 对象并将其赋值为 actions 变量，然后通过调用 actions 变量的 drag_and_drop() 方法，再调用 perform() 方法执行动作，此时就完成了拖曳操作，如图 7-4 和 7-5 所示：

拖曳前页面

![](../media/11-1.jpg)

拖曳后页面

![](../media/11-2.jpg)

以上两图分别为在拖曳前和拖曳后的结果。

更多的动作链操作可以参考官方文档的动作链介绍：[http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.common.action_chains](http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.common.action_chains)。

### 11.8  执行 JavaScript

对于某些操作，Selenium API 并没有提供。比如，下拉进度条，它可以直接模拟运行 JavaScript，此时使用 execute_script() 方法即可实现，代码如下：

```python
from selenium import webdriver
import time

browser = webdriver.Chrome()
browser.get('https://www.zhihu.com/knowledge-plan/hot-question/hot/1/hour')
browser.execute_script('window.scrollTo(1, document.body.scrollHeight)')
browser.execute_script('alert("To Bottom")')
time.sleep(5)
```

这里就利用 execute_script() 方法将进度条下拉到最底部，然后弹出 alert 提示框。

所以说有了这个方法，基本上 API 没有提供的所有功能都可以用执行 JavaScript 的方式来实现了。


### 11.9  获取节点信息

前面说过，通过 page_source 属性可以获取网页的源代码，接着就可以使用解析库（如正则表达式、Beautiful Soup、pyquery 等）来提取信息了。

不过，既然 Selenium 已经提供了选择节点的方法，返回的是 WebElement 类型，那么它也有相关的方法和属性来直接提取节点信息，如属性、文本等。这样的话，我们就可以不用通过解析源代码来提取信息了，非常方便。

#### 11.9.1 获取属性

我们可以使用 get_attribute() 方法来获取节点的属性，但是其前提是先选中这个节点，示例如下：

```python
from selenium import webdriver
from selenium.webdriver import ActionChains

browser = webdriver.Chrome()
url = 'https://www.zhihu.com/explore'
browser.get(url)
logo = browser.find_element_by_id('zh-top-link-logo')
print(logo)
print(logo.get_attribute('class'))
```

运行之后，程序便会驱动浏览器打开知乎页面，然后获取知乎的 logo 节点，最后打印出它的 class。

控制台的输出结果如下：


```python
<selenium.webdriver.remote.webelement.WebElement (session="e18c1f28d7f44d75ccd51df6bb676114", element="1.7236391661148155-1")>
zu-top-link-logo
```

通过 get_attribute() 方法，然后传入想要获取的属性名，就可以得到它的值了。

#### 11.9.2 获取文本值

每个 WebElement 节点都有 text 属性，直接调用这个属性就可以得到节点内部的文本信息，这相当于 Beautiful Soup 的 get_text() 方法、pyquery 的 text() 方法，示例如下：

```python
from selenium import webdriver

browser = webdriver.Chrome()
url = 'https://www.zhihu.com/explore'
browser.get(url)
input = browser.find_element_by_class_name('zu-top-add-question')
print(input.text)
```

这里依然先打开知乎页面，然后获取 “提问” 按钮这个节点，再将其文本值打印出来。

控制台的输出结果如下：

```
提问
```

#### 11.9.3 获取 ID、位置、标签名、大小

另外，WebElement 节点还有一些其他属性，比如 id 属性可以获取节点 id，location 属性可以获取该节点在页面中的相对位置，tag_name 属性可以获取标签名称，size 属性可以获取节点的大小，也就是宽高，这些属性有时候还是很有用的。示例如下：

 ```python
 from selenium import webdriver

browser = webdriver.Chrome()
url = 'https://www.zhihu.com/explore'
browser.get(url)
input = browser.find_element_by_class_name('zu-top-add-question')
print(input.id)
print(input.location)
print(input.tag_name)
print(input.size)
 ```

这里首先获得 “提问” 按钮这个节点，然后调用其 id、location、tag_name、size 属性来获取对应的属性值。

### 11.10  切换 Frame

我们知道网页中有一种节点叫作 iframe，也就是子 Frame，相当于页面的子页面，它的结构和外部网页的结构完全一致。Selenium 打开页面后，它默认是在父级 Frame 里面操作，而此时如果页面中还有子 Frame，它是不能获取到子 Frame 里面的节点的。这时就需要使用 switch_to.frame() 方法来切换 Frame。示例如下：

```python
import time
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException

browser = webdriver.Chrome()
url = 'http://www.runoob.com/try/try.php?filename=jqueryui-api-droppable'
browser.get(url)
browser.switch_to.frame('iframeResult')
try:
    logo = browser.find_element_by_class_name('logo')
except NoSuchElementException:
    print('NO LOGO')
browser.switch_to.parent_frame()
logo = browser.find_element_by_class_name('logo')
print(logo)
print(logo.text)
```
控制台输出：
```python
NO LOGO
<selenium.webdriver.remote.webelement.WebElement (session="4bb8ac13ced4ecbdefef13ffdc1e4ccd", element="1.13792611321464965-2")>
RUNOOB.COM
```

这里还是以前面演示动作链操作的网页为实例，首先通过 switch_to.frame() 方法切换到子 Frame 里面，然后尝试获取子 Frame 里的 logo 节点（这是不能找到的），如果找不到的话，就会抛出 NoSuchElementException 异常，异常被捕捉之后，就会输出 NO LOGO。接下来，重新切换回父级 Frame，然后再次重新获取节点，发现此时可以成功获取了。

所以，当页面中包含子 Frame 时，如果想获取子 Frame 中的节点，需要先调用 switch_to.frame() 方法切换到对应的 Frame，然后再进行操作。

### 11.11  延时等待

在 Selenium 中，get() 方法会在网页框架加载结束后执行，此时如果获取 page_source，可能并不是浏览器完全加载完成的页面，如果某些页面有额外的 Ajax 请求，我们在网页源代码中也不一定能成功获取到。所以，这里需要延时等待一定时间，确保节点已经加载出来。

这里等待的方式有两种：一种是隐式等待，一种是显式等待。

#### 11.11.1 隐式等待

当使用隐式等待执行测试的时候，如果 Selenium 没有在 DOM 中找到节点，将继续等待，超出设定时间后，则抛出找不到节点的异常。换句话说，当查找节点而节点并没有立即出现的时候，隐式等待将等待一段时间再查找 DOM，默认的时间是 1。示例如下：

```python
from selenium import webdriver

browser = webdriver.Chrome()
browser.implicitly_wait(11)
browser.get('https://www.zhihu.com/explore')
input = browser.find_element_by_class_name('zu-top-add-question')
print(input)
```

在这里我们用 implicitly_wait() 方法实现了隐式等待。

#### 11.11.2 显式等待

隐式等待的效果其实并没有那么好，因为我们只规定了一个固定时间，而页面的加载时间会受到网络条件的影响。

这里还有一种更合适的显式等待方法，它指定要查找的节点，然后指定一个最长等待时间。如果在规定时间内加载出来了这个节点，就返回查找的节点；如果到了规定时间依然没有加载出该节点，则抛出超时异常。示例如下：


```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

browser = webdriver.Chrome()
browser.get('https://www.taobao.com/')
wait = WebDriverWait(browser, 11)
input = wait.until(EC.presence_of_element_located((By.ID, 'q')))
button = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, '.btn-search')))
print(input, button)
```

这里首先引入 WebDriverWait 这个对象，指定最长等待时间，然后调用它的 until() 方法，传入要等待条件 expected_conditions。比如，这里传入了 presence_of_element_located 这个条件，代表节点出现的意思，其参数是节点的定位元组，也就是 ID 为 q 的节点搜索框。

这样可以做到的效果就是，在 11 秒内如果 ID 为 q 的节点（即搜索框）成功加载出来，就返回该节点；如果超过 11 秒还没有加载出来，就抛出异常。

对于按钮，可以更改一下等待条件，比如改为 element_to_be_clickable，也就是可点击，所以查找按钮时查找 CSS 选择器为.btn-search 的按钮，如果 11 秒内它是可点击的，也就是成功加载出来了，就返回这个按钮节点；如果超过 11 秒还不可点击，也就是没有加载出来，就抛出异常。

运行代码，在网速较佳的情况下是可以成功加载出来的。

控制台的输出如下：


```python
<selenium.webdriver.remote.webelement.WebElement (session="17dd2fbc2d5b1ce41e82b9754aba8fa8", element="1.5642646294174117-1")>
<selenium.webdriver.remote.webelement.WebElement (session="17dd2fbc2d5b1ce41e82b9754aba8fa8", element="1.5642646294174117-2")>
```

可以看到，控制台成功输出了两个节点，它们都是 WebElement 类型。

如果网络有问题，11 秒内没有成功加载，那就抛出 TimeoutException 异常，此时控制台的输出如下：


```python
TimeoutException Traceback (most recent call last)
<ipython-input-4-f3d73973b223> in <module>()
      7 browser.get('https://www.taobao.com/')
      8 wait = WebDriverWait(browser, 11)
----> 9 input = wait.until(EC.presence_of_element_located((By.ID, 'q')))
```

关于等待条件，其实还有很多，比如判断标题内容，判断某个节点内是否出现了某文字等。表 7-1 列出了所有的等待条件。

表 7-1　等待条件及其含义


| 等待条件 | 含义 |
| ------ | ---- | 
| title_is | 标题是某内容 |
| title_contains | 标题包含某内容 |
| presence_of_element_located | 节点加载出，传入定位元组，如 (By.ID, 'p') |
| visibility_of_element_located | 节点可见，传入定位元组 |
| visibility_of | 可见，传入节点对象 |
| presence_of_all_elements_located | 所有节点加载出 |
| text_to_be_present_in_element | 某个节点文本包含某文字 |
| text_to_be_present_in_element_value | 某个节点值包含某文字 |
| frame_to_be_available_and_switch_to_it frame | 加载并切换 |
| invisibility_of_element_located | 节点不可见 |
| element_to_be_clickable | 节点可点击 |
| staleness_of | 判断一个节点是否仍在 DOM，可判断页面是否已经刷新 |
| element_to_be_selected | 节点可选择，传节点对象 |
| element_located_to_be_selected | 节点可选择，传入定位元组 |
| element_selection_state_to_be | 传入节点对象以及状态，相等返回 True，否则返回 False |
| element_located_selection_state_to_be | 传入定位元组以及状态，相等返回 True，否则返回 False |
| alert_is_present | 是否出现 Alert |

更多详细的等待条件的参数及用法介绍可以参考官方文档：[http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.support.expected_conditions](http://selenium-python.readthedocs.io/api.html#module-selenium.webdriver.support.expected_conditions)。

### 11.12  前进后退

平常使用浏览器时都有前进和后退功能，Selenium 也可以完成这个操作，它使用 back() 方法后退，使用 forward() 方法前进。示例如下：


```python
import time
from selenium import webdriver

browser = webdriver.Chrome()
browser.get('https://www.baidu.com/')
browser.get('https://www.taobao.com/')
browser.get('https://www.python.org/')
browser.back()
time.sleep(1)
browser.forward()
browser.close()
```

这里我们连续访问 3 个页面，然后调用 back() 方法回到第二个页面，接下来再调用 forward() 方法又可以前进到第三个页面。

### 11.13  Cookies

使用 Selenium，还可以方便地对 Cookies 进行操作，例如获取、添加、删除 Cookies 等。示例如下：

```python
from selenium import webdriver

browser = webdriver.Chrome()
browser.get('https://www.zhihu.com/explore')
print(browser.get_cookies())
browser.add_cookie({'name': 'name', 'domain': 'www.zhihu.com', 'value': 'germey'})
print(browser.get_cookies())
browser.delete_all_cookies()
print(browser.get_cookies())
```

首先，我们访问了知乎。加载完成后，浏览器实际上已经生成 Cookies 了。接着，调用 get_cookies() 方法获取所有的 Cookies。然后，我们添加一个 Cookie，这里传入一个字典，有 name、domain 和 value 等内容。接下来，再次获取所有的 Cookies。可以发现，结果就多了这一项新加的 Cookie。最后，调用 delete_all_cookies() 方法删除所有的 Cookies。再重新获取，发现结果就为空了。

控制台的输出如下：

```python
[{'secure': False, 'value': '"NGM1ZTM5NDAwMWEyNDQwNDk5ODlkZWY3OTkxY2I1NDY=|1491614191|236e34291a6f417bfbb517888849ea519ac366d1"', 'domain': '.zhihu.com', 'path': '/', 'httpOnly': False, 'name': 'l_cap_id', 'expiry': 1494196191.413418}]
[{'secure': False, 'value': 'germey', 'domain': '.www.zhihu.com', 'path': '/', 'httpOnly': False, 'name': 'name'}, {'secure': False, 'value': '"NGM1ZTM5NDAwMWEyNDQwNDk5ODlkZWY3OTkxY2I1NDY=|1491614191|236e34291a6f417bfbb517888849ea519ac366d1"', 'domain': '.zhihu.com', 'path': '/', 'httpOnly': False, 'name': 'l_cap_id', 'expiry': 1494196191.413418}]
[]
```

通过以上方法来操作 Cookies 还是非常方便的。

### 11.14  选项卡管理

在访问网页的时候，会开启一个个选项卡。在 Selenium 中，我们也可以对选项卡进行操作。示例如下：

```python
import time
from selenium import webdriver

browser = webdriver.Chrome()
browser.get('https://www.baidu.com')
browser.execute_script('window.open()')
print(browser.window_handles)
browser.switch_to_window(browser.window_handles[1])
browser.get('https://www.taobao.com')
time.sleep(1)
browser.switch_to_window(browser.window_handles[1])
browser.get('https://python.org')
```
控制台输出如下：
```python
['CDwindow-4f58e3a7-7167-4587-bedf-9cd8c867f435', 'CDwindow-6e15f176-6d77-453a-a36c-32baacc447df']
```

首先访问了百度，然后调用了 execute_script() 方法，这里传入 window.open() 这个 JavaScript 语句新开启一个选项卡。接下来，我们想切换到该选项卡。这里调用 window_handles 属性获取当前开启的所有选项卡，返回的是选项卡的代号列表。要想切换选项卡，只需要调用 switch_to_window() 方法即可，其中参数是选项卡的代号。这里我们将第二个选项卡代号传入，即跳转到第二个选项卡，接下来在第二个选项卡下打开一个新页面，然后切换回第一个选项卡重新调用 switch_to_window() 方法，再执行其他操作即可。


### 11.15  异常处理

在使用 Selenium 的过程中，难免会遇到一些异常，例如超时、节点未找到等错误，一旦出现此类错误，程序便不会继续运行了。这里我们可以使用 try except 语句来捕获各种异常。

首先，演示一下节点未找到的异常，示例如下：

```python
from selenium import webdriver

browser = webdriver.Chrome()
browser.get('https://www.baidu.com')
browser.find_element_by_id('hello')
```

这里首先打开百度页面，然后尝试选择一个并不存在的节点，此时就会遇到异常。

运行之后控制台的输出如下：

```python
NoSuchElementException Traceback (most recent call last)
<ipython-input-23-978945848a1b> in <module>()
      3 browser = webdriver.Chrome()
      4 browser.get('https://www.baidu.com')
----> 5 browser.find_element_by_id('hello')
```
可以看到，这里抛出了 NoSuchElementException 异常，这通常是节点未找到的异常。为了防止程序遇到异常而中断，我们需要捕获这些异常，示例如下：
```python
from selenium import webdriver
from selenium.common.exceptions import TimeoutException, NoSuchElementException

browser = webdriver.Chrome()
try:
    browser.get('https://www.baidu.com')
except TimeoutException:
    print('Time Out')
try:
    browser.find_element_by_id('hello')
except NoSuchElementException:
    print('No Element')
finally:
    browser.close()
```

这里我们使用 try except 来捕获各类异常。比如，我们对 find_element_by_id() 查找节点的方法捕获 NoSuchElementException 异常，这样一旦出现这样的错误，就进行异常处理，程序也不会中断了。

控制台的输出如下：

```python
No Element
```

关于更多的异常类，可以参考官方文档：：[http://selenium-python.readthedocs.io/api.html#module-selenium.common.exceptions](http://selenium-python.readthedocs.io/api.html#module-selenium.common.exceptions)。

现在，我们基本对 Selenium 的常规用法有了大体的了解。使用 Selenium，处理 JavaScript 不再是难事。 


