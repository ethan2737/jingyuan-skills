[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$pluginRoot = Join-Path $root 'plugins\jingyuan'
$manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$marketplacePath = Join-Path $root '.agents\plugins\marketplace.json'
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error {
  param([string]$Message)
  $errors.Add($Message) | Out-Null
}

function Test-RelativeReference {
  param(
    [string]$SkillDir,
    [string]$RelativePath,
    [string]$SourceFile
  )
  $target = Join-Path $SkillDir $RelativePath
  if (-not (Test-Path -LiteralPath $target)) {
    Add-Error "Missing referenced file from ${SourceFile}: ${RelativePath}"
  }
}

if (-not (Test-Path -LiteralPath $manifestPath)) {
  Add-Error "Missing plugin manifest: $manifestPath"
} else {
  $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
  if ($manifest.name -ne 'jingyuan') { Add-Error "plugin.json name must be 'jingyuan'." }
  if ($manifest.skills -ne './skills/') { Add-Error "plugin.json skills must be './skills/'." }
  if (-not (Test-Path -LiteralPath (Join-Path $pluginRoot 'skills'))) { Add-Error 'plugin skills path does not exist.' }
  $prompts = @($manifest.interface.defaultPrompt)
  if ($prompts.Count -gt 3) { Add-Error 'defaultPrompt has more than 3 entries.' }
  foreach ($prompt in $prompts) {
    if ($prompt.Length -gt 128) { Add-Error "defaultPrompt entry exceeds 128 characters: $prompt" }
  }
}

if (-not (Test-Path -LiteralPath $marketplacePath)) {
  Add-Error "Missing marketplace file: $marketplacePath"
} else {
  $marketplace = Get-Content -Raw -Encoding UTF8 -LiteralPath $marketplacePath | ConvertFrom-Json
  $entry = @($marketplace.plugins | Where-Object { $_.name -eq 'jingyuan' })
  if ($entry.Count -ne 1) { Add-Error 'marketplace must contain exactly one jingyuan entry.' }
  elseif ($entry[0].source.path -ne './plugins/jingyuan') { Add-Error "marketplace jingyuan source.path must be './plugins/jingyuan'." }
}

$skillRoot = Join-Path $pluginRoot 'skills'
if (Test-Path -LiteralPath (Join-Path $skillRoot 'jingyuan')) {
  Add-Error "Unexpected root skill directory exists: $(Join-Path $skillRoot 'jingyuan'). JingYuan should expose only jingyuan-* skills."
}

$skills = Get-ChildItem -Directory -LiteralPath $skillRoot | Where-Object { $_.Name -like 'jingyuan-*' }
if ($skills.Count -ne 11) {
  Add-Error "Expected 11 jingyuan skills, found $($skills.Count)."
}

foreach ($skill in $skills) {
  $skillFile = Join-Path $skill.FullName 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile)) {
    Add-Error "Missing SKILL.md for $($skill.Name)."
    continue
  }

  $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $skillFile
  if ($content -notmatch '(?s)^---\r?\n(.*?)\r?\n---') {
    Add-Error "Invalid frontmatter in $skillFile."
    continue
  }

  $frontmatter = $Matches[1]
  $name = ($frontmatter -split '\r?\n' | Where-Object { $_ -match '^name:\s*' } | Select-Object -First 1) -replace '^name:\s*', ''
  $description = ($frontmatter -split '\r?\n' | Where-Object { $_ -match '^description:\s*' } | Select-Object -First 1) -replace '^description:\s*', ''
  if ($name -ne $skill.Name) { Add-Error "Skill name '$name' does not match folder '$($skill.Name)'." }
  if ($name -notmatch '^[a-z0-9-]+$') { Add-Error "Skill name is not kebab-case: $name" }
  if ([string]::IsNullOrWhiteSpace($description)) { Add-Error "Missing description in $skillFile." }
  if ($description.Length -gt 1024) { Add-Error "Description too long in $skillFile." }
  if ($description -match '[<>]') { Add-Error "Description contains angle brackets in $skillFile." }

  $matches = [regex]::Matches($content, '\.\./\.\./(?:assets|references)/[A-Za-z0-9_./*-]+')
  foreach ($match in $matches) {
    $relative = $match.Value.Replace('/', '\')
    if ($relative.Contains('*')) { continue }
    Test-RelativeReference -SkillDir $skill.FullName -RelativePath $relative -SourceFile $skillFile
  }

  $pluginRootMatches = [regex]::Matches($content, '<JINGYUAN_PLUGIN_ROOT>/(?:assets|references)/[A-Za-z0-9_./*-]+')
  foreach ($match in $pluginRootMatches) {
    $relative = $match.Value.Replace('<JINGYUAN_PLUGIN_ROOT>/', '').Replace('/', '\')
    if ($relative.Contains('*')) { continue }
    $target = Join-Path $pluginRoot $relative
    if (-not (Test-Path -LiteralPath $target)) {
      Add-Error "Missing plugin-root referenced file from ${skillFile}: $($match.Value)"
    }
  }
}

$scanFiles = @()
$scanFiles += Get-ChildItem -Path (Join-Path $pluginRoot 'skills') -Recurse -File -Filter 'SKILL.md'
$scanFiles += Get-ChildItem -Path (Join-Path $pluginRoot 'assets\templates') -Recurse -File -Filter '*.md'
$scanFiles += Get-ChildItem -Path (Join-Path $pluginRoot 'references\workflow') -Recurse -File -Filter '*.md' |
  Where-Object { $_.Name -ne 'windows-powershell.md' }

$blockedPatterns = @(
  'pkill',
  'lsof',
  'kill\s+-9',
  'grep\s+-rn',
  '(?m)^\s*find\s+',
  'chmod',
  'sudo'
)

foreach ($file in $scanFiles) {
  $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
  foreach ($pattern in $blockedPatterns) {
    if ($content -match $pattern) {
      Add-Error "Blocked Unix command pattern '$pattern' found in $($file.FullName)."
    }
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Host 'JingYuan plugin validation passed.'
