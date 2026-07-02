[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$stateScript = Join-Path $root 'plugins\jingyuan\scripts\jingyuan-state.ps1'
$script:Passed = 0

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw "ASSERTION FAILED: $Message"
  }
  $script:Passed++
}

function Invoke-State {
  param(
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stateScript @Arguments 2>&1
  $exitCode = $LASTEXITCODE
  $text = ($output | Out-String).Trim()
  $json = $null
  if (-not [string]::IsNullOrWhiteSpace($text)) {
    try {
      $json = $text | ConvertFrom-Json
    } catch {
      throw "State command returned non-JSON output (exit $exitCode): $text"
    }
  }

  [pscustomobject]@{
    ExitCode = $exitCode
    Json = $json
    Text = $text
  }
}

function New-TestProject {
  $path = Join-Path $env:TEMP ("jingyuan-state-test-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $path | Out-Null
  & git -C $path init --quiet
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to initialize test Git repository.'
  }
  return $path
}

if (-not (Test-Path -LiteralPath $stateScript -PathType Leaf)) {
  throw "Missing state tool: $stateScript"
}

$projects = New-Object System.Collections.Generic.List[string]
try {
  $project = New-TestProject
  $projects.Add($project)

  $init = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $project)
  Assert-True ($init.ExitCode -eq 0) 'Init should succeed.'
  Assert-True ($init.Json.ok -eq $true) 'Init should return ok=true.'

  $configPath = Join-Path $project '.jingyuan\config.json'
  Assert-True (Test-Path -LiteralPath $configPath -PathType Leaf) 'Init should create config.json.'
  $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($config.version -eq 3) 'New config should use version 3.'
  Assert-True ($config.state.enabled -eq $true) 'State should be enabled for new projects.'
  Assert-True ($config.state.mode -eq 'local') 'State mode should default to local.'
  Assert-True ($config.docs.feedbackDir -eq 'docs/feedback') 'Version 3 config should expose feedbackDir.'
  Assert-True ($null -eq $config.docs.PSObject.Properties['prdChangelog']) 'Version 3 config should omit prdChangelog.'
  Assert-True ($null -eq $config.docs.PSObject.Properties['mockup']) 'Version 3 config should omit mockup.'
  Assert-True ($null -eq $config.docs.PSObject.Properties['feedbackIndex']) 'Version 3 config should omit feedbackIndex.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $project 'docs'))) 'State initialization should not create docs scaffolding.'
  $configBytes = [IO.File]::ReadAllBytes($configPath)
  Assert-True ($configBytes[0] -eq 0x7B) 'Generated JSON should be UTF-8 without BOM.'

  foreach ($relativePath in @(
    '.jingyuan\state\records\tasks\active',
    '.jingyuan\state\records\tasks\archive',
    '.jingyuan\state\records\events',
    '.jingyuan\state\sessions',
    '.jingyuan\state\locks'
  )) {
    Assert-True (Test-Path -LiteralPath (Join-Path $project $relativePath) -PathType Container) "Init should create $relativePath."
  }

  foreach ($view in @('current.md', 'inbox.md', 'events.md', 'locks.md', 'handoff.md')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $project ".jingyuan\state\$view") -PathType Leaf) "Init should create $view."
  }
  $viewBytes = [IO.File]::ReadAllBytes((Join-Path $project '.jingyuan\state\current.md'))
  Assert-True ($viewBytes[0] -eq 0xEF -and $viewBytes[1] -eq 0xBB -and $viewBytes[2] -eq 0xBF) 'Generated Markdown views should use UTF-8 with BOM.'
  Assert-True (Test-Path -LiteralPath (Join-Path $project '.jingyuan\state\records\views.json') -PathType Leaf) 'Init should create a generated-view hash manifest.'

  $excludePath = Join-Path $project '.git\info\exclude'
  $exclude = Get-Content -LiteralPath $excludePath -Raw
  Assert-True ($exclude -match '(?m)^/\.jingyuan/state/\r?$') 'Init should exclude local state from Git.'

  $secondInit = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $project)
  Assert-True ($secondInit.ExitCode -eq 0) 'Init should be idempotent.'

  $noGitProject = Join-Path $env:TEMP ("jingyuan-state-nogit-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $noGitProject | Out-Null
  $projects.Add($noGitProject)
  $noGitInit = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $noGitProject)
  Assert-True ($noGitInit.ExitCode -eq 0) 'Init should support a readable project that is not a Git repository.'
  $noGitSession = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $noGitProject, '-Role', 'pm')
  $noGitSessionId = [string]$noGitSession.Json.data.session_id
  $noGitTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $noGitProject, '-SessionId', $noGitSessionId,
    '-Title', 'No Git fallback', '-FromRole', 'pm', '-ToRole', 'pm', '-WriteScope', 'docs/output.md'
  )
  $noGitClaim = Invoke-State -Arguments @(
    '-Action', 'Claim', '-ProjectRoot', $noGitProject, '-SessionId', $noGitSessionId,
    '-TaskId', ([string]$noGitTask.Json.data.task_id)
  )
  Assert-True ($noGitClaim.ExitCode -eq 0) 'Claim should use a null HEAD and skip Git dirtiness checks outside a Git repository.'
  $noGitClaimedRecord = Get-Content -LiteralPath (Join-Path $noGitProject ".jingyuan\state\records\tasks\active\$($noGitTask.Json.data.task_id).json") -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($null -eq $noGitClaimedRecord.base_head) 'Non-Git task should persist base_head=null.'

  New-Item -ItemType Directory -Path (Join-Path $project 'docs\PRD') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $project 'docs\design') -Force | Out-Null
  [IO.File]::WriteAllText(
    (Join-Path $project 'docs\PRD\prd.md'),
    "# PRD`r`n`r`n## Login`r`n",
    [Text.UTF8Encoding]::new($true)
  )
  & git -C $project config user.name 'JingYuan Test'
  & git -C $project config user.email 'jingyuan-test@example.invalid'
  & git -C $project add .
  & git -C $project commit --quiet -m 'test baseline'
  Assert-True ($LASTEXITCODE -eq 0) 'Test project baseline commit should succeed.'

  $session = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $project, '-Role', 'pm')
  Assert-True ($session.ExitCode -eq 0) 'StartSession should succeed for a valid role.'
  Assert-True ($session.Json.data.session_id -match '^session-pm-[0-9a-f]{12}$') 'StartSession should return a stable role-prefixed session ID.'
  $sessionId = [string]$session.Json.data.session_id
  Assert-True (Test-Path -LiteralPath (Join-Path $project ".jingyuan\state\sessions\$sessionId.json")) 'StartSession should persist a session record.'

  $task = Invoke-State -Arguments @(
    '-Action', 'CreateTask',
    '-ProjectRoot', $project,
    '-SessionId', $sessionId,
    '-ChangeId', 'change-login-oauth',
    '-Title', 'Update login design',
    '-FromRole', 'pm',
    '-ToRole', 'design',
    '-Priority', 'High',
    '-ReadRef', 'docs/PRD/prd.md#Login',
    '-WriteScope', 'docs/design/design.md',
    '-AcceptanceCriterion', 'Design documents the login states'
  )
  Assert-True ($task.ExitCode -eq 0) 'CreateTask should succeed with valid inputs.'
  Assert-True ($task.Json.data.task_id -match '^task-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$') 'CreateTask should generate a unique task ID.'
  $taskId = [string]$task.Json.data.task_id
  $taskPath = Join-Path $project ".jingyuan\state\records\tasks\active\$taskId.json"
  Assert-True (Test-Path -LiteralPath $taskPath -PathType Leaf) 'CreateTask should persist one active task record.'
  $taskRecord = Get-Content -LiteralPath $taskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($taskRecord.status -eq 'pending') 'New task should be pending.'
  Assert-True ($taskRecord.to_role -eq 'design') 'Task should have exactly one receiving role.'
  Assert-True ($taskRecord.read_refs.Count -eq 1) 'Task should persist its read reference.'
  Assert-True ($taskRecord.read_refs[0].sha256 -match '^[A-F0-9]{64}$') 'Task should snapshot the source SHA-256.'
  Assert-True ($taskRecord.write_scopes[0] -eq 'docs/design/design.md') 'Task should persist normalized write scopes.'

  $compactStatus = Invoke-State -Arguments @('-Action', 'Status', '-ProjectRoot', $project, '-Role', 'design')
  Assert-True ($compactStatus.ExitCode -eq 0) 'Role Status should succeed.'
  $compactTask = @($compactStatus.Json.data.active_tasks | Where-Object { $_.task_id -eq $taskId })[0]
  Assert-True ($null -eq $compactTask.PSObject.Properties['read_refs']) 'Role Status should return compact task summaries without full read references.'
  Assert-True ($null -eq $compactTask.PSObject.Properties['acceptance_criteria']) 'Role Status should omit acceptance detail until a task is selected.'
  $fullTaskStatus = Invoke-State -Arguments @('-Action', 'Status', '-ProjectRoot', $project, '-TaskId', $taskId)
  Assert-True ($fullTaskStatus.ExitCode -eq 0) 'Task-specific Status should succeed.'
  Assert-True ($fullTaskStatus.Json.data.task.read_refs[0].path -eq 'docs/PRD/prd.md') 'Task-specific Status should return the complete envelope.'

  $beforeInvalidCount = @(Get-ChildItem -LiteralPath (Join-Path $project '.jingyuan\state\records\tasks\active') -Filter '*.json').Count
  $invalidPath = Invoke-State -Arguments @(
    '-Action', 'CreateTask',
    '-ProjectRoot', $project,
    '-SessionId', $sessionId,
    '-Title', 'Escape project root',
    '-FromRole', 'pm',
    '-ToRole', 'design',
    '-WriteScope', '..\outside.txt'
  )
  Assert-True ($invalidPath.ExitCode -eq 2) 'CreateTask should reject path traversal.'
  Assert-True ($invalidPath.Json.code -eq 'INVALID_PATH') 'Path traversal should return INVALID_PATH.'
  $afterInvalidCount = @(Get-ChildItem -LiteralPath (Join-Path $project '.jingyuan\state\records\tasks\active') -Filter '*.json').Count
  Assert-True ($afterInvalidCount -eq $beforeInvalidCount) 'Rejected tasks should not leave state records.'

  $sensitiveTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Use token=super-secret-value', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/sensitive.md'
  )
  Assert-True ($sensitiveTask.ExitCode -eq 2) 'CreateTask should reject likely secrets in state text.'
  Assert-True ($sensitiveTask.Json.code -eq 'SENSITIVE_CONTENT') 'Likely secret should return SENSITIVE_CONTENT.'

  $designSession = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $project, '-Role', 'design')
  Assert-True ($designSession.ExitCode -eq 0) 'Design session should start.'
  $designSessionId = [string]$designSession.Json.data.session_id
  $claim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $taskId)
  Assert-True ($claim.ExitCode -eq 0) 'Receiving role should claim a pending task.'
  $claimedRecord = Get-Content -LiteralPath $taskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($claimedRecord.status -eq 'in_progress') 'Claim should transition task to in_progress.'
  Assert-True ($claimedRecord.owner_session -eq $designSessionId) 'Claim should record the owner session.'
  Assert-True ($claimedRecord.base_head -match '^[0-9a-f]{40}$') 'Claim should snapshot Git HEAD.'
  Assert-True ($claim.Json.data.task.read_refs[0].path -eq 'docs/PRD/prd.md') 'Claim should return the complete task envelope for downstream execution.'
  Assert-True ($claim.Json.data.task.write_scopes[0] -eq 'docs/design/design.md') 'Claim should expose the exclusive write scope without another broad status read.'
  Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $project '.jingyuan\state\locks') -Directory).Count -eq 1) 'Claim should acquire one resource lock.'

  $secondTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Conflicting design task', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/design.md'
  )
  Assert-True ($secondTask.ExitCode -eq 0) 'A second pending task may describe the same scope.'
  $secondTaskId = [string]$secondTask.Json.data.task_id
  $secondDesignSession = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $project, '-Role', 'design')
  $secondDesignSessionId = [string]$secondDesignSession.Json.data.session_id
  $conflictingClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $secondTaskId)
  Assert-True ($conflictingClaim.ExitCode -eq 3) 'A second session should not claim an occupied scope.'
  Assert-True ($conflictingClaim.Json.code -eq 'LOCK_CONFLICT') 'Occupied scope should return LOCK_CONFLICT.'

  $disjointTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Disjoint design task', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/other.md'
  )
  $disjointTaskId = [string]$disjointTask.Json.data.task_id
  $disjointClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $disjointTaskId)
  Assert-True ($disjointClaim.ExitCode -eq 0) 'Disjoint write scopes should be claimable concurrently.'

  $dependencyTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Wait for design', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/dependent.md', '-DependsOn', $taskId
  )
  $dependencyTaskId = [string]$dependencyTask.Json.data.task_id
  $dependencyClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $dependencyTaskId)
  Assert-True ($dependencyClaim.ExitCode -eq 3) 'Claim should reject incomplete dependencies.'
  Assert-True ($dependencyClaim.Json.code -eq 'DEPENDENCY_NOT_READY') 'Incomplete dependency should return DEPENDENCY_NOT_READY.'

  [IO.File]::WriteAllText((Join-Path $project 'docs\design\dirty.md'), 'unowned change', [Text.UTF8Encoding]::new($false))
  $dirtyTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Adopt dirty design', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/dirty.md'
  )
  $dirtyTaskId = [string]$dirtyTask.Json.data.task_id
  $dirtyClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $dirtyTaskId)
  Assert-True ($dirtyClaim.ExitCode -eq 3) 'Claim should reject unowned dirty target paths.'
  Assert-True ($dirtyClaim.Json.code -eq 'DIRTY_SCOPE') 'Dirty target should return DIRTY_SCOPE.'
  $adoptedClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $dirtyTaskId, '-AdoptDirty')
  Assert-True ($adoptedClaim.ExitCode -eq 0) 'Explicit AdoptDirty should accept the current target baseline.'

  $beforeRenew = [DateTime]::Parse([string](Get-Content -LiteralPath $taskPath -Raw -Encoding UTF8 | ConvertFrom-Json).lease_expires_at)
  $renew = Invoke-State -Arguments @('-Action', 'Renew', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $taskId, '-LeaseMinutes', '240')
  Assert-True ($renew.ExitCode -eq 0) 'Task owner should renew its lease.'
  $afterRenew = [DateTime]::Parse([string](Get-Content -LiteralPath $taskPath -Raw -Encoding UTF8 | ConvertFrom-Json).lease_expires_at)
  Assert-True ($afterRenew -gt $beforeRenew) 'Renew should extend lease expiry.'

  [IO.File]::WriteAllText((Join-Path $project 'unrelated.txt'), 'parallel commit', [Text.UTF8Encoding]::new($false))
  & git -C $project add unrelated.txt
  & git -C $project commit --quiet -m 'unrelated parallel change'
  Assert-True ($LASTEXITCODE -eq 0) 'An unrelated parallel commit should succeed.'
  [IO.File]::WriteAllText((Join-Path $project 'docs\design\design.md'), '# Login design', [Text.UTF8Encoding]::new($true))
  & git -C $project add docs/design/design.md
  $allowedCommit = Invoke-State -Arguments @('-Action', 'CheckCommit', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $taskId)
  Assert-True ($allowedCommit.ExitCode -eq 0) 'CheckCommit should allow staged files inside task scopes.'
  [IO.File]::WriteAllText((Join-Path $project 'outside.md'), 'outside task', [Text.UTF8Encoding]::new($false))
  & git -C $project add outside.md
  $blockedCommit = Invoke-State -Arguments @('-Action', 'CheckCommit', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $taskId)
  Assert-True ($blockedCommit.ExitCode -eq 3) 'CheckCommit should reject unrelated staged files.'
  Assert-True ($blockedCommit.Json.code -eq 'STAGED_SCOPE_VIOLATION') 'Unrelated staged file should return STAGED_SCOPE_VIOLATION.'
  & git -C $project reset --quiet -- outside.md

  $complete = Invoke-State -Arguments @(
    '-Action', 'Complete', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $taskId,
    '-Summary', 'Login design updated', '-ChangedFile', 'docs/design/design.md',
    '-Verification', 'New-Item -Path state-command-must-not-run.txt'
  )
  Assert-True ($complete.ExitCode -eq 0) 'Complete should allow unrelated HEAD drift.'
  Assert-True (-not (Test-Path -LiteralPath $taskPath)) 'Completed task should leave the active directory.'
  $archivedTaskPath = Join-Path $project ".jingyuan\state\records\tasks\archive\$taskId.json"
  Assert-True (Test-Path -LiteralPath $archivedTaskPath -PathType Leaf) 'Completed task should move to short-term archive.'
  $archivedTask = Get-Content -LiteralPath $archivedTaskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($archivedTask.status -eq 'done') 'Completed task should be done.'
  Assert-True ($archivedTask.completion.summary -eq 'Login design updated') 'Completion should persist handoff summary.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $project 'state-command-must-not-run.txt'))) 'Verification evidence must never be executed as a command.'

  $dependencyClaimAfterDone = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $dependencyTaskId)
  Assert-True ($dependencyClaimAfterDone.ExitCode -eq 0) 'A dependent task should become claimable after dependency completion.'
  $blockedTask = Invoke-State -Arguments @(
    '-Action', 'Block', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $dependencyTaskId,
    '-Reason', 'Needs product decision', '-ReleaseLocks'
  )
  Assert-True ($blockedTask.ExitCode -eq 0) 'Task owner should block and hand off a task.'
  $blockedTaskPath = Join-Path $project ".jingyuan\state\records\tasks\active\$dependencyTaskId.json"
  $blockedRecord = Get-Content -LiteralPath $blockedTaskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($blockedRecord.status -eq 'blocked') 'Block should persist blocked status.'
  Assert-True ($null -eq $blockedRecord.owner_session) 'Block with ReleaseLocks should clear ownership.'

  $released = Invoke-State -Arguments @('-Action', 'Release', '-ProjectRoot', $project, '-SessionId', $secondDesignSessionId, '-TaskId', $dirtyTaskId, '-Reason', 'Pause work')
  Assert-True ($released.ExitCode -eq 0) 'Task owner should release a task.'
  $releasedTaskPath = Join-Path $project ".jingyuan\state\records\tasks\active\$dirtyTaskId.json"
  $releasedRecord = Get-Content -LiteralPath $releasedTaskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($releasedRecord.status -eq 'pending') 'Release should return task to pending.'

  $sourceBytes = [IO.File]::ReadAllBytes((Join-Path $project 'docs\PRD\prd.md'))
  $staleTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Stale source check', '-FromRole', 'pm', '-ToRole', 'design',
    '-ReadRef', 'docs/PRD/prd.md#Login', '-WriteScope', 'docs/design/stale.md'
  )
  $staleTaskId = [string]$staleTask.Json.data.task_id
  $staleClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $staleTaskId)
  Assert-True ($staleClaim.ExitCode -eq 0) 'Fresh source task should be claimable.'
  [IO.File]::AppendAllText((Join-Path $project 'docs\PRD\prd.md'), "changed`r`n", [Text.UTF8Encoding]::new($true))
  $staleComplete = Invoke-State -Arguments @(
    '-Action', 'Complete', '-ProjectRoot', $project, '-SessionId', $designSessionId, '-TaskId', $staleTaskId,
    '-Summary', 'Should not complete'
  )
  Assert-True ($staleComplete.ExitCode -eq 4) 'Complete should reject changed source documents.'
  Assert-True ($staleComplete.Json.code -eq 'STALE_SOURCE') 'Changed source should return STALE_SOURCE.'
  [IO.File]::WriteAllBytes((Join-Path $project 'docs\PRD\prd.md'), $sourceBytes)

  $missingViewPath = Join-Path $project '.jingyuan\state\handoff.md'
  Remove-Item -LiteralPath $missingViewPath -Force
  $doctor = Invoke-State -Arguments @('-Action', 'Doctor', '-ProjectRoot', $project)
  Assert-True ($doctor.ExitCode -eq 0) 'Doctor should report health issues without mutating state.'
  Assert-True (@($doctor.Json.data.issues | Where-Object { $_.type -eq 'missing_view' }).Count -eq 1) 'Doctor should detect a manually deleted view.'
  Assert-True (-not (Test-Path -LiteralPath $missingViewPath)) 'Doctor should not silently repair missing views.'
  $rebuild = Invoke-State -Arguments @('-Action', 'RebuildViews', '-ProjectRoot', $project)
  Assert-True ($rebuild.ExitCode -eq 0) 'RebuildViews should explicitly repair generated views.'
  Assert-True (Test-Path -LiteralPath $missingViewPath -PathType Leaf) 'RebuildViews should recreate missing views.'
  [IO.File]::AppendAllText((Join-Path $project '.jingyuan\state\current.md'), "tampered`r`n", [Text.UTF8Encoding]::new($true))
  $tamperedDoctor = Invoke-State -Arguments @('-Action', 'Doctor', '-ProjectRoot', $project)
  Assert-True (@($tamperedDoctor.Json.data.issues | Where-Object { $_.type -eq 'view_out_of_date' -and $_.path -eq '.jingyuan/state/current.md' }).Count -eq 1) 'Doctor should detect a manually edited generated view.'
  [void](Invoke-State -Arguments @('-Action', 'RebuildViews', '-ProjectRoot', $project))

  $status = Invoke-State -Arguments @('-Action', 'Status', '-ProjectRoot', $project, '-Role', 'design')
  Assert-True ($status.ExitCode -eq 0) 'Status should read active state by role.'
  Assert-True (@($status.Json.data.active_tasks | Where-Object { $_.to_role -ne 'design' }).Count -eq 0) 'Role status should not return other roles.'

  $recoverWithoutConfirmation = Invoke-State -Arguments @('-Action', 'Recover', '-ProjectRoot', $project, '-TaskId', $dependencyTaskId)
  Assert-True ($recoverWithoutConfirmation.ExitCode -eq 2) 'Recover should require explicit confirmation.'
  $recoverBlocked = Invoke-State -Arguments @('-Action', 'Recover', '-ProjectRoot', $project, '-TaskId', $dependencyTaskId, '-ConfirmRecovery')
  Assert-True ($recoverBlocked.ExitCode -eq 0) 'Explicit recovery should return a blocked task to pending.'

  $concurrentTaskA = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Concurrent A', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/concurrent.md'
  )
  $concurrentTaskB = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Concurrent B', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/concurrent.md'
  )
  $jobA = Start-Job -ScriptBlock {
    param($ScriptPath, $RootPath, $OwnerId, $ClaimTaskId)
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Action Claim -ProjectRoot $RootPath -SessionId $OwnerId -TaskId $ClaimTaskId 2>&1
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String).Trim(); TaskId = $ClaimTaskId }
  } -ArgumentList $stateScript, $project, $designSessionId, ([string]$concurrentTaskA.Json.data.task_id)
  $jobB = Start-Job -ScriptBlock {
    param($ScriptPath, $RootPath, $OwnerId, $ClaimTaskId)
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Action Claim -ProjectRoot $RootPath -SessionId $OwnerId -TaskId $ClaimTaskId 2>&1
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String).Trim(); TaskId = $ClaimTaskId }
  } -ArgumentList $stateScript, $project, $secondDesignSessionId, ([string]$concurrentTaskB.Json.data.task_id)
  $concurrentResults = @($jobA, $jobB | Receive-Job -Wait)
  Remove-Job -Job $jobA, $jobB -Force
  $concurrentExitCodes = @($concurrentResults | ForEach-Object { [int]$_.ExitCode } | Sort-Object)
  Assert-True (($concurrentExitCodes -join ',') -eq '0,3') 'Exactly one concurrent claimant should acquire an overlapping scope.'

  $winningResult = $concurrentResults | Where-Object { $_.ExitCode -eq 0 } | Select-Object -First 1
  $winningTaskId = [string]$winningResult.TaskId
  $winningTask = Get-Content -LiteralPath (Join-Path $project ".jingyuan\state\records\tasks\active\$winningTaskId.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $thirdDesignSession = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $project, '-Role', 'design')
  $thirdDesignSessionId = [string]$thirdDesignSession.Json.data.session_id
  $rollbackTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Multi-lock rollback', '-FromRole', 'pm', '-ToRole', 'design',
    '-WriteScope', 'docs/design/a-free.md;docs/design/concurrent.md'
  )
  $rollbackClaim = Invoke-State -Arguments @('-Action', 'Claim', '-ProjectRoot', $project, '-SessionId', $thirdDesignSessionId, '-TaskId', ([string]$rollbackTask.Json.data.task_id))
  Assert-True ($rollbackClaim.ExitCode -eq 3) 'A multi-scope claim should fail when one later scope is occupied.'
  $freeScopeLocks = @(
    Get-ChildItem -LiteralPath (Join-Path $project '.jingyuan\state\locks') -Directory | ForEach-Object {
      $owner = Join-Path $_.FullName 'owner.json'
      if (Test-Path -LiteralPath $owner) { Get-Content -LiteralPath $owner -Raw -Encoding UTF8 | ConvertFrom-Json }
    } | Where-Object { $_.scope -eq 'docs/design/a-free.md' }
  )
  Assert-True ($freeScopeLocks.Count -eq 0) 'Failed multi-scope claim should roll back earlier acquired locks.'

  $staleTaskPath = Join-Path $project ".jingyuan\state\records\tasks\active\$staleTaskId.json"
  $expiredRecord = Get-Content -LiteralPath $staleTaskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $expiredRecord.lease_expires_at = [DateTime]::UtcNow.AddMinutes(-5).ToString('o')
  [IO.File]::WriteAllText($staleTaskPath, ($expiredRecord | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))
  foreach ($scope in @($expiredRecord.write_scopes)) {
    foreach ($lockDirectory in Get-ChildItem -LiteralPath (Join-Path $project '.jingyuan\state\locks') -Directory) {
      $ownerPath = Join-Path $lockDirectory.FullName 'owner.json'
      if (-not (Test-Path -LiteralPath $ownerPath)) { continue }
      $owner = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($owner.task_id -eq $staleTaskId) {
        $owner.lease_expires_at = [DateTime]::UtcNow.AddMinutes(-5).ToString('o')
        [IO.File]::WriteAllText($ownerPath, ($owner | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
      }
    }
  }
  $orphanSessionPath = Join-Path $project ".jingyuan\state\sessions\$thirdDesignSessionId.json"
  $orphanSession = Get-Content -LiteralPath $orphanSessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $orphanSession.last_seen_at = [DateTime]::UtcNow.AddDays(-31).ToString('o')
  [IO.File]::WriteAllText($orphanSessionPath, ($orphanSession | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
  $expiredDoctor = Invoke-State -Arguments @('-Action', 'Doctor', '-ProjectRoot', $project)
  Assert-True (@($expiredDoctor.Json.data.issues | Where-Object { $_.type -eq 'expired_task_lease' -and $_.task_id -eq $staleTaskId }).Count -eq 1) 'Doctor should report an expired task lease.'
  Assert-True (@($expiredDoctor.Json.data.issues | Where-Object { $_.type -eq 'expired_lock' -and $_.task_id -eq $staleTaskId }).Count -eq 1) 'Doctor should report an expired resource lock.'
  Assert-True (@($expiredDoctor.Json.data.issues | Where-Object { $_.type -eq 'orphan_session' -and $_.session_id -eq $thirdDesignSessionId }).Count -eq 1) 'Doctor should report a stale session with no active task.'
  $recoverExpired = Invoke-State -Arguments @('-Action', 'Recover', '-ProjectRoot', $project, '-TaskId', $staleTaskId, '-ConfirmRecovery')
  Assert-True ($recoverExpired.ExitCode -eq 0) 'Explicit recovery should reclaim an expired task.'
  $recoveredRecord = Get-Content -LiteralPath $staleTaskPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($recoveredRecord.status -eq 'pending') 'Recovered expired task should return to pending.'

  $cycleTaskA = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Cycle A', '-FromRole', 'pm', '-ToRole', 'design', '-WriteScope', 'docs/design/cycle-a.md'
  )
  $cycleTaskB = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $project, '-SessionId', $sessionId,
    '-Title', 'Cycle B', '-FromRole', 'pm', '-ToRole', 'design', '-WriteScope', 'docs/design/cycle-b.md'
  )
  $cycleTaskAId = [string]$cycleTaskA.Json.data.task_id
  $cycleTaskBId = [string]$cycleTaskB.Json.data.task_id
  $cyclePathA = Join-Path $project ".jingyuan\state\records\tasks\active\$cycleTaskAId.json"
  $cyclePathB = Join-Path $project ".jingyuan\state\records\tasks\active\$cycleTaskBId.json"
  $cycleRecordA = Get-Content -LiteralPath $cyclePathA -Raw -Encoding UTF8 | ConvertFrom-Json
  $cycleRecordB = Get-Content -LiteralPath $cyclePathB -Raw -Encoding UTF8 | ConvertFrom-Json
  $cycleRecordA.depends_on = @($cycleTaskBId)
  $cycleRecordB.depends_on = @($cycleTaskAId)
  [IO.File]::WriteAllText($cyclePathA, ($cycleRecordA | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($cyclePathB, ($cycleRecordB | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))
  $cycleDoctor = Invoke-State -Arguments @('-Action', 'Doctor', '-ProjectRoot', $project)
  $cycleIssues = @($cycleDoctor.Json.data.issues | Where-Object { $_.type -eq 'dependency_cycle' })
  Assert-True (@($cycleIssues | Where-Object { $_.task_id -eq $cycleTaskAId }).Count -eq 1) 'Doctor should detect the first task in a dependency cycle.'
  Assert-True (@($cycleIssues | Where-Object { $_.task_id -eq $cycleTaskBId }).Count -eq 1) 'Doctor should detect the second task in a dependency cycle.'

  $legacyProject = New-TestProject
  $projects.Add($legacyProject)
  New-Item -ItemType Directory -Path (Join-Path $legacyProject '.jingyuan') | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $legacyProject 'docs\PRD') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $legacyProject 'docs\design') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $legacyProject 'docs\changes\auth') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $legacyProject 'docs\feedback') -Force | Out-Null
  $legacyConfig = @'
{
  "version": 1,
  "docs": {
    "prd": "custom/prd.md"
  },
  "contextMode": "single",
  "createdBy": "legacy"
}
'@
  [IO.File]::WriteAllText(
    (Join-Path $legacyProject '.jingyuan\config.json'),
    $legacyConfig,
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\PRD\changelog.md'), "# PRD changes`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\design\design.md'), "# Design`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\design\mockup.md'), "# Mockup`r`n`r`nFigma: file-1`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\changes\auth\proposal.md'), "# Proposal`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\changes\auth\spec.md'), "# Spec`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\changes\auth\design.md'), "# Change Design`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\changes\auth\tasks.md'), "# Tasks`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\feedback\auth.md'), "---`r`ntype: feedback`r`nstatus: open`r`nscopes: [auth]`r`ntags: [login]`r`nupdated: 2026-07-02`r`n---`r`n# Auth feedback`r`n", [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\feedback\index.md'), "# Feedback Index`r`n`r`n- [Auth](auth.md) - login`r`n", [Text.UTF8Encoding]::new($true))
  $contextTemplate = Get-Content -LiteralPath (Join-Path $root 'plugins\jingyuan\assets\templates\context-template.md') -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $legacyProject 'docs\context.md'), $contextTemplate, [Text.UTF8Encoding]::new($true))
  & git -C $legacyProject add .
  & git -C $legacyProject -c user.name='JingYuan Test' -c user.email='jingyuan-test@example.invalid' commit --quiet -m 'legacy baseline'
  Assert-True ($LASTEXITCODE -eq 0) 'Legacy migration fixture should have a clean Git baseline.'

  $withoutMigration = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $legacyProject)
  Assert-True ($withoutMigration.ExitCode -eq 2) 'Version 1 config should require explicit migration.'
  $unchangedConfig = Get-Content -LiteralPath (Join-Path $legacyProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($unchangedConfig.version -eq 1) 'Rejected migration should not change config version.'

  $deprecatedMigration = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $legacyProject, '-Migrate')
  Assert-True ($deprecatedMigration.ExitCode -eq 2) 'Init -Migrate should direct callers to the explicit migration action.'

  $previewMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $legacyProject, '-Preview')
  Assert-True ($previewMigration.ExitCode -eq 0) 'Migration preview should succeed without writing files.'
  Assert-True ($previewMigration.Json.code -eq 'MIGRATION_PREVIEW') 'Migration preview should return a stable code.'
  $previewConfig = Get-Content -LiteralPath (Join-Path $legacyProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($previewConfig.version -eq 1) 'Migration preview should not change config version.'
  Assert-True (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\design\mockup.md')) 'Migration preview should not delete legacy files.'

  $withoutConfirmation = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $legacyProject)
  Assert-True ($withoutConfirmation.ExitCode -eq 2) 'Destructive migration should require explicit confirmation.'

  $withMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $legacyProject, '-ConfirmDestructiveMigration')
  Assert-True ($withMigration.ExitCode -eq 0) 'Confirmed migration should succeed.'
  $migratedConfig = Get-Content -LiteralPath (Join-Path $legacyProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($migratedConfig.version -eq 3) 'Explicit migration should update config version.'
  Assert-True ($migratedConfig.docs.prd -eq 'custom/prd.md') 'Migration should preserve custom docs paths.'
  Assert-True ($migratedConfig.docs.feedbackDir -eq 'docs/feedback') 'Migration should add the version 3 feedback directory.'
  Assert-True ($migratedConfig.createdBy -eq 'legacy') 'Migration should preserve existing fields.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\PRD\changelog.md'))) 'Migration should remove PRD changelog.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\design\mockup.md'))) 'Migration should remove mockup.md.'
  Assert-True ((Get-Content -LiteralPath (Join-Path $legacyProject 'docs\design\design.md') -Raw -Encoding UTF8) -match '## Design Artifacts') 'Migration should merge mockup details into design.md.'
  Assert-True (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\changes\auth.md')) 'Migration should create one change document.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\changes\auth'))) 'Migration should remove the legacy change directory.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\feedback\index.md'))) 'Migration should remove a fully mapped feedback index.'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyProject 'docs\context.md'))) 'Migration should remove a template-equivalent context file.'

  $repeatMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $legacyProject, '-Preview')
  Assert-True ($repeatMigration.ExitCode -eq 0 -and $repeatMigration.Json.code -eq 'ALREADY_CURRENT') 'Migration should be idempotent for version 3 projects.'

  $partialProject = New-TestProject
  $projects.Add($partialProject)
  New-Item -ItemType Directory -Path (Join-Path $partialProject '.jingyuan') | Out-Null
  $partialConfig = @'
{
  "version": 2,
  "docs": {
    "prd": "kept/prd.md"
  },
  "state": {
    "enabled": true,
    "mode": "local"
  },
  "customField": "keep-me"
}
'@
  [IO.File]::WriteAllText((Join-Path $partialProject '.jingyuan\config.json'), $partialConfig, [Text.UTF8Encoding]::new($false))
  & git -C $partialProject add .
  & git -C $partialProject -c user.name='JingYuan Test' -c user.email='jingyuan-test@example.invalid' commit --quiet -m 'partial config baseline'
  $partialMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $partialProject, '-ConfirmDestructiveMigration')
  Assert-True ($partialMigration.ExitCode -eq 0) 'Version 2 config should migrate directly to version 3.'
  $partialInit = Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $partialProject)
  Assert-True ($partialInit.ExitCode -eq 0) 'Version 3 config should receive missing state defaults idempotently.'
  $completedConfig = Get-Content -LiteralPath (Join-Path $partialProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True ($completedConfig.state.root -eq '.jingyuan/state') 'Init should fill missing state root.'
  Assert-True ($completedConfig.state.leaseMinutes -eq 120) 'Init should fill missing lease default.'
  Assert-True ($completedConfig.docs.prd -eq 'kept/prd.md') 'Migration should preserve custom docs paths.'
  Assert-True ($completedConfig.customField -eq 'keep-me') 'Migration should preserve unrelated fields.'

  $noGitMigrationProject = Join-Path $env:TEMP ("jingyuan-state-migrate-nogit-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path (Join-Path $noGitMigrationProject '.jingyuan') -Force | Out-Null
  $projects.Add($noGitMigrationProject)
  [IO.File]::WriteAllText((Join-Path $noGitMigrationProject '.jingyuan\config.json'), '{"version":2}', [Text.UTF8Encoding]::new($false))
  $noGitMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $noGitMigrationProject, '-ConfirmDestructiveMigration')
  Assert-True ($noGitMigration.ExitCode -eq 2 -and $noGitMigration.Json.code -eq 'MIGRATION_REQUIRES_GIT') 'Migration should reject non-Git projects.'
  Assert-True ((Get-Content -LiteralPath (Join-Path $noGitMigrationProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json).version -eq 2) 'Rejected non-Git migration should not change config.'

  $dirtyMigrationProject = New-TestProject
  $projects.Add($dirtyMigrationProject)
  New-Item -ItemType Directory -Path (Join-Path $dirtyMigrationProject '.jingyuan') | Out-Null
  [IO.File]::WriteAllText((Join-Path $dirtyMigrationProject '.jingyuan\config.json'), '{"version":2}', [Text.UTF8Encoding]::new($false))
  & git -C $dirtyMigrationProject add .
  & git -C $dirtyMigrationProject -c user.name='JingYuan Test' -c user.email='jingyuan-test@example.invalid' commit --quiet -m 'dirty migration baseline'
  [IO.File]::WriteAllText((Join-Path $dirtyMigrationProject 'dirty.txt'), 'dirty', [Text.UTF8Encoding]::new($false))
  $dirtyMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $dirtyMigrationProject, '-ConfirmDestructiveMigration')
  Assert-True ($dirtyMigration.ExitCode -eq 3 -and $dirtyMigration.Json.code -eq 'MIGRATION_REQUIRES_CLEAN_GIT') 'Migration should reject a dirty working tree.'
  Assert-True ((Get-Content -LiteralPath (Join-Path $dirtyMigrationProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json).version -eq 2) 'Rejected dirty migration should not change config.'

  $conflictMigrationProject = New-TestProject
  $projects.Add($conflictMigrationProject)
  New-Item -ItemType Directory -Path (Join-Path $conflictMigrationProject '.jingyuan') | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $conflictMigrationProject 'docs\changes\auth') -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $conflictMigrationProject '.jingyuan\config.json'), '{"version":2}', [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText((Join-Path $conflictMigrationProject 'docs\changes\auth\proposal.md'), '# Proposal', [Text.UTF8Encoding]::new($true))
  [IO.File]::WriteAllText((Join-Path $conflictMigrationProject 'docs\changes\auth.md'), '# Existing target', [Text.UTF8Encoding]::new($true))
  & git -C $conflictMigrationProject add .
  & git -C $conflictMigrationProject -c user.name='JingYuan Test' -c user.email='jingyuan-test@example.invalid' commit --quiet -m 'conflict migration baseline'
  $conflictMigration = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $conflictMigrationProject, '-ConfirmDestructiveMigration')
  Assert-True ($conflictMigration.ExitCode -eq 3 -and $conflictMigration.Json.code -eq 'MIGRATION_CONFLICT') 'Migration should reject an existing change target.'
  Assert-True ((Get-Content -LiteralPath (Join-Path $conflictMigrationProject '.jingyuan\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json).version -eq 2) 'Conflict rejection should not change config.'
  Assert-True (Test-Path -LiteralPath (Join-Path $conflictMigrationProject 'docs\changes\auth\proposal.md')) 'Conflict rejection should preserve source files.'

  $feedbackConflictProject = New-TestProject
  $projects.Add($feedbackConflictProject)
  New-Item -ItemType Directory -Path (Join-Path $feedbackConflictProject '.jingyuan') | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $feedbackConflictProject 'docs\feedback') -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $feedbackConflictProject '.jingyuan\config.json'), '{"version":2}', [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText((Join-Path $feedbackConflictProject 'docs\feedback\index.md'), "# Feedback Index`r`n`r`n- [Missing](missing.md) - absent`r`n", [Text.UTF8Encoding]::new($true))
  & git -C $feedbackConflictProject add .
  & git -C $feedbackConflictProject -c user.name='JingYuan Test' -c user.email='jingyuan-test@example.invalid' commit --quiet -m 'feedback conflict baseline'
  $feedbackConflict = Invoke-State -Arguments @('-Action', 'Migrate', '-ProjectRoot', $feedbackConflictProject, '-ConfirmDestructiveMigration')
  Assert-True ($feedbackConflict.ExitCode -eq 3 -and $feedbackConflict.Json.code -eq 'MIGRATION_CONFLICT') 'Migration should reject feedback index entries without topic files.'
  Assert-True (Test-Path -LiteralPath (Join-Path $feedbackConflictProject 'docs\feedback\index.md')) 'Feedback conflict should preserve the index.'

  $workflowProject = New-TestProject
  $projects.Add($workflowProject)
  [void](Invoke-State -Arguments @('-Action', 'Init', '-ProjectRoot', $workflowProject))
  & git -C $workflowProject config user.name 'JingYuan Test'
  & git -C $workflowProject config user.email 'jingyuan-test@example.invalid'
  & git -C $workflowProject add .jingyuan/config.json
  & git -C $workflowProject commit --quiet -m 'workflow baseline'
  Assert-True ($LASTEXITCODE -eq 0) 'Workflow fixture should have a Git baseline.'

  $roles = @('coordinator', 'pm', 'design', 'dev-plan', 'dev-builder', 'review', 'fix')
  $workflowSessions = @{}
  foreach ($workflowRole in $roles) {
    $started = Invoke-State -Arguments @('-Action', 'StartSession', '-ProjectRoot', $workflowProject, '-Role', $workflowRole)
    Assert-True ($started.ExitCode -eq 0) "Workflow should start $workflowRole session."
    $workflowSessions[$workflowRole] = [string]$started.Json.data.session_id
  }

  $workflowSteps = @(
    [pscustomobject]@{ Role = 'pm'; Path = 'docs/PRD/prd.md'; NextRole = 'design'; NextPath = 'docs/design/design.md' },
    [pscustomobject]@{ Role = 'design'; Path = 'docs/design/design.md'; NextRole = 'dev-plan'; NextPath = 'docs/development/plan.md' },
    [pscustomobject]@{ Role = 'dev-plan'; Path = 'docs/development/plan.md'; NextRole = 'dev-builder'; NextPath = 'src/feature.txt' },
    [pscustomobject]@{ Role = 'dev-builder'; Path = 'src/feature.txt'; NextRole = 'review'; NextPath = 'docs/review/review-chain.md' },
    [pscustomobject]@{ Role = 'review'; Path = 'docs/review/review-chain.md'; NextRole = 'fix'; NextPath = 'docs/bug-fix/fix-chain.md' },
    [pscustomobject]@{ Role = 'fix'; Path = 'docs/bug-fix/fix-chain.md'; NextRole = 'review'; NextPath = 'docs/review/review-chain-final.md' },
    [pscustomobject]@{ Role = 'review'; Path = 'docs/review/review-chain-final.md'; NextRole = $null; NextPath = $null }
  )
  $firstWorkflowTask = Invoke-State -Arguments @(
    '-Action', 'CreateTask', '-ProjectRoot', $workflowProject, '-SessionId', $workflowSessions['coordinator'],
    '-ChangeId', 'change-workflow-chain', '-Title', 'PM defines requirement',
    '-FromRole', 'coordinator', '-ToRole', 'pm', '-WriteScope', $workflowSteps[0].Path
  )
  $currentWorkflowTaskId = [string]$firstWorkflowTask.Json.data.task_id
  foreach ($step in $workflowSteps) {
    $claimStep = Invoke-State -Arguments @(
      '-Action', 'Claim', '-ProjectRoot', $workflowProject,
      '-SessionId', $workflowSessions[$step.Role], '-TaskId', $currentWorkflowTaskId
    )
    Assert-True ($claimStep.ExitCode -eq 0) "Workflow role $($step.Role) should claim its task."
    $absoluteOutput = Join-Path $workflowProject $step.Path.Replace('/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteOutput) -Force | Out-Null
    [IO.File]::WriteAllText($absoluteOutput, "$($step.Role) output", [Text.UTF8Encoding]::new($true))

    $nextTaskId = $null
    if ($null -ne $step.NextRole) {
      $nextTask = Invoke-State -Arguments @(
        '-Action', 'CreateTask', '-ProjectRoot', $workflowProject,
        '-SessionId', $workflowSessions[$step.Role], '-ChangeId', 'change-workflow-chain',
        '-Title', "$($step.NextRole) consumes $($step.Role) output",
        '-FromRole', $step.Role, '-ToRole', $step.NextRole,
        '-WriteScope', $step.NextPath, '-DependsOn', $currentWorkflowTaskId
      )
      Assert-True ($nextTask.ExitCode -eq 0) "Workflow role $($step.Role) should create one downstream task."
      $nextTaskId = [string]$nextTask.Json.data.task_id
    }
    $completeStep = Invoke-State -Arguments @(
      '-Action', 'Complete', '-ProjectRoot', $workflowProject,
      '-SessionId', $workflowSessions[$step.Role], '-TaskId', $currentWorkflowTaskId,
      '-Summary', "$($step.Role) step completed", '-ChangedFile', $step.Path,
      '-Verification', 'fixture verification: passed'
    )
    Assert-True ($completeStep.ExitCode -eq 0) "Workflow role $($step.Role) should complete its task."
    $currentWorkflowTaskId = $nextTaskId
  }
  $workflowStatus = Invoke-State -Arguments @('-Action', 'Status', '-ProjectRoot', $workflowProject)
  Assert-True ($workflowStatus.Json.data.active_task_count -eq 0) 'PM-to-review/fix workflow should close every active task.'
  Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $workflowProject '.jingyuan\state\records\tasks\archive') -Filter '*.json').Count -eq 7) 'Workflow should archive all seven role tasks.'

  Write-Host "JingYuan state tests passed: $script:Passed assertions."
} finally {
  foreach ($path in $projects) {
    if (Test-Path -LiteralPath $path) {
      Remove-Item -LiteralPath $path -Recurse -Force
    }
  }
}
