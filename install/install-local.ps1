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

function Sync-JingYuanSkills {
  param(
    [Parameter(Mandatory = $true)][string]$SourceSkills,
    [Parameter(Mandatory = $true)][string]$TargetSkills,
    [switch]$Force
  )

  if (-not (Test-Path -LiteralPath $SourceSkills)) {
    throw "Source skills directory not found: $SourceSkills"
  }
  if (-not (Test-Path -LiteralPath $TargetSkills)) {
    if ($PSCmdlet.ShouldProcess($TargetSkills, 'Create Codex skills directory')) {
      New-Item -ItemType Directory -Path $TargetSkills -Force | Out-Null
    }
  }

  $obsoleteRootSkill = Join-Path $TargetSkills 'jingyuan'
  if (Test-Path -LiteralPath $obsoleteRootSkill) {
    if (-not $Force) {
      throw "Obsolete JingYuan root skill exists: $obsoleteRootSkill. Use -Force to remove it."
    }
    if ($PSCmdlet.ShouldProcess($obsoleteRootSkill, 'Remove obsolete JingYuan root skill')) {
      Remove-Item -LiteralPath $obsoleteRootSkill -Recurse -Force
    }
  }

  Get-ChildItem -Directory -LiteralPath $SourceSkills | Where-Object { $_.Name -like 'jingyuan-*' } | ForEach-Object {
    $target = Join-Path $TargetSkills $_.Name
    if (Test-Path -LiteralPath $target) {
      if (-not $Force) {
        throw "Target skill already exists: $target. Use -Force to replace JingYuan skills."
      }
      if ($PSCmdlet.ShouldProcess($target, 'Remove existing JingYuan skill')) {
        Remove-Item -LiteralPath $target -Recurse -Force
      }
    }
    if ($PSCmdlet.ShouldProcess($target, 'Install JingYuan skill discovery entry')) {
      Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse
    }
  }
}

function Sync-NativeSkillGroup {
  param(
    [Parameter(Mandatory = $true)][string]$SourceSkills,
    [Parameter(Mandatory = $true)][string]$UserHome,
    [switch]$Force
  )

  $nativeSkillsRoot = Join-Path $UserHome '.agents\skills'
  $nativeGroup = Join-Path $nativeSkillsRoot 'jingyuan'

  if (-not (Test-Path -LiteralPath $nativeSkillsRoot)) {
    if ($PSCmdlet.ShouldProcess($nativeSkillsRoot, 'Create native skills directory')) {
      New-Item -ItemType Directory -Path $nativeSkillsRoot -Force | Out-Null
    }
  }

  if (Test-Path -LiteralPath $nativeGroup) {
    if (-not $Force) {
      throw "Native JingYuan skill group already exists: $nativeGroup. Use -Force to replace it."
    }
    if ($PSCmdlet.ShouldProcess($nativeGroup, 'Remove existing native JingYuan skill group')) {
      Remove-Item -LiteralPath $nativeGroup -Recurse -Force
    }
  }

  if ($PSCmdlet.ShouldProcess($nativeGroup, 'Create native JingYuan skill group junction')) {
    New-Item -ItemType Junction -Path $nativeGroup -Target $SourceSkills | Out-Null
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
$targetSkills = Join-Path $installRoot 'skills'

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

Sync-JingYuanSkills -SourceSkills (Join-Path $sourcePlugin 'skills') -TargetSkills $targetSkills -Force:$Force
Sync-NativeSkillGroup -SourceSkills (Join-Path $targetPlugin 'skills') -UserHome $HOME -Force:$Force

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
  Write-Host "JingYuan skill discovery entries planned for: $targetSkills"
  Write-Host "JingYuan native CLI skill group planned for: $(Join-Path $HOME '.agents\skills\jingyuan')"
  Write-Host "Marketplace update planned for: $marketplacePath"
} else {
  Write-Host "JingYuan plugin installed to: $targetPlugin"
  Write-Host "JingYuan skill discovery entries installed to: $targetSkills"
  Write-Host "JingYuan native CLI skill group installed to: $(Join-Path $HOME '.agents\skills\jingyuan')"
  Write-Host "Marketplace updated at: $marketplacePath"
}
Write-Host 'Restart or refresh Codex, then invoke skills with $jingyuan-*.' 
