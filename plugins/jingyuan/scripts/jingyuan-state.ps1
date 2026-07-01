[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Init', 'StartSession', 'CreateTask', 'Claim', 'Renew', 'Complete', 'Block', 'Release', 'Status', 'Doctor', 'Recover', 'CheckCommit', 'RebuildViews')]
  [string]$Action,

  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,

  [switch]$Migrate,
  [string]$Role,
  [string]$SessionId,
  [string]$TaskId,
  [string]$ChangeId,
  [string]$Title,
  [string]$FromRole,
  [string]$ToRole,
  [ValidateSet('High', 'Medium', 'Low')]
  [string]$Priority = 'Medium',
  [string[]]$ReadRef = @(),
  [string[]]$WriteScope = @(),
  [string[]]$DependsOn = @(),
  [string[]]$AcceptanceCriterion = @(),
  [int]$LeaseMinutes = 0,
  [switch]$AdoptDirty,
  [string]$Summary,
  [string[]]$ChangedFile = @(),
  [string[]]$Verification = @(),
  [string[]]$Concern = @(),
  [string[]]$OpenQuestion = @(),
  [string]$Reason,
  [switch]$ReleaseLocks,
  [switch]$ConfirmRecovery
)

$ErrorActionPreference = 'Stop'
$script:ExitCode = 0
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Utf8Bom = New-Object System.Text.UTF8Encoding($true)
$script:ProjectPath = $null
$script:StatePath = $null

function Write-JsonResult {
  param(
    [Parameter(Mandatory = $true)][bool]$Ok,
    [Parameter(Mandatory = $true)][string]$Code,
    [Parameter(Mandatory = $true)][string]$Message,
    [object]$Data,
    [int]$ExitCode = 0
  )

  $payload = [ordered]@{
    ok = $Ok
    code = $Code
    message = $Message
    data = $Data
  }
  [Console]::Out.WriteLine(($payload | ConvertTo-Json -Depth 12 -Compress))
  exit $ExitCode
}

function Write-AtomicText {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content,
    [Parameter(Mandatory = $true)][System.Text.Encoding]$Encoding
  )

  $directory = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  $temporaryPath = Join-Path $directory ('.tmp-' + [guid]::NewGuid().ToString('N'))
  $backupPath = Join-Path $directory ('.bak-' + [guid]::NewGuid().ToString('N'))
  try {
    [IO.File]::WriteAllText($temporaryPath, $Content, $Encoding)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      [IO.File]::Replace($temporaryPath, $Path, $backupPath)
    } else {
      [IO.File]::Move($temporaryPath, $Path)
    }
  } finally {
    if (Test-Path -LiteralPath $temporaryPath) {
      Remove-Item -LiteralPath $temporaryPath -Force
    }
    if (Test-Path -LiteralPath $backupPath) {
      Remove-Item -LiteralPath $backupPath -Force
    }
  }
}

function Write-AtomicJson {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][object]$Value
  )

  $content = $Value | ConvertTo-Json -Depth 16
  Write-AtomicText -Path $Path -Content ($content + [Environment]::NewLine) -Encoding $script:Utf8NoBom
}

function Get-DefaultConfig {
  [ordered]@{
    version = 2
    docs = [ordered]@{
      prd = 'docs/PRD/prd.md'
      prdChangelog = 'docs/PRD/changelog.md'
      design = 'docs/design/design.md'
      mockup = 'docs/design/mockup.md'
      developmentPlan = 'docs/development/plan.md'
      changesDir = 'docs/changes'
      reviewDir = 'docs/review'
      bugFixDir = 'docs/bug-fix'
      feedbackIndex = 'docs/feedback/index.md'
      context = 'docs/context.md'
      adrDir = 'docs/adr'
      outOfScopeDir = 'docs/out-of-scope'
    }
    state = [ordered]@{
      enabled = $true
      mode = 'local'
      root = '.jingyuan/state'
      leaseMinutes = 120
      eventViewLimit = 20
      handoffViewLimit = 3
      archiveDays = 30
    }
    contextMode = 'single'
    createdBy = 'jingyuan:setup'
  }
}

function Add-StateConfig {
  param([Parameter(Mandatory = $true)][object]$Config)

  $default = Get-DefaultConfig
  $Config.version = 2
  if ($null -eq $Config.PSObject.Properties['state']) {
    $Config | Add-Member -NotePropertyName state -NotePropertyValue ([pscustomobject]$default.state)
  } else {
    foreach ($key in $default.state.Keys) {
      if ($null -eq $Config.state.PSObject.Properties[$key]) {
        $Config.state | Add-Member -NotePropertyName $key -NotePropertyValue $default.state[$key]
      }
    }
  }
  return $Config
}

function Get-UtcTimestamp {
  return [DateTime]::UtcNow.ToString('o')
}

function Get-ShortUtcTimestamp {
  return [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
}

function Get-Config {
  $configPath = Join-Path $script:ProjectPath '.jingyuan\config.json'
  if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-JsonResult -Ok $false -Code 'STATE_NOT_INITIALIZED' -Message 'Run Init before using the collaboration state.' -ExitCode 5
  }
  try {
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Write-JsonResult -Ok $false -Code 'INVALID_CONFIG' -Message 'Existing .jingyuan/config.json is not valid JSON.' -ExitCode 2
  }
  if ([int]$config.version -ne 2 -or $null -eq $config.state -or $config.state.enabled -ne $true) {
    Write-JsonResult -Ok $false -Code 'STATE_NOT_ENABLED' -Message 'Collaboration state requires config version 2 with state.enabled=true.' -ExitCode 2
  }
  return $config
}

function Test-ValidRole {
  param([string]$Value)
  return -not [string]::IsNullOrWhiteSpace($Value) -and $Value -match '^[a-z][a-z0-9-]{1,31}$'
}

function Assert-NoSensitiveText {
  param([object[]]$Values)
  $secretPattern = '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|token|password|passwd|secret)\s*[:=]\s*\S+'
  foreach ($value in $Values) {
    if (-not [string]::IsNullOrWhiteSpace([string]$value) -and ([string]$value) -match $secretPattern) {
      Write-JsonResult -Ok $false -Code 'SENSITIVE_CONTENT' -Message 'State text appears to contain a credential or secret. Store only a redacted reference.' -ExitCode 2
    }
  }
}

function Expand-DelimitedValues {
  param([object[]]$Values)
  $expanded = New-Object System.Collections.Generic.List[string]
  foreach ($value in $Values) {
    foreach ($part in ([string]$value -split ';')) {
      $trimmed = $part.Trim()
      if (-not [string]::IsNullOrWhiteSpace($trimmed)) { $expanded.Add($trimmed) }
    }
  }
  return $expanded.ToArray()
}

function Resolve-SafeRelativePath {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [switch]$MustExist
  )

  $candidate = $RelativePath.Trim().Replace('/', '\')
  if ([string]::IsNullOrWhiteSpace($candidate) -or
      [IO.Path]::IsPathRooted($candidate) -or
      $candidate.StartsWith('\\') -or
      $candidate -match '(^|\\)\.\.(\\|$)' -or
      $candidate.Contains(':')) {
    Write-JsonResult -Ok $false -Code 'INVALID_PATH' -Message "Path must stay inside ProjectRoot: $RelativePath" -ExitCode 2
  }

  $absolutePath = [IO.Path]::GetFullPath((Join-Path $script:ProjectPath $candidate))
  $rootPrefix = $script:ProjectPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  if (-not $absolutePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    Write-JsonResult -Ok $false -Code 'INVALID_PATH' -Message "Path escapes ProjectRoot: $RelativePath" -ExitCode 2
  }

  $cursor = $absolutePath
  while (-not [string]::IsNullOrWhiteSpace($cursor) -and $cursor.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    if (Test-Path -LiteralPath $cursor) {
      $item = Get-Item -LiteralPath $cursor -Force
      if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Write-JsonResult -Ok $false -Code 'INVALID_PATH' -Message "Reparse-point paths are not allowed in state scopes: $RelativePath" -ExitCode 2
      }
    }
    if ($cursor -eq $script:ProjectPath) { break }
    $cursor = Split-Path -Parent $cursor
  }

  if ($MustExist -and -not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    Write-JsonResult -Ok $false -Code 'SOURCE_NOT_FOUND' -Message "Referenced source does not exist: $RelativePath" -ExitCode 5
  }

  return $candidate.Replace('\', '/')
}

function Get-FileSha256 {
  param([Parameter(Mandatory = $true)][string]$RelativePath)
  $absolutePath = Join-Path $script:ProjectPath $RelativePath.Replace('/', '\')
  return (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash
}

function Get-StringSha256 {
  param([Parameter(Mandatory = $true)][string]$Value)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = $script:Utf8NoBom.GetBytes($Value)
    return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
  } finally {
    $sha.Dispose()
  }
}

function Invoke-GitCapture {
  param([string[]]$GitArguments = @())
  if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    return [pscustomobject]@{ ExitCode = 127; Output = @() }
  }
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = @(& git -C $script:ProjectPath @GitArguments 2>$null)
    $exitCode = $LASTEXITCODE
  } catch {
    $output = @()
    $exitCode = 1
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  return [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
}

function Enter-StateMutex {
  $mutexName = 'JingYuanState-' + (Get-StringSha256 -Value $script:ProjectPath.ToLowerInvariant()).Substring(0, 24)
  $mutex = New-Object System.Threading.Mutex($false, $mutexName)
  $acquired = $false
  try {
    try {
      $acquired = $mutex.WaitOne(2000)
    } catch [Threading.AbandonedMutexException] {
      $acquired = $true
    }
    if (-not $acquired) {
      $mutex.Dispose()
      Write-JsonResult -Ok $false -Code 'STATE_BUSY' -Message 'Another state transition is in progress. Retry shortly.' -ExitCode 3
    }
    return $mutex
  } catch {
    if (-not $acquired) { $mutex.Dispose() }
    throw
  }
}

function Get-GitHead {
  $result = Invoke-GitCapture -GitArguments @('rev-parse', 'HEAD')
  if ($result.ExitCode -ne 0 -or $result.Output.Count -eq 0) { return $null }
  return ([string]$result.Output[0]).Trim()
}

function Get-SessionRecord {
  param([Parameter(Mandatory = $true)][string]$Id)
  if ($Id -notmatch '^session-[a-z][a-z0-9-]{1,31}-[0-9a-f]{12}$') {
    Write-JsonResult -Ok $false -Code 'INVALID_SESSION' -Message 'SessionId has an invalid format.' -ExitCode 2
  }
  $path = Join-Path $script:StatePath "sessions\$Id.json"
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-JsonResult -Ok $false -Code 'SESSION_NOT_FOUND' -Message "Session not found: $Id" -ExitCode 5
  }
  try {
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Write-JsonResult -Ok $false -Code 'INVALID_STATE' -Message "Session record is invalid JSON: $Id" -ExitCode 2
  }
}

function Get-TaskRecord {
  param([Parameter(Mandatory = $true)][string]$Id)
  if ($Id -notmatch '^task-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$') {
    Write-JsonResult -Ok $false -Code 'INVALID_TASK_ID' -Message 'TaskId has an invalid format.' -ExitCode 2
  }
  foreach ($relativeDirectory in @('records\tasks\active', 'records\tasks\archive')) {
    $path = Join-Path $script:StatePath "$relativeDirectory\$Id.json"
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      try {
        return [pscustomobject]@{
          Path = $path
          Record = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
          IsArchive = $relativeDirectory.EndsWith('archive')
        }
      } catch {
        Write-JsonResult -Ok $false -Code 'INVALID_STATE' -Message "Task record is invalid JSON: $Id" -ExitCode 2
      }
    }
  }
  Write-JsonResult -Ok $false -Code 'TASK_NOT_FOUND' -Message "Task not found: $Id" -ExitCode 5
}

function Get-ScopeLockPath {
  param([Parameter(Mandatory = $true)][string]$Scope)
  $key = Get-StringSha256 -Value $Scope.ToLowerInvariant()
  return Join-Path $script:StatePath "locks\$key"
}

function Remove-TaskLocks {
  param(
    [Parameter(Mandatory = $true)][object]$Task,
    [Parameter(Mandatory = $true)][string]$OwnerSession
  )
  foreach ($scope in @($Task.write_scopes)) {
    $lockPath = Get-ScopeLockPath -Scope $scope
    $ownerPath = Join-Path $lockPath 'owner.json'
    if (-not (Test-Path -LiteralPath $ownerPath -PathType Leaf)) { continue }
    try {
      $lock = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($lock.task_id -eq $Task.task_id -and $lock.session_id -eq $OwnerSession) {
        Remove-Item -LiteralPath $lockPath -Recurse -Force
      }
    } catch {
      continue
    }
  }
}

function Acquire-TaskLocks {
  param(
    [Parameter(Mandatory = $true)][object]$Task,
    [Parameter(Mandatory = $true)][string]$OwnerSession,
    [Parameter(Mandatory = $true)][string]$LeaseExpiresAt
  )

  $acquired = New-Object System.Collections.Generic.List[string]
  foreach ($scope in @($Task.write_scopes) | Sort-Object) {
    $lockPath = Get-ScopeLockPath -Scope $scope
    try {
      New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop | Out-Null
      $acquired.Add($lockPath)
      $lock = [ordered]@{
        schema_version = 1
        scope = $scope
        task_id = $Task.task_id
        session_id = $OwnerSession
        lease_expires_at = $LeaseExpiresAt
        acquired_at = Get-UtcTimestamp
      }
      Write-AtomicJson -Path (Join-Path $lockPath 'owner.json') -Value $lock
    } catch {
      $conflict = $null
      $ownerPath = Join-Path $lockPath 'owner.json'
      if (Test-Path -LiteralPath $ownerPath -PathType Leaf) {
        try { $conflict = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
      }
      foreach ($path in $acquired) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
      }
      Write-JsonResult -Ok $false -Code 'LOCK_CONFLICT' -Message "Write scope is already locked: $scope" -Data $conflict -ExitCode 3
    }
  }
}

function Get-GitPathStatus {
  param([Parameter(Mandatory = $true)][string]$RelativePath)
  $absolutePath = Join-Path $script:ProjectPath $RelativePath.Replace('/', '\')
  $parentPath = Split-Path -Parent $absolutePath
  if (-not (Test-Path -LiteralPath $absolutePath) -and -not (Test-Path -LiteralPath $parentPath -PathType Container)) {
    return @()
  }
  $result = Invoke-GitCapture -GitArguments @('status', '--porcelain=v1', '--untracked-files=all', '--', $RelativePath)
  if ($result.ExitCode -ne 0) { return @() }
  return @($result.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-TaskSourcesCurrent {
  param([Parameter(Mandatory = $true)][object]$Task)
  $stale = New-Object System.Collections.Generic.List[object]
  foreach ($reference in @($Task.read_refs)) {
    $absolutePath = Join-Path $script:ProjectPath $reference.path.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
      $stale.Add([ordered]@{ path = $reference.path; reason = 'missing' })
      continue
    }
    $actual = Get-FileSha256 -RelativePath $reference.path
    if ($actual -ne $reference.sha256) {
      $stale.Add([ordered]@{ path = $reference.path; reason = 'hash_changed'; expected = $reference.sha256; actual = $actual })
    }
  }
  return $stale.ToArray()
}

function Test-PathInWriteScopes {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][object[]]$Scopes
  )
  $path = $RelativePath.Replace('\', '/').TrimStart('/')
  foreach ($scopeValue in $Scopes) {
    $scope = ([string]$scopeValue).Replace('\', '/').TrimStart('/')
    if ($path.Equals($scope, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $scopeAbsolute = Join-Path $script:ProjectPath $scope.Replace('/', '\')
    if ((Test-Path -LiteralPath $scopeAbsolute -PathType Container) -or $scope.EndsWith('/')) {
      $prefix = $scope.TrimEnd('/') + '/'
      if ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
  }
  return $false
}

function Get-RelatedHeadDrift {
  param([Parameter(Mandatory = $true)][object]$Task)
  $currentHead = Get-GitHead
  if ([string]::IsNullOrWhiteSpace([string]$Task.base_head) -or
      [string]::IsNullOrWhiteSpace([string]$currentHead) -or
      $Task.base_head -eq $currentHead) {
    return @()
  }
  $result = Invoke-GitCapture -GitArguments @('diff', '--name-only', "$($Task.base_head)..$currentHead")
  if ($result.ExitCode -ne 0) { return @() }
  $changed = $result.Output
  $readPaths = @($Task.read_refs | ForEach-Object { $_.path })
  $related = New-Object System.Collections.Generic.List[string]
  foreach ($path in @($changed)) {
    if ($readPaths -contains $path -or (Test-PathInWriteScopes -RelativePath $path -Scopes @($Task.write_scopes))) {
      $related.Add([string]$path)
    }
  }
  return $related.ToArray()
}

function Assert-TaskDependenciesReady {
  param([Parameter(Mandatory = $true)][object]$Task)
  $notReady = New-Object System.Collections.Generic.List[object]
  foreach ($dependencyId in @($Task.depends_on)) {
    $dependency = Get-TaskRecord -Id $dependencyId
    if ($dependency.Record.status -ne 'done') {
      $notReady.Add([ordered]@{ task_id = $dependencyId; status = $dependency.Record.status })
    }
  }
  if ($notReady.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'DEPENDENCY_NOT_READY' -Message 'One or more task dependencies are not done.' -Data $notReady.ToArray() -ExitCode 3
  }
}

function Add-Event {
  param(
    [Parameter(Mandatory = $true)][string]$Type,
    [Parameter(Mandatory = $true)][string]$EventSummary,
    [string]$EventTaskId,
    [string]$EventChangeId,
    [string]$EventSessionId,
    [object]$Details
  )

  $eventId = 'event-' + (Get-ShortUtcTimestamp) + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
  $event = [ordered]@{
    schema_version = 1
    event_id = $eventId
    type = $Type
    summary = $EventSummary
    task_id = $EventTaskId
    change_id = $EventChangeId
    session_id = $EventSessionId
    details = $Details
    created_at = Get-UtcTimestamp
  }
  Write-AtomicJson -Path (Join-Path $script:StatePath "records\events\$eventId.json") -Value $event
  return $event
}

function Get-JsonRecords {
  param([Parameter(Mandatory = $true)][string]$Directory)
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
  $records = New-Object System.Collections.Generic.List[object]
  foreach ($file in Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File | Sort-Object Name) {
    try {
      $records.Add((Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json))
    } catch {
      continue
    }
  }
  return $records.ToArray()
}

function Rebuild-StateViews {
  $tasks = @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'records\tasks\active'))
  $events = @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'records\events') | Sort-Object created_at -Descending)
  $lockRecords = New-Object System.Collections.Generic.List[object]
  $locksDirectory = Join-Path $script:StatePath 'locks'
  if (Test-Path -LiteralPath $locksDirectory -PathType Container) {
    foreach ($lockDirectory in Get-ChildItem -LiteralPath $locksDirectory -Directory) {
      $ownerPath = Join-Path $lockDirectory.FullName 'owner.json'
      if (Test-Path -LiteralPath $ownerPath -PathType Leaf) {
        try { $lockRecords.Add((Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json)) } catch { }
      }
    }
  }

  $current = New-Object System.Collections.Generic.List[string]
  $current.Add('# JingYuan Current State')
  $current.Add('')
  $current.Add('> Generated by jingyuan-state.ps1. Do not edit directly.')
  $current.Add('')
  if ($tasks.Count -eq 0) {
    $current.Add('No active changes.')
  } else {
    $current.Add('| Change | Task | Role | Status | Focus |')
    $current.Add('|---|---|---|---|---|')
    foreach ($task in $tasks | Sort-Object priority, created_at) {
      $change = if ([string]::IsNullOrWhiteSpace([string]$task.change_id)) { '-' } else { $task.change_id }
      $current.Add("| $change | $($task.task_id) | $($task.to_role) | $($task.status) | $($task.title) |")
    }
  }

  $inbox = New-Object System.Collections.Generic.List[string]
  $inbox.Add('# JingYuan Inbox')
  $inbox.Add('')
  $inbox.Add('> Generated by jingyuan-state.ps1. Do not edit directly.')
  foreach ($roleGroup in $tasks | Where-Object { $_.status -in @('pending', 'blocked', 'needs_context', 'needs_decision') } | Group-Object to_role | Sort-Object Name) {
    $inbox.Add('')
    $inbox.Add("## To $($roleGroup.Name)")
    $inbox.Add('')
    foreach ($task in $roleGroup.Group | Sort-Object priority, created_at) {
      $inbox.Add("- [$($task.status)] $($task.title) (`$($task.task_id))")
    }
  }
  if ($inbox.Count -eq 3) { $inbox.Add(''); $inbox.Add('No pending tasks.') }

  $eventsView = New-Object System.Collections.Generic.List[string]
  $eventsView.Add('# JingYuan Recent Events')
  $eventsView.Add('')
  $eventsView.Add('> Generated by jingyuan-state.ps1. Do not edit directly.')
  foreach ($event in $events | Select-Object -First 20) {
    $eventsView.Add('')
    $eventsView.Add("- $($event.created_at) [$($event.type)] $($event.summary)")
  }
  if ($eventsView.Count -eq 3) { $eventsView.Add(''); $eventsView.Add('No recent events.') }

  $locksView = New-Object System.Collections.Generic.List[string]
  $locksView.Add('# JingYuan Locks')
  $locksView.Add('')
  $locksView.Add('> Generated by jingyuan-state.ps1. Do not edit directly.')
  if ($lockRecords.Count -eq 0) {
    $locksView.Add('')
    $locksView.Add('No active locks.')
  } else {
    $locksView.Add('')
    $locksView.Add('| Scope | Task | Session | Expires |')
    $locksView.Add('|---|---|---|---|')
    foreach ($lock in $lockRecords | Sort-Object scope) {
      $locksView.Add("| $($lock.scope) | $($lock.task_id) | $($lock.session_id) | $($lock.lease_expires_at) |")
    }
  }

  $handoffView = New-Object System.Collections.Generic.List[string]
  $handoffView.Add('# JingYuan Handoff')
  $handoffView.Add('')
  $handoffView.Add('> Generated by jingyuan-state.ps1. Do not edit directly.')
  foreach ($event in $events | Where-Object { $_.type -in @('task_completed', 'task_blocked', 'task_released') } | Select-Object -First 3) {
    $handoffView.Add('')
    $handoffView.Add("## $($event.task_id)")
    $handoffView.Add('')
    $handoffView.Add($event.summary)
  }
  if ($handoffView.Count -eq 3) { $handoffView.Add(''); $handoffView.Add('No recent handoffs.') }

  foreach ($view in @(
    @{ Name = 'current.md'; Lines = $current },
    @{ Name = 'inbox.md'; Lines = $inbox },
    @{ Name = 'events.md'; Lines = $eventsView },
    @{ Name = 'locks.md'; Lines = $locksView },
    @{ Name = 'handoff.md'; Lines = $handoffView }
  )) {
    Write-AtomicText -Path (Join-Path $script:StatePath $view.Name) -Content (($view.Lines -join "`r`n") + "`r`n") -Encoding $script:Utf8Bom
  }

  $hashes = [ordered]@{}
  foreach ($viewName in @('current.md', 'inbox.md', 'events.md', 'locks.md', 'handoff.md')) {
    $hashes[$viewName] = (Get-FileHash -LiteralPath (Join-Path $script:StatePath $viewName) -Algorithm SHA256).Hash
  }
  Write-AtomicJson -Path (Join-Path $script:StatePath 'records\views.json') -Value ([ordered]@{
    schema_version = 1
    generated_at = Get-UtcTimestamp
    hashes = $hashes
  })
}

function Get-DependencyCycleTaskIds {
  param([object[]]$Tasks = @())
  $taskMap = @{}
  foreach ($task in $Tasks) { $taskMap[$task.task_id] = $task }
  $colors = @{}
  $cycleNodes = New-Object 'System.Collections.Generic.HashSet[string]'

  function Visit-DependencyNode {
    param(
      [Parameter(Mandatory = $true)][string]$NodeId,
      [System.Collections.Generic.List[string]]$Stack
    )
    $colors[$NodeId] = 'gray'
    $Stack.Add($NodeId)
    foreach ($dependencyId in @($taskMap[$NodeId].depends_on)) {
      if (-not $taskMap.ContainsKey($dependencyId)) { continue }
      if ($colors[$dependencyId] -eq 'gray') {
        $start = $Stack.IndexOf($dependencyId)
        if ($start -ge 0) {
          for ($index = $start; $index -lt $Stack.Count; $index++) {
            [void]$cycleNodes.Add($Stack[$index])
          }
        }
      } elseif ($colors[$dependencyId] -ne 'black') {
        Visit-DependencyNode -NodeId $dependencyId -Stack $Stack
      }
    }
    $Stack.RemoveAt($Stack.Count - 1)
    $colors[$NodeId] = 'black'
  }

  foreach ($taskIdValue in @($taskMap.Keys)) {
    if ($colors[$taskIdValue] -ne 'black') {
      $stack = New-Object 'System.Collections.Generic.List[string]'
      Visit-DependencyNode -NodeId $taskIdValue -Stack $stack
    }
  }
  return @($cycleNodes | Sort-Object)
}

function Start-StateSession {
  [void](Get-Config)
  if (-not (Test-ValidRole -Value $Role)) {
    Write-JsonResult -Ok $false -Code 'INVALID_ROLE' -Message 'Role must use lowercase letters, digits, and hyphens.' -ExitCode 2
  }
  $id = "session-$Role-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
  $timestamp = Get-UtcTimestamp
  $record = [ordered]@{
    schema_version = 1
    session_id = $id
    role = $Role
    status = 'active'
    started_at = $timestamp
    last_seen_at = $timestamp
  }
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$id.json") -Value $record
  [void](Add-Event -Type 'session_started' -EventSummary "$Role session started." -EventSessionId $id)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'SESSION_STARTED' -Message 'Session started.' -Data $record
}

function New-StateTask {
  [void](Get-Config)
  $session = Get-SessionRecord -Id $SessionId
  if (-not (Test-ValidRole -Value $FromRole) -or -not (Test-ValidRole -Value $ToRole)) {
    Write-JsonResult -Ok $false -Code 'INVALID_ROLE' -Message 'FromRole and ToRole must be valid single role names.' -ExitCode 2
  }
  if ($session.role -ne $FromRole) {
    Write-JsonResult -Ok $false -Code 'ROLE_MISMATCH' -Message 'FromRole must match the creating session role.' -ExitCode 2
  }
  if ([string]::IsNullOrWhiteSpace($Title) -or $Title.Length -gt 120) {
    Write-JsonResult -Ok $false -Code 'INVALID_TASK' -Message 'Title is required and must not exceed 120 characters.' -ExitCode 2
  }
  Assert-NoSensitiveText -Values (@($Title) + @($AcceptanceCriterion))
  $expandedReadRefs = @(Expand-DelimitedValues -Values $ReadRef)
  $expandedWriteScopes = @(Expand-DelimitedValues -Values $WriteScope)
  $expandedDependencies = @(Expand-DelimitedValues -Values $DependsOn)
  if ($expandedWriteScopes.Count -eq 0 -or $expandedWriteScopes.Count -gt 20) {
    Write-JsonResult -Ok $false -Code 'INVALID_TASK' -Message 'Each task requires 1-20 write scopes.' -ExitCode 2
  }

  $readReferences = New-Object System.Collections.Generic.List[object]
  foreach ($reference in $expandedReadRefs) {
    $parts = $reference -split '#', 2
    $path = Resolve-SafeRelativePath -RelativePath $parts[0] -MustExist
    $anchor = if ($parts.Count -eq 2) { $parts[1] } else { $null }
    $readReferences.Add([ordered]@{
      path = $path
      anchor = $anchor
      sha256 = Get-FileSha256 -RelativePath $path
    })
  }

  $writeScopes = New-Object System.Collections.Generic.List[string]
  foreach ($scope in $expandedWriteScopes) {
    $normalized = Resolve-SafeRelativePath -RelativePath $scope
    if (-not $writeScopes.Contains($normalized)) { $writeScopes.Add($normalized) }
  }

  $taskIdValue = 'task-' + (Get-ShortUtcTimestamp) + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
  $timestamp = Get-UtcTimestamp
  $task = [ordered]@{
    schema_version = 1
    task_id = $taskIdValue
    change_id = if ([string]::IsNullOrWhiteSpace($ChangeId)) { $null } else { $ChangeId }
    title = $Title
    from_role = $FromRole
    to_role = $ToRole
    status = 'pending'
    priority = $Priority
    read_refs = $readReferences.ToArray()
    write_scopes = $writeScopes.ToArray()
    depends_on = $expandedDependencies
    acceptance_criteria = @($AcceptanceCriterion)
    owner_session = $null
    lease_expires_at = $null
    base_head = $null
    write_baseline = @()
    concerns = @()
    created_at = $timestamp
    updated_at = $timestamp
  }
  Write-AtomicJson -Path (Join-Path $script:StatePath "records\tasks\active\$taskIdValue.json") -Value $task
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  [void](Add-Event -Type 'task_created' -EventSummary $Title -EventTaskId $taskIdValue -EventChangeId $task.change_id -EventSessionId $SessionId)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_CREATED' -Message 'Task created.' -Data ([ordered]@{ task_id = $taskIdValue; status = 'pending' })
}

function Claim-StateTask {
  $config = Get-Config
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  if ($taskContainer.IsArchive -or $task.status -ne 'pending') {
    Write-JsonResult -Ok $false -Code 'INVALID_TRANSITION' -Message "Only pending tasks can be claimed; current status is $($task.status)." -ExitCode 6
  }
  if ($session.role -ne $task.to_role) {
    Write-JsonResult -Ok $false -Code 'ROLE_MISMATCH' -Message "Task is assigned to $($task.to_role), not $($session.role)." -ExitCode 3
  }
  Assert-TaskDependenciesReady -Task $task

  $staleSources = @(Test-TaskSourcesCurrent -Task $task)
  if ($staleSources.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'STALE_SOURCE' -Message 'Task source changed after creation.' -Data $staleSources -ExitCode 4
  }

  $dirtyScopes = New-Object System.Collections.Generic.List[object]
  $baseline = New-Object System.Collections.Generic.List[object]
  foreach ($scope in @($task.write_scopes)) {
    $status = @(Get-GitPathStatus -RelativePath $scope)
    if ($status.Count -gt 0 -and -not $AdoptDirty) {
      $dirtyScopes.Add([ordered]@{ scope = $scope; status = $status })
    }
    $absolutePath = Join-Path $script:ProjectPath $scope.Replace('/', '\')
    $isFile = Test-Path -LiteralPath $absolutePath -PathType Leaf
    $baseline.Add([ordered]@{
      path = $scope
      exists = $isFile
      sha256 = if ($isFile) { Get-FileSha256 -RelativePath $scope } else { $null }
      git_status = $status
    })
  }
  if ($dirtyScopes.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'DIRTY_SCOPE' -Message 'One or more write scopes already contain unowned changes. Use -AdoptDirty only after explicit confirmation.' -Data $dirtyScopes.ToArray() -ExitCode 3
  }

  $minutes = if ($LeaseMinutes -gt 0) { $LeaseMinutes } else { [int]$config.state.leaseMinutes }
  if ($minutes -lt 5 -or $minutes -gt 1440) {
    Write-JsonResult -Ok $false -Code 'INVALID_LEASE' -Message 'LeaseMinutes must be between 5 and 1440.' -ExitCode 2
  }
  $leaseExpiresAt = [DateTime]::UtcNow.AddMinutes($minutes).ToString('o')
  Acquire-TaskLocks -Task $task -OwnerSession $SessionId -LeaseExpiresAt $leaseExpiresAt

  $timestamp = Get-UtcTimestamp
  $task.status = 'in_progress'
  $task.owner_session = $SessionId
  $task.lease_expires_at = $leaseExpiresAt
  $task.base_head = Get-GitHead
  $task.write_baseline = $baseline.ToArray()
  $task.updated_at = $timestamp
  Write-AtomicJson -Path $taskContainer.Path -Value $task
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  [void](Add-Event -Type 'task_claimed' -EventSummary $task.title -EventTaskId $TaskId -EventChangeId $task.change_id -EventSessionId $SessionId)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_CLAIMED' -Message 'Task claimed.' -Data ([ordered]@{
    task_id = $TaskId
    status = 'in_progress'
    lease_expires_at = $leaseExpiresAt
    base_head = $task.base_head
    task = $task
  })
}

function Renew-StateTask {
  $config = Get-Config
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  if ($taskContainer.IsArchive -or $task.status -ne 'in_progress' -or $task.owner_session -ne $SessionId) {
    Write-JsonResult -Ok $false -Code 'NOT_TASK_OWNER' -Message 'Only the active task owner can renew its lease.' -ExitCode 3
  }
  if ($session.role -ne $task.to_role) {
    Write-JsonResult -Ok $false -Code 'ROLE_MISMATCH' -Message 'Session role does not match task role.' -ExitCode 3
  }
  $minutes = if ($LeaseMinutes -gt 0) { $LeaseMinutes } else { [int]$config.state.leaseMinutes }
  if ($minutes -lt 5 -or $minutes -gt 1440) {
    Write-JsonResult -Ok $false -Code 'INVALID_LEASE' -Message 'LeaseMinutes must be between 5 and 1440.' -ExitCode 2
  }
  $leaseExpiresAt = [DateTime]::UtcNow.AddMinutes($minutes).ToString('o')
  foreach ($scope in @($task.write_scopes)) {
    $lockPath = Get-ScopeLockPath -Scope $scope
    $ownerPath = Join-Path $lockPath 'owner.json'
    if (-not (Test-Path -LiteralPath $ownerPath -PathType Leaf)) {
      Write-JsonResult -Ok $false -Code 'LOCK_MISSING' -Message "Task lock is missing for scope: $scope" -ExitCode 3
    }
    $lock = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($lock.task_id -ne $TaskId -or $lock.session_id -ne $SessionId) {
      Write-JsonResult -Ok $false -Code 'LOCK_CONFLICT' -Message "Task no longer owns scope: $scope" -Data $lock -ExitCode 3
    }
    $lock.lease_expires_at = $leaseExpiresAt
    Write-AtomicJson -Path $ownerPath -Value $lock
  }
  $timestamp = Get-UtcTimestamp
  $task.lease_expires_at = $leaseExpiresAt
  $task.updated_at = $timestamp
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path $taskContainer.Path -Value $task
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'LEASE_RENEWED' -Message 'Task lease renewed.' -Data ([ordered]@{ task_id = $TaskId; lease_expires_at = $leaseExpiresAt })
}

function Assert-TaskOwner {
  param(
    [Parameter(Mandatory = $true)][object]$Task,
    [Parameter(Mandatory = $true)][object]$TaskContainer,
    [Parameter(Mandatory = $true)][object]$Session
  )
  if ($TaskContainer.IsArchive -or $Task.status -ne 'in_progress' -or $Task.owner_session -ne $Session.session_id) {
    Write-JsonResult -Ok $false -Code 'NOT_TASK_OWNER' -Message 'Only the active task owner can perform this transition.' -ExitCode 3
  }
  if ($Session.role -ne $Task.to_role) {
    Write-JsonResult -Ok $false -Code 'ROLE_MISMATCH' -Message 'Session role does not match task role.' -ExitCode 3
  }
}

function Complete-StateTask {
  [void](Get-Config)
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  Assert-TaskOwner -Task $task -TaskContainer $taskContainer -Session $session
  if ([string]::IsNullOrWhiteSpace($Summary) -or $Summary.Length -gt 2000) {
    Write-JsonResult -Ok $false -Code 'INVALID_HANDOFF' -Message 'Summary is required and must not exceed 2000 characters.' -ExitCode 2
  }
  Assert-NoSensitiveText -Values (@($Summary) + @($Verification) + @($Concern) + @($OpenQuestion))

  $staleSources = @(Test-TaskSourcesCurrent -Task $task)
  if ($staleSources.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'STALE_SOURCE' -Message 'Task source changed while work was in progress. Locks remain held for explicit reconciliation.' -Data $staleSources -ExitCode 4
  }
  $headDrift = @(Get-RelatedHeadDrift -Task $task)
  if ($headDrift.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'RELATED_HEAD_DRIFT' -Message 'Git HEAD changed in task-related paths. Locks remain held for explicit reconciliation.' -Data $headDrift -ExitCode 4
  }

  $normalizedChangedFiles = New-Object System.Collections.Generic.List[string]
  foreach ($path in @(Expand-DelimitedValues -Values $ChangedFile)) {
    $normalized = Resolve-SafeRelativePath -RelativePath $path
    if (-not (Test-PathInWriteScopes -RelativePath $normalized -Scopes @($task.write_scopes))) {
      Write-JsonResult -Ok $false -Code 'CHANGED_SCOPE_VIOLATION' -Message "Changed file is outside task write scopes: $normalized" -ExitCode 3
    }
    if (-not $normalizedChangedFiles.Contains($normalized)) { $normalizedChangedFiles.Add($normalized) }
  }

  $timestamp = Get-UtcTimestamp
  $completion = [ordered]@{
    summary = $Summary
    changed_files = $normalizedChangedFiles.ToArray()
    verification = @($Verification)
    concerns = @($Concern)
    open_questions = @($OpenQuestion)
    completed_at = $timestamp
    completed_head = Get-GitHead
  }
  if ($null -eq $task.PSObject.Properties['completion']) {
    $task | Add-Member -NotePropertyName completion -NotePropertyValue ([pscustomobject]$completion)
  } else {
    $task.completion = [pscustomobject]$completion
  }
  $task.status = 'done'
  $task.concerns = @($Concern)
  $task.lease_expires_at = $null
  $task.updated_at = $timestamp

  $archivePath = Join-Path $script:StatePath "records\tasks\archive\$TaskId.json"
  Write-AtomicJson -Path $archivePath -Value $task
  Remove-Item -LiteralPath $taskContainer.Path -Force
  Remove-TaskLocks -Task $task -OwnerSession $SessionId
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  [void](Add-Event -Type 'task_completed' -EventSummary $Summary -EventTaskId $TaskId -EventChangeId $task.change_id -EventSessionId $SessionId -Details $completion)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_COMPLETED' -Message 'Task completed and archived.' -Data ([ordered]@{ task_id = $TaskId; status = 'done'; concerns = @($Concern) })
}

function Block-StateTask {
  [void](Get-Config)
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  Assert-TaskOwner -Task $task -TaskContainer $taskContainer -Session $session
  if ([string]::IsNullOrWhiteSpace($Reason) -or $Reason.Length -gt 2000) {
    Write-JsonResult -Ok $false -Code 'INVALID_HANDOFF' -Message 'Reason is required and must not exceed 2000 characters.' -ExitCode 2
  }
  Assert-NoSensitiveText -Values @($Reason)
  $timestamp = Get-UtcTimestamp
  $task.status = 'blocked'
  if ($null -eq $task.PSObject.Properties['blocked_reason']) {
    $task | Add-Member -NotePropertyName blocked_reason -NotePropertyValue $Reason
  } else {
    $task.blocked_reason = $Reason
  }
  if ($ReleaseLocks) {
    Remove-TaskLocks -Task $task -OwnerSession $SessionId
    $task.owner_session = $null
    $task.lease_expires_at = $null
  }
  $task.updated_at = $timestamp
  Write-AtomicJson -Path $taskContainer.Path -Value $task
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  [void](Add-Event -Type 'task_blocked' -EventSummary $Reason -EventTaskId $TaskId -EventChangeId $task.change_id -EventSessionId $SessionId)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_BLOCKED' -Message 'Task marked blocked.' -Data ([ordered]@{ task_id = $TaskId; released = [bool]$ReleaseLocks })
}

function Release-StateTask {
  [void](Get-Config)
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  Assert-TaskOwner -Task $task -TaskContainer $taskContainer -Session $session
  Remove-TaskLocks -Task $task -OwnerSession $SessionId
  $timestamp = Get-UtcTimestamp
  $task.status = 'pending'
  $task.owner_session = $null
  $task.lease_expires_at = $null
  $task.base_head = $null
  $task.write_baseline = @()
  $task.updated_at = $timestamp
  Write-AtomicJson -Path $taskContainer.Path -Value $task
  $session.last_seen_at = $timestamp
  Write-AtomicJson -Path (Join-Path $script:StatePath "sessions\$SessionId.json") -Value $session
  $message = if ([string]::IsNullOrWhiteSpace($Reason)) { 'Task released.' } else { $Reason }
  [void](Add-Event -Type 'task_released' -EventSummary $message -EventTaskId $TaskId -EventChangeId $task.change_id -EventSessionId $SessionId)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_RELEASED' -Message 'Task returned to pending.' -Data ([ordered]@{ task_id = $TaskId; status = 'pending' })
}

function Test-StagedCommitScope {
  [void](Get-Config)
  $session = Get-SessionRecord -Id $SessionId
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  if ($task.owner_session -ne $SessionId -or $session.role -ne $task.to_role) {
    Write-JsonResult -Ok $false -Code 'NOT_TASK_OWNER' -Message 'Only the task owner can validate a commit.' -ExitCode 3
  }
  $result = Invoke-GitCapture -GitArguments @('diff', '--cached', '--name-only')
  if ($result.ExitCode -ne 0) {
    Write-JsonResult -Ok $false -Code 'GIT_ERROR' -Message 'Unable to inspect staged files.' -ExitCode 1
  }
  $staged = @($result.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $violations = @($staged | Where-Object { -not (Test-PathInWriteScopes -RelativePath $_ -Scopes @($task.write_scopes)) })
  if ($violations.Count -gt 0) {
    Write-JsonResult -Ok $false -Code 'STAGED_SCOPE_VIOLATION' -Message 'Staged files include paths outside the task write scopes.' -Data $violations -ExitCode 3
  }
  Write-JsonResult -Ok $true -Code 'COMMIT_SCOPE_VALID' -Message 'All staged files are inside task write scopes.' -Data ([ordered]@{ staged_files = $staged })
}

function Get-StateStatus {
  [void](Get-Config)
  if (-not [string]::IsNullOrWhiteSpace($TaskId)) {
    $taskContainer = Get-TaskRecord -Id $TaskId
    if (-not [string]::IsNullOrWhiteSpace($Role) -and $taskContainer.Record.to_role -ne $Role) {
      Write-JsonResult -Ok $false -Code 'ROLE_MISMATCH' -Message "Task is assigned to $($taskContainer.Record.to_role), not $Role." -ExitCode 3
    }
    Write-JsonResult -Ok $true -Code 'TASK_STATUS' -Message 'Complete task envelope loaded.' -Data ([ordered]@{
      task = $taskContainer.Record
      archived = [bool]$taskContainer.IsArchive
    })
  }
  $tasks = @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'records\tasks\active'))
  if (-not [string]::IsNullOrWhiteSpace($Role)) {
    if (-not (Test-ValidRole -Value $Role)) {
      Write-JsonResult -Ok $false -Code 'INVALID_ROLE' -Message 'Role has an invalid format.' -ExitCode 2
    }
    $tasks = @($tasks | Where-Object { $_.to_role -eq $Role })
  }
  $summaries = @($tasks | ForEach-Object {
    [pscustomobject][ordered]@{
      task_id = $_.task_id
      change_id = $_.change_id
      title = $_.title
      to_role = $_.to_role
      status = $_.status
      priority = $_.priority
      owner_session = $_.owner_session
      lease_expires_at = $_.lease_expires_at
      depends_on = @($_.depends_on)
    }
  })
  Write-JsonResult -Ok $true -Code 'STATUS' -Message 'Active collaboration state loaded.' -Data ([ordered]@{
    active_tasks = $summaries
    active_task_count = $summaries.Count
  })
}

function Invoke-StateDoctor {
  $config = Get-Config
  $issues = New-Object System.Collections.Generic.List[object]
  $jsonDirectories = @(
    'records\tasks\active', 'records\tasks\archive', 'records\events', 'sessions'
  )
  foreach ($relativeDirectory in $jsonDirectories) {
    $directory = Join-Path $script:StatePath $relativeDirectory
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
      $issues.Add([ordered]@{ type = 'missing_directory'; path = $relativeDirectory })
      continue
    }
    foreach ($file in Get-ChildItem -LiteralPath $directory -Filter '*.json' -File) {
      try { [void](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {
        $issues.Add([ordered]@{ type = 'invalid_json'; path = $file.FullName.Substring($script:ProjectPath.Length + 1) })
      }
    }
  }
  foreach ($view in @('current.md', 'inbox.md', 'events.md', 'locks.md', 'handoff.md')) {
    $path = Join-Path $script:StatePath $view
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      $issues.Add([ordered]@{ type = 'missing_view'; path = ".jingyuan/state/$view" })
    }
  }
  $viewManifestPath = Join-Path $script:StatePath 'records\views.json'
  if (-not (Test-Path -LiteralPath $viewManifestPath -PathType Leaf)) {
    $issues.Add([ordered]@{ type = 'missing_view_manifest'; path = '.jingyuan/state/records/views.json' })
  } else {
    try {
      $viewManifest = Get-Content -LiteralPath $viewManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($view in @('current.md', 'inbox.md', 'events.md', 'locks.md', 'handoff.md')) {
        $viewPath = Join-Path $script:StatePath $view
        if (-not (Test-Path -LiteralPath $viewPath -PathType Leaf)) { continue }
        $expectedHash = [string]$viewManifest.hashes.$view
        $actualHash = (Get-FileHash -LiteralPath $viewPath -Algorithm SHA256).Hash
        if ([string]::IsNullOrWhiteSpace($expectedHash) -or $expectedHash -ne $actualHash) {
          $issues.Add([ordered]@{ type = 'view_out_of_date'; path = ".jingyuan/state/$view" })
        }
      }
    } catch {
      $issues.Add([ordered]@{ type = 'invalid_json'; path = '.jingyuan/state/records/views.json' })
    }
  }

  $activeTasks = @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'records\tasks\active'))
  $cycleTaskIds = @(Get-DependencyCycleTaskIds -Tasks $activeTasks)
  foreach ($task in $activeTasks) {
    foreach ($stale in @(Test-TaskSourcesCurrent -Task $task)) {
      $issues.Add([ordered]@{ type = 'stale_source'; task_id = $task.task_id; path = $stale.path; reason = $stale.reason })
    }
    if ($task.status -eq 'in_progress' -and -not [string]::IsNullOrWhiteSpace([string]$task.lease_expires_at)) {
      if ([DateTime]::Parse($task.lease_expires_at).ToUniversalTime() -lt [DateTime]::UtcNow) {
        $issues.Add([ordered]@{ type = 'expired_task_lease'; task_id = $task.task_id; owner_session = $task.owner_session })
      }
    }
    if ($cycleTaskIds -contains $task.task_id) {
      $issues.Add([ordered]@{ type = 'dependency_cycle'; task_id = $task.task_id })
    }
  }

  $ownedSessionIds = @($activeTasks | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.owner_session) } | ForEach-Object { $_.owner_session } | Select-Object -Unique)
  $sessionCutoff = [DateTime]::UtcNow.AddDays(-[int]$config.state.archiveDays)
  foreach ($session in @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'sessions'))) {
    if ($session.status -eq 'active' -and
        $ownedSessionIds -notcontains $session.session_id -and
        [DateTime]::Parse($session.last_seen_at).ToUniversalTime() -lt $sessionCutoff) {
      $issues.Add([ordered]@{ type = 'orphan_session'; session_id = $session.session_id; last_seen_at = $session.last_seen_at })
    }
  }

  $locksDirectory = Join-Path $script:StatePath 'locks'
  if (Test-Path -LiteralPath $locksDirectory -PathType Container) {
    foreach ($lockDirectory in Get-ChildItem -LiteralPath $locksDirectory -Directory) {
      $ownerPath = Join-Path $lockDirectory.FullName 'owner.json'
      if (-not (Test-Path -LiteralPath $ownerPath -PathType Leaf)) {
        $issues.Add([ordered]@{ type = 'orphan_lock'; path = $lockDirectory.Name; reason = 'missing_owner' })
        continue
      }
      try {
        $lock = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([DateTime]::Parse($lock.lease_expires_at).ToUniversalTime() -lt [DateTime]::UtcNow) {
          $issues.Add([ordered]@{ type = 'expired_lock'; task_id = $lock.task_id; scope = $lock.scope })
        }
        $taskExists = Test-Path -LiteralPath (Join-Path $script:StatePath "records\tasks\active\$($lock.task_id).json") -PathType Leaf
        $sessionExists = Test-Path -LiteralPath (Join-Path $script:StatePath "sessions\$($lock.session_id).json") -PathType Leaf
        if (-not $taskExists -or -not $sessionExists) {
          $issues.Add([ordered]@{ type = 'orphan_lock'; task_id = $lock.task_id; scope = $lock.scope; reason = 'missing_task_or_session' })
        }
      } catch {
        $issues.Add([ordered]@{ type = 'invalid_json'; path = $ownerPath.Substring($script:ProjectPath.Length + 1) })
      }
    }
  }

  $referenced = @($activeTasks | ForEach-Object { @($_.depends_on) } | Select-Object -Unique)
  $archiveCutoff = [DateTime]::UtcNow.AddDays(-[int]$config.state.archiveDays)
  foreach ($archivedTask in @(Get-JsonRecords -Directory (Join-Path $script:StatePath 'records\tasks\archive'))) {
    if ($referenced -notcontains $archivedTask.task_id -and [DateTime]::Parse($archivedTask.updated_at).ToUniversalTime() -lt $archiveCutoff) {
      $issues.Add([ordered]@{ type = 'archive_prune_candidate'; task_id = $archivedTask.task_id })
    }
  }

  Write-JsonResult -Ok $true -Code 'DOCTOR_REPORT' -Message 'State health inspection completed without mutation.' -Data ([ordered]@{
    healthy = $issues.Count -eq 0
    issue_count = $issues.Count
    issues = $issues.ToArray()
  })
}

function Recover-StateTask {
  [void](Get-Config)
  if (-not $ConfirmRecovery) {
    Write-JsonResult -Ok $false -Code 'RECOVERY_CONFIRMATION_REQUIRED' -Message 'Recover requires explicit -ConfirmRecovery.' -ExitCode 2
  }
  $taskContainer = Get-TaskRecord -Id $TaskId
  $task = $taskContainer.Record
  if ($taskContainer.IsArchive -or $task.status -notin @('in_progress', 'blocked', 'needs_context', 'needs_decision')) {
    Write-JsonResult -Ok $false -Code 'INVALID_TRANSITION' -Message "Task status $($task.status) cannot be recovered." -ExitCode 6
  }
  if ($task.status -eq 'in_progress' -and
      -not [string]::IsNullOrWhiteSpace([string]$task.lease_expires_at) -and
      [DateTime]::Parse($task.lease_expires_at).ToUniversalTime() -ge [DateTime]::UtcNow) {
    Write-JsonResult -Ok $false -Code 'LEASE_STILL_ACTIVE' -Message 'An active lease cannot be recovered.' -ExitCode 3
  }
  if (-not [string]::IsNullOrWhiteSpace([string]$task.owner_session)) {
    Remove-TaskLocks -Task $task -OwnerSession $task.owner_session
  }
  $task.status = 'pending'
  $task.owner_session = $null
  $task.lease_expires_at = $null
  $task.base_head = $null
  $task.write_baseline = @()
  $task.updated_at = Get-UtcTimestamp
  Write-AtomicJson -Path $taskContainer.Path -Value $task
  [void](Add-Event -Type 'task_recovered' -EventSummary 'Task recovered to pending after explicit confirmation.' -EventTaskId $TaskId -EventChangeId $task.change_id)
  Rebuild-StateViews
  Write-JsonResult -Ok $true -Code 'TASK_RECOVERED' -Message 'Task recovered to pending.' -Data ([ordered]@{ task_id = $TaskId; status = 'pending' })
}

function Set-LocalStateExcluded {
  $result = Invoke-GitCapture -GitArguments @('rev-parse', '--git-path', 'info/exclude')
  if ($result.ExitCode -ne 0 -or $result.Output.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$result.Output[0])) {
    return
  }

  $excludePath = [string]$result.Output[0]
  if (-not [IO.Path]::IsPathRooted($excludePath)) {
    $excludePath = Join-Path $script:ProjectPath $excludePath
  }
  $excludeDirectory = Split-Path -Parent $excludePath
  if (-not (Test-Path -LiteralPath $excludeDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $excludeDirectory -Force | Out-Null
  }

  $pattern = '/.jingyuan/state/'
  $existing = if (Test-Path -LiteralPath $excludePath -PathType Leaf) {
    Get-Content -LiteralPath $excludePath
  } else {
    @()
  }
  if ($existing -notcontains $pattern) {
    [IO.File]::AppendAllText($excludePath, $pattern + [Environment]::NewLine, $script:Utf8NoBom)
  }
}

function Initialize-State {
  $configDirectory = Join-Path $script:ProjectPath '.jingyuan'
  $configPath = Join-Path $configDirectory 'config.json'
  if (-not (Test-Path -LiteralPath $configDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
  }

  if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    try {
      $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
      Write-JsonResult -Ok $false -Code 'INVALID_CONFIG' -Message 'Existing .jingyuan/config.json is not valid JSON.' -ExitCode 2
    }
    if ([int]$config.version -lt 2) {
      if (-not $Migrate) {
        Write-JsonResult -Ok $false -Code 'MIGRATION_REQUIRED' -Message 'Config version 1 requires explicit -Migrate confirmation.' -ExitCode 2
      }
      $config = Add-StateConfig -Config $config
      Write-AtomicJson -Path $configPath -Value $config
    } elseif ([int]$config.version -gt 2) {
      Write-JsonResult -Ok $false -Code 'UNSUPPORTED_CONFIG' -Message "Config version $($config.version) is newer than this tool supports." -ExitCode 2
    } else {
      $config = Add-StateConfig -Config $config
      Write-AtomicJson -Path $configPath -Value $config
    }
  } else {
    $config = Get-DefaultConfig
    Write-AtomicJson -Path $configPath -Value $config
  }

  foreach ($relativePath in @(
    'records\tasks\active',
    'records\tasks\archive',
    'records\events',
    'sessions',
    'locks'
  )) {
    New-Item -ItemType Directory -Path (Join-Path $script:StatePath $relativePath) -Force | Out-Null
  }
  Rebuild-StateViews
  Set-LocalStateExcluded

  Write-JsonResult -Ok $true -Code 'INITIALIZED' -Message 'JingYuan local collaboration state is ready.' -Data ([ordered]@{
    project_root = $script:ProjectPath
    state_root = $script:StatePath
    config_version = 2
  })
}

try {
  $script:ProjectPath = [IO.Path]::GetFullPath($ProjectRoot)
  if (-not (Test-Path -LiteralPath $script:ProjectPath -PathType Container)) {
    Write-JsonResult -Ok $false -Code 'PROJECT_NOT_FOUND' -Message 'ProjectRoot must be an existing directory.' -ExitCode 5
  }
  $script:StatePath = Join-Path $script:ProjectPath '.jingyuan\state'

  $mutex = $null
  $mutatingActions = @('Init', 'StartSession', 'CreateTask', 'Claim', 'Renew', 'Complete', 'Block', 'Release', 'Recover', 'RebuildViews')
  try {
    if ($Action -in $mutatingActions) { $mutex = Enter-StateMutex }
    switch ($Action) {
      'Init' { Initialize-State }
      'StartSession' { Start-StateSession }
      'CreateTask' { New-StateTask }
      'Claim' { Claim-StateTask }
      'Renew' { Renew-StateTask }
      'Complete' { Complete-StateTask }
      'Block' { Block-StateTask }
      'Release' { Release-StateTask }
      'Status' { Get-StateStatus }
      'Doctor' { Invoke-StateDoctor }
      'Recover' { Recover-StateTask }
      'CheckCommit' { Test-StagedCommitScope }
      'RebuildViews' {
        [void](Get-Config)
        Rebuild-StateViews
        Write-JsonResult -Ok $true -Code 'VIEWS_REBUILT' -Message 'State views rebuilt.'
      }
      default {
        Write-JsonResult -Ok $false -Code 'NOT_IMPLEMENTED' -Message "Action $Action is not implemented yet." -ExitCode 2
      }
    }
  } finally {
    if ($null -ne $mutex) {
      try { $mutex.ReleaseMutex() } catch { }
      $mutex.Dispose()
    }
  }
} catch {
  Write-JsonResult -Ok $false -Code 'UNEXPECTED_ERROR' -Message $_.Exception.Message -ExitCode 1
}
