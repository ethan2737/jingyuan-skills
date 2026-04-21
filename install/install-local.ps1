[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [switch]$Force,
  [string]$HomeRoot
)

$ErrorActionPreference = 'Stop'

function Get-FullPath {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.Path]::GetFullPath($Path)
}

function Assert-ExpectedPath {
  param(
    [Parameter(Mandatory = $true)][string]$Actual,
    [Parameter(Mandatory = $true)][string]$Expected
  )

  $actualFull = Get-FullPath -Path $Actual
  $expectedFull = Get-FullPath -Path $Expected
  if ($actualFull -ne $expectedFull) {
    throw "Safety check failed. Refusing to operate on '$actualFull'; expected '$expectedFull'."
  }
}

function New-MarketplaceEntry {
  return [ordered]@{
    name = 'jingyuan'
    source = [ordered]@{
      source = 'local'
      path = './plugins/jingyuan'
    }
    policy = [ordered]@{
      installation = 'AVAILABLE'
      authentication = 'ON_INSTALL'
    }
    category = 'Productivity'
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$sourcePlugin = Join-Path $projectRoot 'plugins\jingyuan'

if (-not (Test-Path -LiteralPath $sourcePlugin)) {
  throw "Source plugin directory not found: $sourcePlugin"
}

$defaultCodexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$installRoot = if ([string]::IsNullOrWhiteSpace($HomeRoot)) { $defaultCodexRoot } else { $HomeRoot }
$installRoot = Get-FullPath -Path $installRoot
$targetPlugin = Join-Path $installRoot 'plugins\jingyuan'
$expectedPlugin = Join-Path $installRoot 'plugins\jingyuan'
$marketplacePath = Join-Path $installRoot '.agents\plugins\marketplace.json'

Assert-ExpectedPath -Actual $targetPlugin -Expected $expectedPlugin

if (Test-Path -LiteralPath $targetPlugin) {
  if (-not $Force) {
    throw "Target plugin already exists: $targetPlugin. Use -Force to replace JingYuan."
  }
  if ($PSCmdlet.ShouldProcess($targetPlugin, 'Remove existing JingYuan plugin')) {
    Remove-Item -LiteralPath $targetPlugin -Recurse -Force
  }
}

$targetParent = Split-Path -Parent $targetPlugin
if (-not (Test-Path -LiteralPath $targetParent)) {
  if ($PSCmdlet.ShouldProcess($targetParent, 'Create plugin parent directory')) {
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
  }
}

if ($PSCmdlet.ShouldProcess($targetPlugin, 'Install JingYuan plugin')) {
  Copy-Item -LiteralPath $sourcePlugin -Destination $targetPlugin -Recurse
}

$marketplaceDir = Split-Path -Parent $marketplacePath
if (-not (Test-Path -LiteralPath $marketplaceDir)) {
  if ($PSCmdlet.ShouldProcess($marketplaceDir, 'Create marketplace directory')) {
    New-Item -ItemType Directory -Path $marketplaceDir -Force | Out-Null
  }
}

$marketplace = $null
if (Test-Path -LiteralPath $marketplacePath) {
  $raw = Get-Content -Raw -Encoding UTF8 -LiteralPath $marketplacePath
  if (-not [string]::IsNullOrWhiteSpace($raw)) {
    $marketplace = $raw | ConvertFrom-Json
  }
}

if ($null -eq $marketplace) {
  $marketplace = [pscustomobject][ordered]@{
    name = 'local'
    interface = [pscustomobject][ordered]@{
      displayName = 'Local Plugins'
    }
    plugins = @()
  }
}

if ($null -eq $marketplace.interface) {
  $marketplace | Add-Member -NotePropertyName interface -NotePropertyValue ([pscustomobject][ordered]@{ displayName = 'Local Plugins' })
}
if ($null -eq $marketplace.plugins) {
  $marketplace | Add-Member -NotePropertyName plugins -NotePropertyValue @()
}

$existing = @($marketplace.plugins | Where-Object { $_.name -ne 'jingyuan' })
$entry = [pscustomobject](New-MarketplaceEntry)
$marketplace.plugins = @($existing + $entry)

if ($PSCmdlet.ShouldProcess($marketplacePath, 'Create or update JingYuan marketplace entry')) {
  $json = $marketplace | ConvertTo-Json -Depth 20
  Set-Content -LiteralPath $marketplacePath -Value $json -Encoding UTF8
}

if ($WhatIfPreference) {
  Write-Host "JingYuan plugin install planned for: $targetPlugin"
  Write-Host "Marketplace update planned for: $marketplacePath"
} else {
  Write-Host "JingYuan plugin installed to: $targetPlugin"
  Write-Host "Marketplace updated at: $marketplacePath"
}
Write-Host 'Restart or refresh Codex, then invoke skills with $jingyuan-*.' 
