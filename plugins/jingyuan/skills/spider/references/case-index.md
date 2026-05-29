# Spider 案例代码索引

案例源码目录：`E:\Project\Spider`

这个目录作为外部实战案例库使用，不复制源码到 skill。读取案例代码前先确认任务路线，并只打开相关文件；案例中可能存在旧 Cookie、token、账号标识或本地路径，回答和改写代码时必须脱敏并改为占位符或环境变量。

## 使用顺序

1. 先用 `SKILL.md` 的 Crawler Classification 判断路线。
2. 再在本索引中找相近案例。
3. 只读取对应案例目录的 `网站分析`、`.py`、`.js` 或 Scrapy 模块。
4. 不直接复用案例中的 Cookie、token、账号、绝对输出路径和请求频率。

## 路线到案例目录

| Route | Case path | Notes |
| --- | --- | --- |
| Static page / Ajax | `01_网站/01_非逆向网站/` | requests、aiohttp、分页、HTML 解析、异步下载。 |
| JS reverse / encryption | `01_网站/02_逆向网站/` | 每个案例通常含网站分析、JS 加密逻辑、Python 请求复现。 |
| App | `02_App/` | App 接口请求案例，通常需要结合抓包证据。 |
| Environment emulation | `03_supplement_env/` | Node.js 补 window/document/navigator 等浏览器环境。 |
| Scrapy | `04_Scrapy框架/` | Scrapy 项目结构、settings、items、pipelines、middlewares、spiders。 |
| Proxy pool | `05_免费IP代理池/` | 采集、Redis 存储、校验、Flask API、统一启动。 |
| Templates | `06_代码模板/` | JS proxy/hook 模板和学习笔记。 |

## 普通网站案例

- `01_网站/01_非逆向网站/01_极简壁纸.py` - 极简壁纸
- `01_网站/01_非逆向网站/02_桌面壁纸.py` - 桌面壁纸
- `01_网站/01_非逆向网站/03_猪八戒网站.py` - 猪八戒网站
- `01_网站/01_非逆向网站/04_大陆电影票房数据.py` - 大陆电影票房数据
- `01_网站/01_非逆向网站/05_豆瓣Top250排行榜.py` - 豆瓣Top250排行榜
- `01_网站/01_非逆向网站/06_豆瓣分类电影排行榜.py` - 豆瓣分类电影排行榜
- `01_网站/01_非逆向网站/07_豆瓣最受欢迎的影评.py` - 豆瓣最受欢迎的影评
- `01_网站/01_非逆向网站/08_当当网图书信息.py` - 当当网图书信息
- `01_网站/01_非逆向网站/09_冶金信息网.py` - 冶金信息网
- `01_网站/01_非逆向网站/10_雪球网.py` - 雪球网
- `01_网站/01_非逆向网站/11_我爱电子书.py` - 我爱电子书
- `01_网站/01_非逆向网站/12_红楼梦全书下载.py` - 红楼梦全书下载
- `01_网站/01_非逆向网站/13_斗图下载.py` - 斗图下载
- `01_网站/01_非逆向网站/14_协程_明朝那些事儿.py` - 协程_明朝那些事儿
- `01_网站/01_非逆向网站/15_协程下载视频.py` - 协程下载视频
- `01_网站/01_非逆向网站/16_24节气时间表.py` - 24节气时间表
- `01_网站/01_非逆向网站/17_广东省公共资源交易平台.py` - 广东省公共资源交易平台

## 逆向网站案例

- `01_网站/02_逆向网站/1_网易云音乐/` - Python 请求复现、JS 加密/签名；文件：1-逆向分析, 2-核心参数加密逻辑.js, 3-请求下载音乐.py, 古老的RSA加密库.js
- `01_网站/02_逆向网站/10_网易有道翻译/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加解密逻辑.js, 3-数据请求.py
- `01_网站/02_逆向网站/11_空气质量分析平台/` - Python 请求复现、JS 加密/签名、Hook/本地替换；文件：1-网站分析, 2-本地替换Hook文件.js, 3-本地替换页面源代码.html, 4-加密解密逻辑.js, 5-请求数据.py
- `01_网站/02_逆向网站/12_观鸟中心/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/13_虚拟币/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-获取数据.py
- `01_网站/02_逆向网站/14_宝钢股份官网/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/15_企查查/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/16_建筑监管平台/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/17_吉林长春产权交易中心/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密与解密算法.js, 3-请求数据.py
- `01_网站/02_逆向网站/18_中国移动登录/` - JS 加密/签名；文件：1-网站分析, 2-加密算法.js
- `01_网站/02_逆向网站/19_考试宝/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密算法.js, 3-请求数据.py
- `01_网站/02_逆向网站/2_CBA官方网站/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/20_酷我音乐/` - JS 加密/签名；文件：1-网站分析, webpack.js
- `01_网站/02_逆向网站/21_掌上高考/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密算法.js, 3-请求数据.py
- `01_网站/02_逆向网站/22_国家医保服务平台/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密算法.js, 3-请求数据.py
- `01_网站/02_逆向网站/23_杭州服装批发网/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/24_剑鱼标讯/` - 网站分析；文件：1-网站分析
- `01_网站/02_逆向网站/25_爱问财/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-爱问财源码.js, 3-请求数据.py
- `01_网站/02_逆向网站/26_BOSS直聘/` - 网站分析；文件：拽神实现方案.py
- `01_网站/02_逆向网站/27_商标局/` - 网站分析；文件：拽神实现方案.py
- `01_网站/02_逆向网站/28_小红书/` - 网站分析；文件：拽神实现方案.py
- `01_网站/02_逆向网站/29_中文期刊服务平台/` - 网站分析；文件：拽神实现方案.py
- `01_网站/02_逆向网站/3_集思录登录/` - Python 请求复现、JS 加密/签名；文件：1_网站分析, 2-加密逻辑.js, 3-请求登录.py, code.jpg
- `01_网站/02_逆向网站/30_全国招标公告公示/` - Python 请求复现；文件：网站分析, 招标公告-请求.py
- `01_网站/02_逆向网站/31_华能电子商务-瑞数5/` - Python 请求复现、JS 加密/签名、补环境/运行验证；文件：1-网站分析, 2-核心算法.js, 3-请求数据.py, test.js
- `01_网站/02_逆向网站/32_建设库/` - JS 加密/签名；文件：sign签名逻辑.js, 网站分析
- `01_网站/02_逆向网站/33_猫眼电影/` - 网站分析；文件：练习.py, 猫眼.py
- `01_网站/02_逆向网站/34_网上房地产/` - 网站分析；文件：网站分析
- `01_网站/02_逆向网站/35_同花顺行情中心/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/36_抖音/` - Python 请求复现、补环境/运行验证；文件：1-网站分析, 2-补环境逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/37_拼多多/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-核心code.js, 3-请求数据.py
- `01_网站/02_逆向网站/38_欧治-瑞数5-补环境/` - Python 请求复现、JS 加密/签名、补环境/运行验证；文件：2-核心算法.js, 3-请求数据.py, demo.js, test.js
- `01_网站/02_逆向网站/39_慕课网/` - 网站分析；文件：imooc_crawler.py
- `01_网站/02_逆向网站/4_数位观察/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-解密逻辑.js, 3-获取数据.py
- `01_网站/02_逆向网站/5_合肥滨湖会展/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密解密逻辑.js, 3-获取数据.py
- `01_网站/02_逆向网站/6_中大网校模拟登录/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密逻辑.js, 3-请求登录.py, verify_code.png
- `01_网站/02_逆向网站/7_中国五矿集团/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密代码解析.js, 3-完整加密逻辑.js, 4-请求数据.py
- `01_网站/02_逆向网站/8_艺恩EnData/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加密逻辑.js, 3-请求数据.py
- `01_网站/02_逆向网站/9_七麦数据/` - Python 请求复现、JS 加密/签名；文件：1-网站分析, 2-加解密逻辑.js, 3-七麦数据.py

## App、补环境、Scrapy、代理池和模板

### 02_App
- `02_App/1-新快报/请求数据.py`

### 03_supplement_env
- `03_supplement_env/1_my_env/bom/groups.js`
- `03_supplement_env/1_my_env/bom/window.js`
- `03_supplement_env/1_my_env/core/groups.js`
- `03_supplement_env/1_my_env/core/proxy.js`
- `03_supplement_env/1_my_env/dom/document.js`
- `03_supplement_env/1_my_env/dom/groups.js`
- `03_supplement_env/1_my_env/groups.js`
- `03_supplement_env/2_target/groups.js`
- `03_supplement_env/2_target/result.js`
- `03_supplement_env/2_target/start.js`
- `03_supplement_env/2_target/target.js`
- `03_supplement_env/4_main.js`

### 04_Scrapy框架
- `04_Scrapy框架/__init__.py`
- `04_Scrapy框架/ZDwangxiao/__init__.py`
- `04_Scrapy框架/ZDwangxiao/runner.py`
- `04_Scrapy框架/ZDwangxiao/scrapy.cfg`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/__init__.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/items.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/middlewares.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/pipelines.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/settings.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/spiders/__init__.py`
- `04_Scrapy框架/ZDwangxiao/ZDwangxiao/spiders/ks.py`

### 05_免费IP代理池
- `05_免费IP代理池/step01_collections_ip.py`
- `05_免费IP代理池/step02_proxy_ip_redis.py`
- `05_免费IP代理池/step03_verify_ip.py`
- `05_免费IP代理池/step04_api接口.py`
- `05_免费IP代理池/step05_程序统一启动run.py`
- `05_免费IP代理池/使用方法.py`

### 06_代码模板
- `06_代码模板/proxy模板1.js`
- `06_代码模板/proxy模板2.js`

## 检索建议

- 找普通请求案例：`rg -n "requests|aiohttp|xpath|BeautifulSoup" E:\Project\Spider\01_网站\01_非逆向网站`
- 找登录/Cookie 案例：`rg -n "Session|cookie|login|登录" E:\Project\Spider\01_网站\02_逆向网站`
- 找签名/加密案例：`rg -n "sign|encrypt|decrypt|AES|RSA|MD5|SHA|CryptoJS" E:\Project\Spider\01_网站\02_逆向网站`
- 找补环境案例：`rg -n "window|document|navigator|proxy|vm2" E:\Project\Spider\03_supplement_env E:\Project\Spider\01_网站\02_逆向网站`
- 找 Scrapy 写法：`rg -n "Spider|Request|parse|pipeline|middleware" E:\Project\Spider\04_Scrapy框架`
