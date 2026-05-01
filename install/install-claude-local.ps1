[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet('user', 'project', 'local')]
  [string]$Scope = 'user',
  [switch]$Force,
  [string]$MarketplacePath
)

$ErrorActionPreference = 'Stop'

function Get-FullPath {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.Path]::GetFullPath($Path)
}

function Test-ClaudeCommand {
  $command = Get-Command claude -ErrorAction SilentlyContinue
  if ($null -eq $command) {
    throw "Claude Code CLI not found. Install Claude Code and ensure 'claude' is available on PATH."
  }
}

function Invoke-ClaudeCommand {
  param(
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $display = 'claude ' + ($Arguments -join ' ')
  if ($PSCmdlet.ShouldProcess($display, $Description)) {
    & claude @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Claude command failed with exit code ${LASTEXITCODE}: $display"
    }
  } else {
    Write-Host "What if: $display"
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$marketplaceRoot = if ([string]::IsNullOrWhiteSpace($MarketplacePath)) { $projectRoot } else { $MarketplacePath }
$marketplaceRoot = Get-FullPath -Path $marketplaceRoot
$marketplaceFile = Join-Path $marketplaceRoot '.claude-plugin\marketplace.json'
$pluginManifest = Join-Path $projectRoot 'plugins\jingyuan\.claude-plugin\plugin.json'

if (-not (Test-Path -LiteralPath $marketplaceFile)) {
  throw "Claude Code marketplace not found: $marketplaceFile"
}

if (-not (Test-Path -LiteralPath $pluginManifest)) {
  throw "Claude Code plugin manifest not found: $pluginManifest"
}

if ($WhatIfPreference) {
  if ($null -eq (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude Code CLI not found. Continuing because -WhatIf was specified."
  }
} else {
  Test-ClaudeCommand
}

Invoke-ClaudeCommand -Arguments @('plugin', 'validate', $projectRoot) -Description 'Validate JingYuan Claude Code marketplace and plugin'

if ($Force) {
  try {
    Invoke-ClaudeCommand -Arguments @('plugin', 'uninstall', 'jingyuan@jingyuan-local', '--scope', $Scope) -Description 'Uninstall existing JingYuan Claude Code plugin'
  } catch {
    Write-Warning "Existing JingYuan Claude Code plugin could not be uninstalled or was not installed: $($_.Exception.Message)"
  }
}

Invoke-ClaudeCommand -Arguments @('plugin', 'marketplace', 'add', $marketplaceRoot, '--scope', $Scope) -Description 'Add JingYuan Claude Code marketplace'
Invoke-ClaudeCommand -Arguments @('plugin', 'install', 'jingyuan@jingyuan-local', '--scope', $Scope) -Description 'Install JingYuan Claude Code plugin'

Write-Host "JingYuan Claude Code marketplace added from: $marketplaceRoot"
Write-Host "JingYuan Claude Code plugin installed at scope: $Scope"
Write-Host 'If Claude Code is already running, run /reload-plugins before invoking /jingyuan:* skills.'
