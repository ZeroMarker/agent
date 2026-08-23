# Playwright 使用笔记

> 官网：https://playwright.dev/
> 官方文档：https://playwright.dev/docs/intro
> 仓库：https://github.com/microsoft/playwright
> 一句话：Playwright 是微软出品的跨浏览器自动化框架，同一套 API 驱动 Chromium / Firefox / WebKit；内置自动等待 + Locator 定位器模型，与 Selenium 需要手写显式等待是核心差异。

## 1. 定位与选型

| 维度 | Playwright | Selenium | Puppeteer |
| --- | --- | --- | --- |
| 浏览器支持 | Chromium / Firefox / WebKit | 最广（含老 IE） | 仅 Chromium |
| 自动等待 | 内置 actionability 检查 | 需显式 WebDriverWait | 需手动 waitFor* |
| 定位器 | Locator 惰性重试模型 | By.* / CSS / XPath | $ / $$ + 手动等待 |
| 多用户/多标签隔离 | BrowserContext | 无等价抽象 | 无 |
| 测试运行器 | 内置 Playwright Test | pytest-selenium 等 | 需自配 |
| 录制/回放/调试 | codegen + Trace Viewer | Selenium IDE | 无官方 |
| 语言绑定 | Python / JS / Java / .NET | 多语言 | JS 为主 |

选型建议：

- 新项目（测试 + 多浏览器）→ Playwright，一套代码覆盖三引擎。
- 需要最大浏览器兼容（老 IE 等）→ Selenium。
- 仅 Chromium 且已有 Puppeteer 存量代码 → 维持 Puppeteer，否则新写优先 Playwright。
- 与 browser-use 的关系：browser-use 是构建在浏览器自动化之上的 **Agent 框架**，底层用 Playwright 驱动；裸操浏览器、做反爬抓取、写 e2e 测试直接用 Playwright。

## 2. 核心概念

### 三层对象模型

- **Browser**：浏览器进程。`launch()` 启动，`headless=False` 有头运行。
- **BrowserContext**：隔离的会话环境。每个 context 有独立 cookie、localStorage、缓存、UA。多账号/多用户必须开多个 context，而不是多个 tab。
- **Page**：一个标签页，`context.new_page()` 创建。

### 自动等待（auto-wait）

操作前 Playwright 自动等待元素满足可操作条件：可见、已附加 DOM、稳定（不再移动）、可接收事件、enabled。不需要手写 `sleep` / `WebDriverWait`。

- 等不到则抛 `TimeoutError`，默认超时 30s（可传 `timeout` 覆盖）。
- 判断状态用 `expect()`（轮询直到通过），不要用 `is_visible()` 当等待手段——它不重试，只查一次。

### Locator 定位器

- **惰性**：创建时不查询 DOM，每次操作时重新解析 → 页面重渲染后依然有效。
- 可链式：`page.get_by_role("row").filter(has_text=...)`。
- 优先语义定位（role / label / placeholder / text / test id），CSS/XPath 兜底，避免绑定易变的 class。

## 3. 安装

```bash
pip install playwright                # Python
npm i -D playwright                   # Node（只要驱动不带浏览器用 playwright-core）
playwright install chromium           # 下载浏览器二进制；Python 下写 python -m playwright install
playwright install --with-deps chromium   # 同时装系统依赖（Ubuntu 等）
```

- 国内网络慢/失败：走镜像

  ```bash
  export PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright/
  playwright install chromium
  ```

- 复用系统已有 Chrome/Edge：`chromium.launch(channel="chrome")`，或 `playwright-core` + `PLAYWRIGHT_EXECUTABLE_PATH` 指到现有浏览器，免下载。
- 浏览器按版本独立装到 `~/.cache/ms-playwright/`；升级 playwright 库后要重新 `install`，否则报 `Executable doesn't exist`。

## 4. 常用 API 速查（Python）

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("https://example.com")
    # ...
    browser.close()
```

### 定位器

```python
page.get_by_role("button", name="登录")      # 语义定位，最推荐
page.get_by_label("用户名")                    # 表单 label
page.get_by_placeholder("请输入密码")
page.get_by_text("已提交")                     # 文本
page.get_by_test_id("submit-btn")             # 默认 data-testid
page.locator("div").filter(has_text="xx")     # 链式过滤
page.locator("div").first() / .nth(2) / .last()
page.locator("xpath=//div[@id='a']")          # XPath 兜底
```

### 交互

```python
locator.click()                 # 自动等待 + 滚动到可见
locator.dblclick() / .rightclick()
locator.fill("text")            # 清空再输入
locator.press("Enter")          # 键盘，可组合 "Control+A"
locator.select_option("v")      # <select>
locator.check() / .uncheck()
locator.hover()
locator.set_input_files("a.png")   # 文件上传
page.keyboard.type("...")       # 逐字输入（慢）
page.mouse.wheel(0, 500)        # 滚轮
```

### 读取与断言

```python
page.title() / page.url
locator.inner_text() / .text_content()
locator.count() / .is_visible() / .is_enabled()
locator.get_attribute("href")

from playwright.sync_api import expect
expect(locator).to_be_visible(timeout=10_000)
expect(page).to_have_title("...")
expect(locator).to_have_text("...")       # 精确文本
expect(locator).to_contain_text("...")
```

### 截图与 PDF

```python
page.screenshot(path="shot.png", full_page=True)   # full_page 截整页
locator.screenshot(path="el.png")                  # 只截元素
page.pdf(path="a.pdf")                             # 仅 Chromium 且 headless
```

### 登录态复用（Agent 场景关键）

```python
# 保存
context.storage_state(path="state.json")
# 复用：免去每次登录
context = browser.new_context(storage_state="state.json")
```

cookie / localStorage / sessionStorage 全量保存。登录过期或被反爬踢掉后失效，需重登再保存一次。

### 多页面 / 弹窗 / 下载

```python
with page.expect_popup() as p:
    page.click("a[target=_blank]")
new_page = p.value

with page.expect_download() as d:
    page.click("a[download]")
d.value.save_as("file.zip")
```

### 网络拦截与 Mock

```python
def block(route):
    if route.request.resource_type == "image":
        route.abort()              # 跳过图片提速
    else:
        route.continue_()

page.route("**/*", block)
page.wait_for_response("**/api/data")   # 等接口返回
```

### 反爬与指纹

```python
browser = p.chromium.launch(
    headless=False,                              # headless 特征易被检测
    args=["--disable-blink-features=AutomationControlled"],
)
context = browser.new_context(
    user_agent="Mozilla/5.0 ... Chrome/1xx",     # 真实 UA
    locale="zh-CN",
    viewport={"width": 1280, "height": 720},
)
```

- 指纹随机化 / stealth 补丁：本仓库 [`browser/mcp_web_search`](../browser/index.md) 就是 Playwright + playwright-stealth 做 Google 搜索反爬，CLI / MCP 两种模式。
- 需要大量不重复指纹时：随机 UA + 随机 viewport + 随机时区，每次新建 context。

### 异步版本

Python 有 `async_playwright`（同 API，await 风格）；Node 全异步。两种语言 API 一一对应，官方文档互相可查。

## 5. 测试运行器

- Python：`pytest-playwright`，`page` fixture 自动管理 browser/context/page；Node：`npx playwright test`。
- 并行执行（默认多 worker）、`--shard` 分片、失败自动重试、HTML 报告。
- trace：失败自动录 trace（`trace: "on-first-retry"`），`playwright show-trace` 查看每个操作的 DOM 快照与网络。
- `npx playwright test --ui` 可视化调试。

## 6. 配套工具

- **codegen 录制**：`python -m playwright codegen https://example.com` → 操作页面自动生成脚本，生成后改造即可。
- **Trace Viewer**：`playwright show-trace trace.zip`。
- **远程/无头服务器**：浏览器可跑在远端，客户端用 `PLAYWRIGHT_WS_ENDPOINT`（launchServer）或 `PLAYWRIGHT_CDP_ENDPOINT`（连现有 Chrome）连接——本仓库 [`skills/open-websearch`](../skills/open-websearch/) 的 Playwright 模式即支持这几种连接方式。

## 7. 常见排障

| 报错/现象 | 原因 | 处理 |
| --- | --- | --- |
| `Executable doesn't exist` | 浏览器未下载或版本不匹配 | `playwright install chromium`；升级库后重装 |
| 启动报缺系统库 | 缺 OS 依赖 | `playwright install --with-deps chromium` |
| `TimeoutError` 等不到元素 | 自动等待失败 | 换更稳的定位器（get_by_role），检查元素是否被遮挡 / 在 iframe 内 |
| 页面检测到自动化 | headless 特征 / webdriver 标志 | 有头运行、真实 UA、stealth 补丁（见 §4 反爬） |
| 登录态丢失 | storage_state 过期 | 重新登录后重新保存 |
| 下载/安装浏览器慢或失败 | 网络问题 | PLAYWRIGHT_DOWNLOAD_HOST 镜像 + 代理 |
| 并发跑多个脚本资源占用高 | 每脚本一个 browser 进程 | 复用同一个 browser 实例，用多 context 隔离 |

- iframe 内容：`page.frame_locator("iframe[name=xx]")` 之后继续定位。
- shadow DOM：locator 默认可穿透；CSS 用 pierce 引擎。

## 8. 参考链接

- 官方文档：https://playwright.dev/docs/intro
- Python API：https://playwright.dev/python/docs/api/class-playwright
- Trace Viewer：https://playwright.dev/docs/trace-viewer
- 本仓库相关：`browser/mcp_web_search`（Playwright + stealth 反爬搜索）、`skills/open-websearch`（Playwright 模式）
