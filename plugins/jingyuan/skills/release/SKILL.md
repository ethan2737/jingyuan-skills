---
name: release
description: 景元发布构建工作流。Use when Codex needs to package, build, release, or deploy a project after implementation and verification.
---

# Codex 适配说明

- 本 Skill 从原 release-builder 迁移而来，正文保留原工作流内容并按 Codex 规则调整入口、路径和产物命名。
- 所有产品、设计、开发计划、反馈和进化类文档必须写入目标项目的 `docs/` 目录；不得在目标项目根目录直接生成旧文件名。
- 新入口使用 `$jingyuan:release`；旧斜杠命令仅作为历史语义参考。
- Claude 专属的 hooks/sub-agent 描述在 Codex 中按 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md` 和 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md` 执行。
- 执行前优先读取本插件的共享参考：`<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`。
- 本插件面向 Windows 用户，命令示例默认使用 PowerShell；除用户明确要求外，不使用 Unix 命令作为主流程。
- 将 `<JINGYUAN_PLUGIN_ROOT>` 解析为 `$env:CODEX_HOME\plugins\jingyuan`；如未设置 `CODEX_HOME`，则解析为 `$HOME\.codex\plugins\jingyuan`。

# 原工作流正文（Codex 路径适配版）


[任务]
    根据项目类型执行完整的构建-打包-测试-发布流程。
    确保发布产物：能安装、能运行、无隐私泄露、无安全漏洞。

[依赖检测]
    在需求收集之后、根据用户选择的发布渠道按需执行。

    基础检测：
    - 项目代码已存在 → 无代码则提示先调用 $jingyuan:dev-builder
    - git 可用
    - 构建工具可用
    - package.json 存在

    渠道检测：
    - 根据用户选择的发布渠道，检测该渠道所需的 CLI 工具和认证状态
    - 用户只打包不发布 → 不检测部署工具

    安装策略：
    - 缺失的工具由 Agent 自主判断安装方式并直接安装
    - 需要用户登录认证的操作，提示用户完成认证
    - 签名证书等用户专属资产缺失时，说明需要什么并引导用户准备

    可选：
    - docs/PRD/prd.md → 有则可对照功能做冒烟测试

[第一性原则]
    **dev 测通 ≠ 打包能用**：开发环境和打包后的运行时环境完全不同。路径不同、依赖打包方式不同、权限不同。必须从安装包测试，不能只测 dev 模式。
    **隐私是底线**：发布产物中绝不包含个人数据——数据库文件、session、API Key、开发者路径、用户名。没有例外，没有豁免。
    **安装后测试**：Desktop 从安装包安装到系统目录测试，CLI 全局安装后测试，Web 部署后在线测试。不从构建输出目录测试。
    **联网优先**：打包报错先 WebSearch 搜索，特别是 electron-builder、Vercel CLI 的版本兼容性和签名/公证问题。

[输出风格]
    **语态**：
    - 像发布工程师：按检查清单逐项执行，每步附结果
    - 失败就停，不跳过

    **原则**：
    - × 绝不在只测了 dev 模式后就说"可以发布了"
    - × 绝不跳过隐私审计
    - × 绝不在冒烟测试未通过时继续发布
    - ✓ 每步附证据（构建输出、grep 结果、测试截图）
    - ✓ 发现隐私泄露立刻停止并修复

    **典型表达**：
    - "pnpm build 通过，产物在 .next/ 下，总大小 45MB。"
    - "隐私审计：PowerShell 扫描发现构建产物中有 2 处 `C:\Users\` 开发者路径，停止发布，先修复。"
    - "DMG 安装到 /Applications 后从系统目录启动正常，核心功能验证通过。"

[文件结构]
    ```
    release/
    └── SKILL.md                           # 主 Skill 定义（本文件）
    ```

[发布检查清单]
    所有项目类型共用的检查项。

    [版本管理]
        - 确认 package.json 的 version 字段已更新（语义化版本）
        - 确认 CHANGELOG 已更新（如有）
        - 工作区干净（git status 无未提交的改动）

    [构建验证]
        - 构建命令零错误完成
        - 产物文件存在且大小合理，Agent 根据项目类型和依赖规模判断预期范围，异常偏大则排查是否打包了不该打包的东西

    [隐私审计]（绝对底线）
        先确定构建产物目录（不同项目不同）：
        - Next.js → .next/ 或 out/
        - Vite → dist/
        - Electron → release/、out/、dist/win-unpacked/ 或项目实际 Windows 打包目录
        - CLI → dist/ 或 build/

        然后对构建产物目录执行 PowerShell 检查：
        ```powershell
        $buildDir = '[BUILD_DIR]'
        if (-not (Test-Path -LiteralPath $buildDir)) {
          throw "Build directory not found: $buildDir"
        }

        Get-ChildItem -LiteralPath $buildDir -Recurse -Force -File -ErrorAction Stop |
          Where-Object { $_.Name -match '(^\.env|credentials|\.pem$|\.key$|\.db$|\.db-shm$|\.db-wal$)' }

        Get-ChildItem -LiteralPath $buildDir -Recurse -Force -File -ErrorAction SilentlyContinue |
          Select-String -ErrorAction SilentlyContinue `
            -Pattern 'C:\\Users\\|[A-Z]:\\|/Users/|sk-ant-|sk-proj-|ANTHROPIC_API_KEY|OPENAI_API_KEY|password\s*='
        ```
        发现任何一项 → 立刻停止，修复后重新构建。

    [依赖完整性]
        - npm audit 无 critical 漏洞
        - 构建过程无 MODULE_NOT_FOUND 错误

    [Git 检查]
        - git author 不暴露个人信息
        - .gitignore 覆盖所有数据文件（.env*, *.db, .forge-data/）

[发布策略]
    根据项目类型选择对应的发布流程。

    **Web 项目发布**
    1. 构建
       Agent 根据项目使用的框架和版本，确定正确的构建命令和产物目录。不同框架版本的构建方式可能不同，执行前先检查项目配置。
    2. 隐私审计：执行 [隐私审计] 检查清单
    3. 配置生产环境变量
       - Vercel：`vercel env add [NAME]` 或在 Vercel 控制台设置
       - Netlify：在 netlify.toml 或控制台设置
       - 确认 API Key 等敏感变量已在平台配置，不在代码中
    4. 部署
       - Vercel：`vercel --prod`
       - Netlify：`netlify deploy --prod --dir=[BUILD_DIR]`
       - 静态托管：提醒用户上传 [BUILD_DIR] 到托管服务
       - 记录部署 URL
    5. 在线验证：访问部署 URL，确认页面可加载、无白屏
    6. 冒烟测试：如有 docs/PRD/prd.md → 对照核心功能列表逐项测试

    **Desktop 项目发布（Electron，默认 Windows）**
    1. 构建：`pnpm build` → 验证前端产物
    2. 打包
       - Windows 默认执行：`pnpm package:win`（或项目实际 Windows 打包命令）
       - 如需 macOS / Linux，先确认用户明确要求跨平台打包，再执行对应命令
    3. 隐私审计：执行 [隐私审计]，检查打包产物目录
    4. 安装测试（提醒用户操作）
       - Windows："请运行安装程序，从开始菜单启动应用"
       - macOS / Linux：仅在用户明确要求对应平台时提供指引
       - 输出指引后暂停，等待用户回复启动是否成功
       - 用户确认成功 → 继续冒烟测试
       - 用户报告失败 → 排查问题后重新打包
    5. 功能冒烟测试
       - 如有 docs/PRD/prd.md → 对照核心功能列表逐项测试
       - 如无 → 测试应用能正常打开、主要页面能加载、核心操作能执行
       - 如有 Playwright → 自动化测试关键流程

    **CLI 项目发布**
    1. 构建：`pnpm build` → 验证产物
    2. 隐私审计：执行 [隐私审计] 检查清单
    3. 发布
       - npm：确认 npm 登录（`npm whoami`），展示包名、版本和 `npm publish` 命令，取得用户明确确认后发布
       - 二进制：使用 pkg 或 esbuild 打包成可执行文件
    4. 安装测试：`npm install -g [package-name]` → 验证命令可运行
    5. 功能冒烟测试：核心命令逐个执行，验证输出正确

[回退策略]
    发布后发现问题时的回退方式：

    **Web**：
    - Vercel：`vercel rollback` 或在控制台回退到上一个部署
    - Netlify：在控制台选择上一个成功部署恢复
    - 其他：重新部署上一个版本的构建产物

    **Desktop**：
    - 无法远程回退已分发的安装包
    - 修复后重新打包 → 更新版本号 → 重新发布
    - 如有 GitHub Release → 删除有问题的 release，上传新版

    **CLI**：
    - `npm deprecate [package]@[version] "known issue, please use [new-version]"`
    - 严重问题：展示包名、版本、影响范围和 `npm unpublish [package]@[version]` 命令，取得用户明确确认后执行（72 小时内）
    - 修复后 bump 版本号重新 publish

[工作流程]
    [第一步：需求收集]
        先问清楚再动手：

        1. 检测项目类型（自动）
           扫描项目结构判断：
           - 有 electron-builder 配置 → Desktop
           - 有 next.config / vite.config + 无 electron → Web
           - 有 bin 字段 in package.json + 无前端框架 → CLI
           - 混合类型（如 Electron + Next.js）→ Desktop
           - 无法判断 → 询问用户

        2. 问目标
           "你想打包还是发布？
            - **打包**：只生成构建产物/安装包，不部署上线
            - **发布**：构建 + 部署上线 / 发布到 registry"

        3. 问渠道（如果是发布）
           Web 项目："你想部署到哪里？Vercel / Netlify / 自托管服务器 / 其他？"
           CLI 项目："发布到 npm？还是打成二进制分发？"
           Desktop 项目："上传到 GitHub Release？还是其他分发渠道？"

        4. 问平台（如果是 Desktop）
           "打包哪些平台？macOS / Windows / Linux / 全平台？"

        收集完毕后，根据用户回答执行 [依赖检测]（只检测实际需要的工具）。

    [第二步：版本确认]
        读取 package.json version
        询问用户是否需要更新版本号
        如需更新 → 修改 package.json → 提交

    [第三步：构建]
        执行构建命令（根据项目类型选择正确命令）
        验证构建产物存在且无错误
        如有打包步骤（Desktop）→ 执行打包
        记录构建产物目录路径

    [第四步：隐私审计]
        用第三步记录的实际产物目录执行 [隐私审计] 检查清单
        任何一项失败 → 停止，报告问题，等待修复
        全部通过 → 继续

    [第五步：安装测试]
        Web → 部署后访问 URL
        Desktop → 提醒用户从安装包安装到系统目录并启动（AI 无法操作 DMG 安装）
        CLI → 全局安装后运行

    [第六步：冒烟测试]
        根据项目类型和 docs/PRD/prd.md（如有）测试核心功能
        如有 Playwright → 自动化测试关键流程
        每项测试附结果

    [第七步：发布确认]
        向用户汇报所有测试结果：
        "🚀 **发布就绪检查**

         **项目类型**：[Web / Desktop / CLI]
         **版本**：[version]
         **构建**：✅ 通过，产物 [BUILD_DIR]，大小 [SIZE]
         **隐私审计**：✅ 无泄露
         **安装测试**：✅ [安装方式] 启动正常
         **冒烟测试**：✅ [X/Y] 项通过

         确认发布？"

        用户逐项确认后才执行对应操作：
        - Git tag / push：展示 tag、远程地址、分支和 `git push --tags`
        - GitHub Release：展示 release 名称、tag、上传文件列表
        - Web 生产部署：展示部署平台、项目、环境和部署命令
        - CLI 发布：展示包名、版本和 `npm publish`
        - Desktop 分发：展示安装包路径、版本和上传目标

    [第八步：发布后验证]
        - Web → 再次访问生产 URL，确认可用
        - CLI → `npm install -g [name]@[version]` 安装最新版验证
        - Desktop → 确认用户安装测试通过
        - 如有问题 → 执行 [回退策略]

[初始化]
    执行 [第一步：需求收集]






