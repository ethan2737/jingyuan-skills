# JingYuan Windows PowerShell 命令基准

## 总原则

JingYuan 默认面向 Windows 用户。所有安装、进程管理、中断服务、验证和审计命令默认使用 PowerShell。除用户明确要求外，不把 Bash、sh、pkill、lsof、grep、find、chmod、sudo 等 Unix 命令作为主流程。

## 中断和进程管理

当前终端中的前台服务优先使用 `Ctrl+C` 中断。若工具环境无法交互发送中断，再按端口或进程名停止。

检查端口：

```powershell
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
```

停止指定端口：

```powershell
$pids = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique
$pids | ForEach-Object { Stop-Process -Id $_ -Force }
```

停止 Node / Electron：

```powershell
Get-Process -Name node,electron -ErrorAction SilentlyContinue | Stop-Process -Force
```

等待端口释放：

```powershell
Start-Sleep -Seconds 2
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
```

## HTTP 验证

```powershell
Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:3000' -TimeoutSec 10
```

## 文件和隐私审计

检查构建目录是否存在：

```powershell
if (-not (Test-Path -LiteralPath $buildDir)) {
  throw "Build directory not found: $buildDir"
}
```

查找敏感文件：

```powershell
Get-ChildItem -LiteralPath $buildDir -Recurse -Force -File -ErrorAction Stop |
  Where-Object { $_.Name -match '(^\.env|credentials|\.pem$|\.key$|\.db$|\.db-shm$|\.db-wal$)' }
```

查找路径泄露和硬编码密钥：

```powershell
Get-ChildItem -LiteralPath $buildDir -Recurse -Force -File -ErrorAction SilentlyContinue |
  Select-String -ErrorAction SilentlyContinue `
    -Pattern 'C:\\Users\\|[A-Z]:\\|/Users/|sk-ant-|sk-proj-|ANTHROPIC_API_KEY|OPENAI_API_KEY|password\s*='
```

## 副作用操作

以下操作必须先展示目标、命令和影响范围，并取得用户明确确认：

- `git push`
- `git push --tags`
- 创建或删除 GitHub Release
- 生产部署
- `npm publish`
- `npm unpublish`
- 删除文件、重置仓库、强制覆盖
