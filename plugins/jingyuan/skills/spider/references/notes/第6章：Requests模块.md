## 第6章：Requests模块

---

### 6.1 Requests模块介绍

Requests 是Python 中一个简洁、易用的 HTTP 客户端库，用于发送 HTTP/1.1 请求。它是对 Python 内置的`urllib`的封装，提供了更人性化的接口，支持以下核心功能：

- 发送 GET/POST 等 HTTP 请求
- 自动处理 URL 编码、会话、Cookies
- 支持文件上传、SSL验证、代理配置
- 内置JSON解析和超时处理

### 6.2 Requests基本用法

#### 6.2.1 安装方法

```python
# Pycharm -> Terminal
pip install requests  # 国外源
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple requests  # 国内清华源

# 测试，在pycharm中运行程序，如果没有报错，证明安装成功
print(requests.get)
#如果遇到 No attribute in module requests 的报错信息，你自己创建的py文件或者文件夹和第三方库重名了
```

#### 6.2.2 发送GET请求

`get` 为显示请求，请求的参数会拼接在连接中

```python
# ---------- get请求初体验 ----------
# 导入模块
import requests

# 基本get请求:获取百度页面源代码
response = requests.get("http://www.baidu.com")
response.encoding = "utf-8" # 解决乱码问题
response.encoding = response.apparent_encoding # 自动识别编码
print(response.text) # 拿到页面源代码

# ---------- 带参数的get请求 ----------
import requests

# 用户输入的参数
content = input("请输入你要检索的内容：")
# get为显示请求，请求的参数会拼接在连接中
url = f"http://www.sogou.com/web?query={content}"

# 处理简单的反爬，添加请求头
headers = {
    "user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
}
# 发送请求
resp = requests.get(url, headers=headers)
resp.encoding = "utf-8"
print(resp.text)
```

`requests` 处理多参数的 `get` 请求，可以将参数存放在一个字典中传递，但无论何种方式传递参数，最终都会拼接到`url`中显示在 `？`后面。`get`请求的参数可以在浏览器 `ntwork -> XHR -> Headers -> Query String Parameters` 里面找到。

```python
# 多参数的 get 请求

import requests

# get请求地址
url = "https://movie.douban.com/j/chart/top_list"
# get请求参数
params = {
    "type":"13",
    "interval":"100:90",
    "action":"",
    "start":"0",
    "limit":"20",
}
headers = {
    "user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
}
# 发送请求
resp = requests.get(url, params=params, headers=headers)
print(resp.url) 

# 最终请求的url是这样的：
# https://movie.douban.com/j/chart/top_list?type=13&interval=100%3A90&action=&start=0&limit=20
```

> 所以，在Payload中看到 Query String Parameters时，发送 get 请求，使用如下方法：
> requests.get(url,  params=my_params,  headers=请求头)

#### 6.2.3 POST请求

`post` 为隐式请求，参数不会拼接到`url`中，可以在浏览器 `ntwork -> XHR -> Headers -> Form Data` 里面找到参数

```python
import requests

# post请求地址
post_url = "https://fanyi.baidu.com/sug"

# 随请求发送的数据：字典类型
data = {
    "kw":input("请输入要翻译的内容：")
}

# 发送请求
resp = requests.post(post_url, data=data)
# print(resp.text)  # 文本使用text
print(resp.json()) # 返回的数据是json字符串则使用json()，方便处理数据
```

> 所以，在Payload中看到 Query String Parameters 或者 Form Data 或者同时存在时，发送 post 请求，使用如下方法：
> requests.post(url,  params=my_params,  data=my_formdata,  headers=请求头)



在爬虫生涯中总共会看到三种参数：

| 参数类型                | 请求方式 | 特点                                                         |
| ----------------------- | -------- | ------------------------------------------------------------ |
| Qurey String Parameters | get      | 参数会通过`?`拼接到`url`中                                   |
| From Data               | post     | 通过 `requests.post(data=data)`方式提交                      |
| Request Payload         | post     | 需要把参数字典转换成字符串提交，`requests.post(data=json.dumps(dict)`<br />并且在请求头中必须加入<br />`"contentType":"Application/json"` |



#### 6.2.4 响应对象

要重点掌握 `response.text`  是从响应中获取文本内容（自动解码）。`response.json()`  是响应的内容为JSON字符串，需要通过这种方式解析。

```python
import requests

response = requests.get("http://www.baidu.com")
print(response.text) # 响应体，str类型
print(response.request.headers) # 响应对应的请求头
print(response.status_code) # HTTP 状态码（200, 404 等）
print(response.headers) # 响应头（字典格式）
print(response.cookies)# 获取 Cookies
print(response.encoding)# 响应编码（如 'utf-8'）
print(response.content)# 二进制响应内容（如图片）
print(response.url) # 获取访问的url
print(response.json()) # 获取json数据，得到的内容为字典（一般为接口响应体的格式是json格式时使用此方法）
print(response.ok) # 如果状态码小于等于200，此时返回True；如果大于200，此时返回False
```

响应体的三种类型总结

| 类型             | 说明          | 作用                               |
| ---------------- | ------------- | ---------------------------------- |
| response.text    | 响应体是 str  | 获取的是文本内容，例如文字、HTML等 |
| response.content | 响应体是bytes | 下载的内容是图片、文件、视频等等   |
| response.json()  | 响应体是json  | 获取的数据是字典的形式             |



#### 6.2.5 会话管理

有时网站需要登陆后才能获取数据，而登录的用户信息都保存在`Cookies`中。可以使用`session`进行请求，`session`是一连贯的请求，在这个过程中`cookies`不会丢失：

- 第一步：登陆，获取cookies
- 第二步：带着cookies 请求目标网址
- 第三步：拿到目标数据

```python
# 第一种方式：重点掌握

import requests

# 登录url
url = "https://user.17k.com/www/bookshelf/"
# 第一步：创建会话
session = requests.session()
# 传入登录信息
data = {
    "loginName":"<REDACTED_CREDENTIAL>",
    "password":"<REDACTED_CREDENTIAL>",
}
# 第二步：访问登录url，传入参数登录，登录成功后，Cookies就会在session中
session.post(url, data=data)
# 第三部：用session请求目标网址
resp = session.get("https://user.17k.com/ck/author/shelf?page=1&appKey=2406394919")
print(resp.json())


# 第二种方式：先登录网站，获取到Cookies信息，传入请求头中
resp = requests.get(url, headers={"Cookie":"<REDACTED_SECRET>"})
print(resp.text)
```

#### 6.2.6 超时与代理

```python
# 设置超时时间（单位：秒）
resp = requests.get("http://www.baidu.com", timeout=3) # 3秒内没有响应则超时，抛出 Timeout 超时异常

# 使用IP代理
proxies = {
    "http":"http://10.10.1.10:3128",
    "https":"https://10.10.1.10:3128",
}
resp = requests.get("https://httbin.ort/ip", proxies=proxies)
resp.encoding = "utf-8"
print(resp.text)
```

免费的代理IP不稳定、不好找，所以使用的性价比不是很高。可以引入第三方的代理平台，比如：https://www.kuaidaili.com/ 。代理IP函数是连接第三方平台购买生成的`aipkey`

```python
# 快代理平台案例
def get_ip():
    """通过第三方API获取IP的函数"""
    # 第三方代理平台的api地址
    url = "https://dps.kdlapi.com/api/getdps/?secret_id=<REDACTED_SECRET>&signature=<REDACTED_SECRET>&num=10&pt=1&format=json&sep=1&dedup=1"
    # 对API发送请求
    resp = requests.get(url)
    ips = resp.json() # 获取到IP的json字符串
    for ip in ips["data"]["proxy_list"]: # 遍历每一个IP
        yield ip # 每循环一次，返回一个IP，逐一返回

def spider():
    """爬虫函数，抵用获取IP函数"""
    url = "http://www.baidu.com"
    while True:
        try: # 异常处理
            proxy_ip = next(gen) # 拿到代理IP
            proxy = {
                "http":"http://" + proxy_ip,
                "https":"https://" + proxy_ip,
            }
            resp = requests.get(url, proxies=proxy)
            resp.encoding = "utf-8"
            return resp.text
        except: # 抛出异常
            print("报错了……")

if __name__ == "__main__":
    gen = get_ip()  # gen就是代理IP的生成器
    for i in range(10): # 请求10次 
        spider()
```



#### 6.2.7 防盗链

Referer 防盗链是一种常见的反爬虫机制，用于防止网站资源被非法盗用。

##### 6.2.7.1 Referer防盗链的原理

- `Referer` 是HTTP请求头的一部分，表示当前请求是从哪个 url 跳转过来的，例如：用户从网页 A 点击链接跳转到网页 B，浏览器会自动在请求 B 的 HTTP 头中添加 `Referer: A`
- 服务器通过检查 `Referer`字段判断请求来源，如果`Referer`不属于白名单或者未设置，服务器可能拒绝请求（返回403错误）或者重定向到指定页面

##### 6.2.7.2 破解Referer防盗链的方法

- 手动设置`Referer` 请求头，模拟浏览器行为，按`F12` 切换到`Network`标签，查看发送的请求，在`Headers`中记录着`referer`的值
- 如果资源是通过 JavaScript 动态加载的，可以通过抓包工具（如 Fiddler 或 Charles）分析请求链路，找到真实的资源地址和对应的 `Referer`。

##### 6.2.7.3 破解梨视频防盗链案例

```python
"""
实现步骤：
1.拿到contId
2.拿到videoStatus返回的json -> srcURL
3.对srcURl里面的内容进行修整
4.下载视频

"""

import requests
# 拉取视频的网址
url = "https://www.pearvideo.com/video_1799764"
# 请求头
headers = {
    "user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
    "referer":url,
}


# 1.拿到contId
contId = url.split("_")[-1]
# 拼接videoStatus路径并请求，拿到返回的json
videoStatusUrl = f"https://www.pearvideo.com/videoStatus.jsp?contId={contId}"
# 2.拿到videoStatus返回的json -> srcURL
resp = requests.get(videoStatusUrl, headers=headers)
dic = resp.json()
srcUrl = dic["videoInfo"]["videos"]["srcUrl"]
systemTime = dic["systemTime"]
# 3.对srcURl里面的内容进行修整
srcUrl = srcUrl.replace(systemTime, f"cont-{contId}")
# 4.下载视频
with open("a.mp4", "wb") as f:
    f.write(requests.get(srcUrl).content)


```



