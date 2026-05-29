[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$pluginRoot = Join-Path $root 'plugins\jingyuan'
$manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$claudeManifestPath = Join-Path $pluginRoot '.claude-plugin\plugin.json'
$marketplacePath = Join-Path $root '.agents\plugins\marketplace.json'
$claudeMarketplacePath = Join-Path $root '.claude-plugin\marketplace.json'
$installerPath = Join-Path $root 'install\install-local.ps1'
$claudeInstallerPath = Join-Path $root 'install\install-claude-local.ps1'
$readmePath = Join-Path $root 'README.md'
$validationReportPath = Join-Path $root 'validation-report.json'
$errors = New-Object System.Collections.Generic.List[string]
$manifest = $null
$claudeManifest = $null

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

function Test-Utf8JsonStartsClean {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 1 -or ($bytes[0] -ne 0x7B -and $bytes[0] -ne 0x5B)) {
    Add-Error "$Label must be UTF-8 JSON without BOM and start with '{' or '[': $Path"
  }
}

function Test-StrictUtf8 {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $encoding = [System.Text.UTF8Encoding]::new($false, $true)
  try {
    [void]$encoding.GetString($bytes)
  } catch {
    Add-Error "$Label must be valid UTF-8: $Path"
  }
}

function Test-Utf8Bom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  Test-StrictUtf8 -Path $Path -Label $Label
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
    Add-Error "$Label must be UTF-8 with BOM for Windows PowerShell 5.1 compatibility: $Path"
  }
}

if (-not (Test-Path -LiteralPath $manifestPath)) {
  Add-Error "Missing plugin manifest: $manifestPath"
} else {
  Test-Utf8JsonStartsClean -Path $manifestPath -Label 'plugin.json'
  $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
  if ($manifest.name -ne 'jingyuan') { Add-Error "plugin.json name must be 'jingyuan'." }
  if ($manifest.skills -ne './skills/') { Add-Error "plugin.json skills must be './skills/'." }
  if (-not (Test-Path -LiteralPath (Join-Path $pluginRoot 'skills'))) { Add-Error 'plugin skills path does not exist.' }
  $prompts = @()
  if ($null -ne $manifest.interface.defaultPrompt) {
    $prompts = @($manifest.interface.defaultPrompt)
  }
  if ($prompts.Count -gt 3) { Add-Error 'defaultPrompt has more than 3 entries.' }
  foreach ($prompt in $prompts) {
    if ($prompt.Length -gt 128) { Add-Error "defaultPrompt entry exceeds 128 characters: $prompt" }
  }
}

if (-not (Test-Path -LiteralPath $claudeManifestPath)) {
  Add-Error "Missing Claude Code plugin manifest: $claudeManifestPath"
} else {
  Test-Utf8JsonStartsClean -Path $claudeManifestPath -Label 'Claude Code plugin.json'
  $claudeManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $claudeManifestPath | ConvertFrom-Json
  if ($claudeManifest.name -ne 'jingyuan') { Add-Error "Claude Code plugin.json name must be 'jingyuan'." }
  if ($claudeManifest.skills -ne './skills/') { Add-Error "Claude Code plugin.json skills must be './skills/'." }
  if ([string]::IsNullOrWhiteSpace($claudeManifest.description)) { Add-Error 'Claude Code plugin.json must include description.' }
  if (-not (Test-Path -LiteralPath (Join-Path $pluginRoot 'skills'))) { Add-Error 'Claude Code plugin skills path does not exist.' }
  if ($null -ne $manifest) {
    if ($claudeManifest.name -ne $manifest.name) { Add-Error 'Codex and Claude Code plugin manifests must use the same name.' }
    if ($claudeManifest.version -ne $manifest.version) { Add-Error 'Codex and Claude Code plugin manifests must use the same version.' }
    if ($claudeManifest.license -ne $manifest.license) { Add-Error 'Codex and Claude Code plugin manifests must use the same license.' }
  }
}

if (-not (Test-Path -LiteralPath $installerPath)) {
  Add-Error "Missing installer: $installerPath"
} else {
  $installerContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $installerPath
  if ($installerContent -notmatch [regex]::Escape("plugins\cache\local\jingyuan\local")) {
    Add-Error 'Installer must sync the Codex local plugin cache path plugins\cache\local\jingyuan\local.'
  }
  if ($installerContent -notmatch 'Install-JingYuanSkillMirror') {
    Add-Error 'Installer must create flat Codex skill mirrors for jingyuan:* discovery.'
  }
  if ($installerContent -notmatch 'JINGYUAN_SKILL\.md') {
    Add-Error 'Installer must generate a BOM-safe JingYuan payload file for Codex mirror instructions.'
  }
  if ($installerContent -match 'Write-Utf8BomFile -Path \$skillFile') {
    Add-Error 'Installer must write Codex flat skill mirrors without BOM so frontmatter starts with raw ---.'
  }
  if ($installerContent -notmatch 'Write-Utf8BomFile -Path \$payloadFile') {
    Add-Error 'Installer must write Codex mirror payloads with BOM to avoid Windows PowerShell mojibake when reading Chinese instructions.'
  }
  if ($installerContent -match '\[plugins\."jingyuan@local"\]\s*\r?\n\s*enabled\s*=\s*true') {
    Add-Error 'Installer must not enable jingyuan@local by default because Codex shows enabled plugins as plugin-only completion rows.'
  }
}

if (-not (Test-Path -LiteralPath $claudeInstallerPath)) {
  Add-Error "Missing Claude Code installer: $claudeInstallerPath"
} else {
  $claudeInstallerContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $claudeInstallerPath
  if ($claudeInstallerContent -notmatch "ValidateSet\('user', 'project', 'local'\)") {
    Add-Error 'Claude Code installer must support user, project, and local scopes.'
  }
  if ($claudeInstallerContent -notmatch "'plugin', 'validate'") {
    Add-Error 'Claude Code installer must run claude plugin validate.'
  }
  if ($claudeInstallerContent -notmatch "'plugin', 'marketplace', 'add'") {
    Add-Error 'Claude Code installer must add the JingYuan marketplace.'
  }
  if ($claudeInstallerContent -notmatch "'plugin', 'install'") {
    Add-Error 'Claude Code installer must install jingyuan@jingyuan-local.'
  }
  if ($claudeInstallerContent -match 'CODEX_HOME|\.codex|config\.toml|\.agents') {
    Add-Error 'Claude Code installer must not write or depend on Codex home, config, or marketplace paths.'
  }
}

if (-not (Test-Path -LiteralPath $marketplacePath)) {
  Add-Error "Missing marketplace file: $marketplacePath"
} else {
  Test-Utf8JsonStartsClean -Path $marketplacePath -Label 'marketplace.json'
  $marketplace = Get-Content -Raw -Encoding UTF8 -LiteralPath $marketplacePath | ConvertFrom-Json
  if ($marketplace.name -ne 'local') { Add-Error "marketplace name must be 'local'." }
  $entry = @($marketplace.plugins | Where-Object { $_.name -eq 'jingyuan' })
  if ($entry.Count -ne 1) { Add-Error 'marketplace must contain exactly one jingyuan entry.' }
  elseif ($entry[0].source.path -ne './plugins/jingyuan') { Add-Error "marketplace jingyuan source.path must be './plugins/jingyuan'." }
}

if (-not (Test-Path -LiteralPath $claudeMarketplacePath)) {
  Add-Error "Missing Claude Code marketplace file: $claudeMarketplacePath"
} else {
  Test-Utf8JsonStartsClean -Path $claudeMarketplacePath -Label 'Claude Code marketplace.json'
  $claudeMarketplace = Get-Content -Raw -Encoding UTF8 -LiteralPath $claudeMarketplacePath | ConvertFrom-Json
  if ($claudeMarketplace.name -ne 'jingyuan-local') { Add-Error "Claude Code marketplace name must be 'jingyuan-local'." }
  if ($null -eq $claudeMarketplace.owner -or [string]::IsNullOrWhiteSpace($claudeMarketplace.owner.name)) {
    Add-Error 'Claude Code marketplace must include owner.name.'
  }
  $claudeEntry = @($claudeMarketplace.plugins | Where-Object { $_.name -eq 'jingyuan' })
  if ($claudeEntry.Count -ne 1) { Add-Error 'Claude Code marketplace must contain exactly one jingyuan entry.' }
  else {
    if ($claudeEntry[0].source -ne './plugins/jingyuan') { Add-Error "Claude Code marketplace jingyuan source must be './plugins/jingyuan'." }
    if ($claudeEntry[0].source -match '\.\.') { Add-Error 'Claude Code marketplace source must not contain .. path segments.' }
    if ($null -ne $claudeEntry[0].version) { Add-Error 'Claude Code marketplace must not duplicate plugin version; plugin.json owns the version.' }
  }
}

$skillRoot = Join-Path $pluginRoot 'skills'
if (Test-Path -LiteralPath (Join-Path $skillRoot 'jingyuan')) {
  Add-Error "Unexpected root skill directory exists: $(Join-Path $skillRoot 'jingyuan'). JingYuan should expose only short child skills under the jingyuan plugin namespace."
}

$expectedSkills = @(
  'setup',
  'pm',
  'design',
  'mockup',
  'dev-plan',
  'dev-builder',
  'review',
  'fix',
  'release',
  'research',
  'spider',
  'feedback',
  'humanizer',
  'evolution',
  'sync',
  'skill-builder'
)

$skills = Get-ChildItem -Directory -LiteralPath $skillRoot
$actualSkillNames = @($skills | ForEach-Object { $_.Name } | Sort-Object)
$expectedSkillNames = @($expectedSkills | Sort-Object)
$skillNameDiff = Compare-Object -ReferenceObject $expectedSkillNames -DifferenceObject $actualSkillNames
if ($actualSkillNames.Count -ne $expectedSkillNames.Count -or $skillNameDiff) {
  Add-Error "Expected JingYuan skills: $($expectedSkillNames -join ', '); found: $($actualSkillNames -join ', ')."
}

if (-not (Test-Path -LiteralPath $readmePath)) {
  Add-Error "Missing README: $readmePath"
} else {
  $readmeContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $readmePath
  if ($readmeContent -notmatch '## .+Claude Code') { Add-Error 'README must document Claude Code installation.' }
  if ($readmeContent -notmatch 'install-claude-local\.ps1') { Add-Error 'README must mention install-claude-local.ps1.' }
  if ($readmeContent -notmatch 'claude plugin validate \.') { Add-Error 'README must mention claude plugin validate .' }
  foreach ($expectedSkill in $expectedSkills) {
    if ($readmeContent -notmatch [regex]::Escape("`$jingyuan:$expectedSkill")) {
      Add-Error "README must mention `$jingyuan:$expectedSkill."
    }
    if ($readmeContent -notmatch [regex]::Escape("/jingyuan:$expectedSkill")) {
      Add-Error "README must mention /jingyuan:$expectedSkill."
    }
  }
}

if (Test-Path -LiteralPath $validationReportPath) {
  Test-Utf8JsonStartsClean -Path $validationReportPath -Label 'validation-report.json'
  $validationReport = Get-Content -Raw -Encoding UTF8 -LiteralPath $validationReportPath | ConvertFrom-Json
  if ($validationReport.skillCount -ne $expectedSkills.Count) {
    Add-Error "validation-report.json skillCount must be $($expectedSkills.Count); found $($validationReport.skillCount)."
  }
  $reportSkills = @($validationReport.skills | Sort-Object)
  $reportSkillDiff = Compare-Object -ReferenceObject $expectedSkillNames -DifferenceObject $reportSkills
  if ($reportSkills.Count -ne $expectedSkillNames.Count -or $reportSkillDiff) {
    Add-Error "validation-report.json skills must match expected skills."
  }
}

foreach ($skill in $skills) {
  $skillFile = Join-Path $skill.FullName 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile)) {
    Add-Error "Missing SKILL.md for $($skill.Name)."
    continue
  }

  Test-StrictUtf8 -Path $skillFile -Label 'Plugin SKILL.md'
  $bytes = [System.IO.File]::ReadAllBytes($skillFile)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Add-Error "Plugin SKILL.md must be UTF-8 without BOM for Claude Code frontmatter parsing: $skillFile"
    continue
  }
  if ($bytes.Length -lt 3 -or $bytes[0] -ne 0x2D -or $bytes[1] -ne 0x2D -or $bytes[2] -ne 0x2D) {
    Add-Error "Plugin SKILL.md must start with --- frontmatter: $skillFile"
    continue
  }

  $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $skillFile
  if ($content -notmatch '(?s)^\uFEFF?---\r?\n(.*?)\r?\n---') {
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
  if ($content -notmatch [regex]::Escape("`$jingyuan:$($skill.Name)")) {
    Add-Error "Skill must mention Codex entry `$jingyuan:$($skill.Name): $skillFile"
  }
  if ($content -notmatch [regex]::Escape("/jingyuan:$($skill.Name)")) {
    Add-Error "Skill must mention Claude Code entry /jingyuan:$($skill.Name): $skillFile"
  }
  if ($content -notmatch '\$\{CLAUDE_PLUGIN_ROOT\}') {
    Add-Error "Skill must document Claude Code plugin root variable `${CLAUDE_PLUGIN_ROOT}: $skillFile"
  }

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

$markdownFiles = Get-ChildItem -Path $root -Recurse -File -Filter '*.md' |
  Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\plugins\\jingyuan\\skills\\[^\\]+\\SKILL\.md$'
  }
foreach ($file in $markdownFiles) {
  Test-Utf8Bom -Path $file.FullName -Label 'Markdown file'
}

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
