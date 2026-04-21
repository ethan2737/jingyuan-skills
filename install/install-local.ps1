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

function Read-TextFile {
  param([Parameter(Mandatory = $true)][string]$Path)

  $reader = [System.IO.StreamReader]::new($Path, [System.Text.UTF8Encoding]::new($false, $true), $true)
  try {
    return $reader.ReadToEnd()
  } finally {
    $reader.Dispose()
  }
}

function Write-Utf8NoBomFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Value
  )

  $encoding = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function ConvertTo-TomlBasicString {
  param([Parameter(Mandatory = $true)][string]$Value)

  return ($Value | ConvertTo-Json -Compress)
}

function ConvertTo-CodexMarketplaceSourcePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $fullPath = Get-FullPath -Path $Path
  if ($IsWindows -or $env:OS -eq 'Windows_NT') {
    if ($fullPath -match '^[A-Za-z]:\\' -and -not $fullPath.StartsWith('\\?\')) {
      return "\\?\$fullPath"
    }
  }
  return $fullPath
}

function Remove-TomlTableBlock {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content,
    [Parameter(Mandatory = $true)][string]$Header
  )

  $pattern = '(?ms)^' + [regex]::Escape($Header) + '\s*\r?\n.*?(?=^\[|\z)'
  return [regex]::Replace($Content, $pattern, '').TrimEnd()
}

function Update-CodexConfig {
  param(
    [Parameter(Mandatory = $true)][string]$InstallRoot
  )

  $configPath = Join-Path $InstallRoot 'config.toml'
  $configDir = Split-Path -Parent $configPath
  if (-not (Test-Path -LiteralPath $configDir)) {
    if ($PSCmdlet.ShouldProcess($configDir, 'Create Codex config directory')) {
      New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
  }

  $content = ''
  if (Test-Path -LiteralPath $configPath) {
    $content = Read-TextFile -Path $configPath
  }

  $content = Remove-TomlTableBlock -Content $content -Header '[plugins."jingyuan@local"]'
  $content = Remove-TomlTableBlock -Content $content -Header '[plugins."jingyuan@jingyuan-local"]'
  $content = Remove-TomlTableBlock -Content $content -Header '[marketplaces.local]'
  $content = Remove-TomlTableBlock -Content $content -Header '[marketplaces.jingyuan-local]'

  $sourcePath = ConvertTo-CodexMarketplaceSourcePath -Path $InstallRoot
  $source = ConvertTo-TomlBasicString -Value $sourcePath
  $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  $block = @"

[marketplaces.local]
last_updated = "$timestamp"
source_type = "local"
source = $source
"@

  $nextContent = ($content.TrimEnd() + $block + [Environment]::NewLine).TrimStart()
  if ($PSCmdlet.ShouldProcess($configPath, 'Update Codex local marketplace config')) {
    Write-Utf8NoBomFile -Path $configPath -Value $nextContent
  }

  return $configPath
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

function Remove-ObsoleteSkillDiscoveryEntries {
  param(
    [Parameter(Mandatory = $true)][string]$CodexRoot,
    [Parameter(Mandatory = $true)][string]$UserHome,
    [Parameter(Mandatory = $true)][string[]]$MirrorSkillDirs
  )

  $codexSkills = Join-Path $CodexRoot 'skills'
  if (Test-Path -LiteralPath $codexSkills) {
    Get-ChildItem -Directory -LiteralPath $codexSkills |
      Where-Object {
        $_.Name -eq 'jingyuan' -or
        $_.Name -like 'jingyuan-*' -or
        $MirrorSkillDirs -contains $_.Name
      } |
      ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove obsolete flat JingYuan skill discovery entry')) {
          Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
      }
  }

  $nativeGroup = Join-Path $UserHome '.agents\skills\jingyuan'
  if (Test-Path -LiteralPath $nativeGroup) {
    if ($PSCmdlet.ShouldProcess($nativeGroup, 'Remove obsolete native JingYuan skill group')) {
      Remove-Item -LiteralPath $nativeGroup -Recurse -Force
    }
  }
}

function Install-JingYuanSkillMirror {
  param(
    [Parameter(Mandatory = $true)][string]$SourceSkillRoot,
    [Parameter(Mandatory = $true)][string]$TargetSkillRoot,
    [Parameter(Mandatory = $true)][string[]]$SkillNames
  )

  if (-not (Test-Path -LiteralPath $TargetSkillRoot)) {
    if ($PSCmdlet.ShouldProcess($TargetSkillRoot, 'Create Codex skill directory')) {
      New-Item -ItemType Directory -Path $TargetSkillRoot -Force | Out-Null
    }
  }

  foreach ($skillName in $SkillNames) {
    $sourceSkill = Join-Path $SourceSkillRoot $skillName
    $targetSkill = Join-Path $TargetSkillRoot "jy-$skillName"
    if (-not (Test-Path -LiteralPath $sourceSkill)) {
      throw "Source skill directory not found: $sourceSkill"
    }

    if ($PSCmdlet.ShouldProcess($targetSkill, "Install JingYuan skill mirror jingyuan:$skillName")) {
      Copy-Item -LiteralPath $sourceSkill -Destination $targetSkill -Recurse
      $skillFile = Join-Path $targetSkill 'SKILL.md'
      $content = Read-TextFile -Path $skillFile
      $content = [regex]::Replace($content, '(?m)^name:\s*.+$', "name: `"jingyuan:$skillName`"")
      $content = $content.Replace('../../assets/', '../../plugins/jingyuan/assets/')
      $content = $content.Replace('../../references/', '../../plugins/jingyuan/references/')
      Write-Utf8NoBomFile -Path $skillFile -Value $content
    }
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
$cleanupUserHome = if ([string]::IsNullOrWhiteSpace($HomeRoot)) { $HOME } else { $installRoot }
$installRoot = Get-FullPath -Path $installRoot
$cleanupUserHome = Get-FullPath -Path $cleanupUserHome
$targetPlugin = Join-Path $installRoot 'plugins\jingyuan'
$expectedPlugin = Join-Path $installRoot 'plugins\jingyuan'
$cachePluginParent = Join-Path $installRoot 'plugins\cache\local\jingyuan'
$expectedCachePluginParent = Join-Path $installRoot 'plugins\cache\local\jingyuan'
$cachePlugin = Join-Path $cachePluginParent 'local'
$expectedCachePlugin = Join-Path $installRoot 'plugins\cache\local\jingyuan\local'
$marketplacePath = Join-Path $installRoot '.agents\plugins\marketplace.json'
$configPath = Join-Path $installRoot 'config.toml'
$skillMirrorRoot = Join-Path $installRoot 'skills'
$jingyuanSkillNames = @(
  'pm',
  'design',
  'mockup',
  'dev-plan',
  'dev-builder',
  'review',
  'fix',
  'release',
  'feedback',
  'evolution',
  'skill-builder'
)
$mirrorSkillDirs = @($jingyuanSkillNames | ForEach-Object { "jy-$_" })

Assert-ExpectedPath -Actual $targetPlugin -Expected $expectedPlugin
Assert-ExpectedPath -Actual $cachePluginParent -Expected $expectedCachePluginParent
Assert-ExpectedPath -Actual $cachePlugin -Expected $expectedCachePlugin

if (Test-Path -LiteralPath $targetPlugin) {
  if (-not $Force) {
    throw "Target plugin already exists: $targetPlugin. Use -Force to replace JingYuan."
  }
  if ($PSCmdlet.ShouldProcess($targetPlugin, 'Remove existing JingYuan plugin')) {
    Remove-Item -LiteralPath $targetPlugin -Recurse -Force
  }
}

if (Test-Path -LiteralPath $cachePluginParent) {
  if (-not $Force) {
    throw "Target plugin cache already exists: $cachePluginParent. Use -Force to replace JingYuan."
  }
  if ($PSCmdlet.ShouldProcess($cachePluginParent, 'Remove existing JingYuan plugin cache')) {
    Remove-Item -LiteralPath $cachePluginParent -Recurse -Force
  }
}

$targetParent = Split-Path -Parent $targetPlugin
if (-not (Test-Path -LiteralPath $targetParent)) {
  if ($PSCmdlet.ShouldProcess($targetParent, 'Create plugin parent directory')) {
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
  }
}

$cachePluginContainer = Split-Path -Parent $cachePlugin
if (-not (Test-Path -LiteralPath $cachePluginContainer)) {
  if ($PSCmdlet.ShouldProcess($cachePluginContainer, 'Create plugin cache directory')) {
    New-Item -ItemType Directory -Path $cachePluginContainer -Force | Out-Null
  }
}

Remove-ObsoleteSkillDiscoveryEntries -CodexRoot $installRoot -UserHome $cleanupUserHome -MirrorSkillDirs $mirrorSkillDirs

if ($PSCmdlet.ShouldProcess($targetPlugin, 'Install JingYuan plugin')) {
  Copy-Item -LiteralPath $sourcePlugin -Destination $targetPlugin -Recurse
}

if ($PSCmdlet.ShouldProcess($cachePlugin, 'Install JingYuan plugin cache')) {
  Copy-Item -LiteralPath $sourcePlugin -Destination $cachePlugin -Recurse
}

Install-JingYuanSkillMirror -SourceSkillRoot (Join-Path $sourcePlugin 'skills') -TargetSkillRoot $skillMirrorRoot -SkillNames $jingyuanSkillNames

$marketplaceDir = Split-Path -Parent $marketplacePath
if (-not (Test-Path -LiteralPath $marketplaceDir)) {
  if ($PSCmdlet.ShouldProcess($marketplaceDir, 'Create marketplace directory')) {
    New-Item -ItemType Directory -Path $marketplaceDir -Force | Out-Null
  }
}

$marketplace = $null
if (Test-Path -LiteralPath $marketplacePath) {
  $raw = Read-TextFile -Path $marketplacePath
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

if ($null -eq $marketplace.name) {
  $marketplace | Add-Member -NotePropertyName name -NotePropertyValue 'local'
} else {
  $marketplace.name = 'local'
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
  Write-Utf8NoBomFile -Path $marketplacePath -Value $json
}

$configPath = Update-CodexConfig -InstallRoot $installRoot

if ($WhatIfPreference) {
  Write-Host "JingYuan plugin install planned for: $targetPlugin"
  Write-Host "JingYuan plugin cache install planned for: $cachePlugin"
  Write-Host "JingYuan skill mirror install planned for: $skillMirrorRoot\jy-*"
  Write-Host "Marketplace update planned for: $marketplacePath"
  Write-Host "Codex config update planned for: $configPath"
} else {
  Write-Host "JingYuan plugin installed to: $targetPlugin"
  Write-Host "JingYuan plugin cache installed to: $cachePlugin"
  Write-Host "JingYuan skill mirror installed to: $skillMirrorRoot\jy-*"
  Write-Host "Marketplace updated at: $marketplacePath"
  Write-Host "Codex config updated at: $configPath"
}
Write-Host 'Restart or refresh Codex, then invoke skills with jingyuan:* without a plugin-only completion row.'
