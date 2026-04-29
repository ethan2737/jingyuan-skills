---
name: release
description: 景元发布构建工作流。Use when Codex needs to package, build, release, or deploy a project after implementation and verification.
---

# JingYuan Release

`$jingyuan:release` 在实现和审查之后执行构建、打包、隐私审计、安装/部署验证和发布确认。它的目标是证明发布产物能安全交付，而不是证明 dev 模式能跑。

[任务]
    根据项目类型执行构建、打包、发布前检查、隐私审计、安装/部署验证、冒烟测试和回退准备。

[依赖检测]
    基础依赖：
    - 项目代码已存在 → 无代码则提示先调用 `$jingyuan:dev-builder`。
    - git 可用。
    - package.json 或项目对应构建配置存在。
    - 构建工具可用。

    渠道依赖：
    - 只打包不发布 → 不检测部署或 registry 认证。
    - Web 发布 → 检测目标平台 CLI 和登录状态。
    - CLI 发布 → 检测 npm 登录或二进制打包工具。
    - Desktop 发布 → 检测打包工具、签名/证书配置和目标平台限制。

    可选：
    - `docs/PRD/prd.md` → 用于核心功能冒烟测试。
    - `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` → 用于确认发布边界。

[第一性原则]
    **dev 测通不等于发布可用**：必须测试打包、安装或部署后的真实运行环境。
    **隐私是底线**：产物中不能包含数据库、session、密钥、Token、开发者路径或个人信息。
    **失败即停止**：构建、隐私审计、安装测试或冒烟测试失败时停止发布。
    **用户确认副作用**：push、tag、npm publish、GitHub Release、生产部署、unpublish 必须先展示目标、命令和影响范围，并取得确认。
    **联网优先**：打包、签名、部署、平台 CLI 兼容问题先查最新文档或已知问题。

[发布检查清单]
    [版本与工作区]
        - package version 已确认。
        - CHANGELOG 或发布说明已更新（如项目使用）。
        - 工作区无未提交改动，除非用户明确允许发布当前未提交状态。

    [构建验证]
        - 构建命令 exit code 为 0。
        - 产物目录存在，大小合理。
        - 无 MODULE_NOT_FOUND、缺资源、路径错误或构建警告中的阻塞项。

    [隐私审计]
        先确定构建产物目录：
        - Next.js：`.next/` 或 `out/`
        - Vite：`dist/`
        - Electron：`release/`、`out/`、`dist/win-unpacked/` 或项目实际目录
        - CLI：`dist/` 或 `build/`

        对产物目录检查：
        - `.env*`、credentials、`.pem`、`.key`。
        - `.db`、`.db-shm`、`.db-wal`、session、用户数据。
        - `C:\Users\`、`[A-Z]:\`、`/Users/`。
        - `sk-ant-`、`sk-proj-`、`ANTHROPIC_API_KEY`、`OPENAI_API_KEY`、`password\s*=`

    [依赖与安全]
        - npm audit 或项目等价安全检查无 critical 漏洞。
        - 环境变量在平台或安装环境配置，不硬编码进代码或产物。
        - .gitignore 覆盖本地数据和敏感文件。

[项目类型策略]
    **Web**
    1. 识别框架和构建命令。
    2. 构建并记录产物目录。
    3. 执行隐私审计和依赖安全检查。
    4. 配置生产环境变量。
    5. 用户确认后部署到 Vercel、Netlify、自托管或其他渠道。
    6. 访问生产 URL，检查页面加载、核心路由和 PRD 核心流程。

    **Desktop / Electron**
    1. 构建前端和主进程产物。
    2. 按目标平台打包，Windows 默认只打 Windows；跨平台必须用户明确要求。
    3. 对打包产物执行隐私审计。
    4. 指导用户从安装包安装到系统目录并启动。
    5. 安装后执行核心功能冒烟测试。

    **CLI**
    1. 构建 CLI 产物。
    2. 执行隐私审计。
    3. 本地或全局安装后验证命令可运行。
    4. 用户确认包名、版本、registry 和命令后发布。
    5. 发布后安装指定版本并复测核心命令。

[回退策略]
    - Web：使用平台 rollback 或重新部署上一个稳定版本。
    - Desktop：无法远程回退已分发安装包；修复后 bump 版本重新打包发布。
    - CLI：必要时 `npm deprecate`；严重问题在规则允许范围内展示 `npm unpublish` 命令并等待用户确认。

[工作流程]
    1. 检测项目类型：Web、Desktop、CLI 或混合项目。
    2. 询问目标：只打包，还是发布到指定渠道。
    3. 按目标渠道执行 [依赖检测]。
    4. 确认版本号和发布说明。
    5. 执行构建/打包，记录命令、exit code、产物目录和大小。
    6. 执行隐私审计、安全检查和依赖检查；失败则停止并报告。
    7. 执行安装/部署后验证和冒烟测试。
    8. 展示发布就绪摘要和具体副作用命令，等待用户确认。
    9. 用户确认后执行发布。
    10. 发布后验证；失败则执行 [回退策略]。

[输出格式]
    发布确认前输出：
    - 项目类型和版本。
    - 构建命令、exit code、产物目录和大小。
    - 隐私审计结果。
    - 安装/部署验证结果。
    - 冒烟测试覆盖项。
    - 准备执行的发布命令、目标和影响范围。
    - 回退方式。

[初始化]
    执行 [工作流程] 第 1 步。
