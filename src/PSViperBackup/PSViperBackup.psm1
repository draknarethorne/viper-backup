Set-StrictMode -Version 2.0

$script:ModuleRoot = $PSScriptRoot
$script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Get-ViperTimestamp {
    [CmdletBinding()]
    param([datetime]$Value = (Get-Date))

    return $Value.ToString('yyyyMMdd-HHmmss', [Globalization.CultureInfo]::InvariantCulture)
}

function Get-RobocopyResult {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][int]$ExitCode)

    $failed = $ExitCode -ge 8
    $severity = if ($failed) {
        'Failure'
    }
    elseif (($ExitCode -band 4) -ne 0) {
        'Warning'
    }
    elseif (($ExitCode -band 2) -ne 0) {
        'Notice'
    }
    else {
        'Success'
    }

    [pscustomobject]@{
        ExitCode = $ExitCode
        Severity = $severity
        Failed = $failed
        FilesCopied = (($ExitCode -band 1) -ne 0)
        ExtraEntries = (($ExitCode -band 2) -ne 0)
        Mismatches = (($ExitCode -band 4) -ne 0)
        CopyFailures = (($ExitCode -band 8) -ne 0)
        FatalError = (($ExitCode -band 16) -ne 0)
    }
}

function ConvertTo-WindowsCommandLineArgument {
    [CmdletBinding()]
    param([AllowEmptyString()][Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Resolve-ViperPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BasePath
    )

    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-ViperPathOverlap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $sourcePath = [Environment]::ExpandEnvironmentVariables($Source).TrimEnd('\', '/')
    $destinationPath = [Environment]::ExpandEnvironmentVariables($Destination).TrimEnd('\', '/')
    try { $sourcePath = [IO.Path]::GetFullPath($sourcePath).TrimEnd('\', '/') } catch {}
    try { $destinationPath = [IO.Path]::GetFullPath($destinationPath).TrimEnd('\', '/') } catch {}
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $separator = [IO.Path]::DirectorySeparatorChar
    return (
        $sourcePath.Equals($destinationPath, $comparison) -or
        $sourcePath.StartsWith("$destinationPath$separator", $comparison) -or
        $destinationPath.StartsWith("$sourcePath$separator", $comparison)
    )
}

function Get-ViperDestinationVolume {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Destination)

    if ($Destination -match '^([A-Za-z]):[\\/]') {
        $letter = $Matches[1]
        try {
            $volume = Get-Volume -DriveLetter $letter -ErrorAction Stop
            return [pscustomobject]@{
                Kind = 'Local'
                DriveLetter = $letter.ToUpperInvariant()
                Label = [string]$volume.FileSystemLabel
                Serial = [string]$volume.UniqueId
                FreeBytes = [int64]$volume.SizeRemaining
                Available = $true
            }
        }
        catch {
            return [pscustomobject]@{
                Kind = 'Local'
                DriveLetter = $letter.ToUpperInvariant()
                Label = $null
                Serial = $null
                FreeBytes = 0
                Available = $false
                Error = $_.Exception.Message
            }
        }
    }

    if ($Destination -match '^\\\\([^\\]+)\\([^\\]+)') {
        $root = "\\$($Matches[1])\$($Matches[2])"
        return [pscustomobject]@{
            Kind = 'Network'
            Root = $root
            Available = (Test-Path -LiteralPath $root -PathType Container)
        }
    }

    return [pscustomobject]@{
        Kind = 'Unknown'
        Available = $false
        Error = 'Destination must use a local drive root or UNC path.'
    }
}

function Assert-ViperDestinationIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Job,
        [scriptblock]$VolumeResolver = ${function:Get-ViperDestinationVolume}
    )

    $volume = & $VolumeResolver ([string]$Job.Destination)
    if (-not $volume.Available) {
        throw "Destination for job '$($Job.Name)' is unavailable."
    }

    if ($volume.Kind -eq 'Local') {
        if (-not $Job.ContainsKey('DestinationVolume')) {
            throw "Job '$($Job.Name)' must declare DestinationVolume identity."
        }
        $identity = $Job.DestinationVolume
        if (-not $identity.ExpectedLabel) {
            throw "Job '$($Job.Name)' must declare DestinationVolume.ExpectedLabel."
        }
        if ([string]$volume.Label -cne [string]$identity.ExpectedLabel) {
            throw "Destination label mismatch for job '$($Job.Name)'. Expected '$($identity.ExpectedLabel)', found '$($volume.Label)'."
        }
        if ($identity.ContainsKey('ExpectedSerial') -and $identity.ExpectedSerial -and ([string]$volume.Serial -ne [string]$identity.ExpectedSerial)) {
            throw "Destination serial mismatch for job '$($Job.Name)'."
        }
        if ($identity.ContainsKey('DriveLetter') -and $identity.DriveLetter -and ([string]$volume.DriveLetter -ine [string]$identity.DriveLetter)) {
            throw "Destination drive-letter mismatch for job '$($Job.Name)'."
        }
        if ($identity.ContainsKey('MinFreeGiB') -and $null -ne $identity.MinFreeGiB) {
            $minimumBytes = [int64]([double]$identity.MinFreeGiB * 1GB)
            if ([int64]$volume.FreeBytes -lt $minimumBytes) {
                throw "Destination free space is below MinFreeGiB for job '$($Job.Name)'."
            }
        }
    }

    return $volume
}

function Test-ViperCloudHydration {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    $offline = 0
    $inspected = 0
    try {
        Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction Stop | ForEach-Object {
            $inspected++
            $attributes = $_.Attributes
            $isOffline = (($attributes -band [IO.FileAttributes]::Offline) -ne 0)
            $isRecall = (($attributes.ToString() -match 'RecallOn(DataAccess|Open)'))
            if ($isOffline -or $isRecall) {
                $offline++
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            InspectedFiles = $inspected
            OfflineFiles = $offline
            FullyHydrated = $false
            Error = $_.Exception.Message
        }
    }

    [pscustomobject]@{
        Available = $true
        InspectedFiles = $inspected
        OfflineFiles = $offline
        FullyHydrated = ($offline -eq 0)
        Error = $null
    }
}

function Test-ViperBackupPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][hashtable]$Plan,
        [switch]$AllowDelete
    )

    $errors = New-Object Collections.Generic.List[string]
    $warnings = New-Object Collections.Generic.List[string]
    $planDefaults = if ($Plan.ContainsKey('Defaults') -and $Plan.Defaults -is [hashtable]) { $Plan.Defaults } else { @{} }
    $defaultMode = if ($planDefaults.ContainsKey('Mode') -and $planDefaults.Mode) { [string]$planDefaults.Mode } else { 'Update' }
    [object[]]$jobs = if ($Plan.ContainsKey('Jobs') -and $Plan.Jobs) { @($Plan.Jobs) } else { @() }

    if (-not $Plan.ContainsKey('SchemaVersion') -or $Plan.SchemaVersion -ne 1) {
        $errors.Add('SchemaVersion must be 1.')
    }
    if ($Plan.ContainsKey('Defaults') -and $Plan.Defaults -isnot [hashtable]) {
        $errors.Add('Defaults must be a hashtable.')
    }
    if (-not $Plan.ContainsKey('Name') -or -not $Plan.Name) {
        $errors.Add('Plan Name is required.')
    }
    if (-not $Plan.ContainsKey('StateDirectory') -or -not $Plan.StateDirectory) {
        $errors.Add('StateDirectory is required.')
    }
    if ($jobs.Count -eq 0) {
        $errors.Add('At least one job is required.')
    }
    if ($defaultMode -notin @('Update', 'Mirror', 'Snapshot')) {
        $errors.Add("Defaults has unsupported Mode '$defaultMode'.")
    }

    $names = @{}
    foreach ($job in $jobs) {
        if ($job -isnot [hashtable]) {
            $errors.Add('Every job must be a hashtable.')
            continue
        }
        if (-not $job.ContainsKey('Name') -or -not $job.Name) {
            $errors.Add('Every job requires a Name.')
            continue
        }
        if ($names.ContainsKey([string]$job.Name)) {
            $errors.Add("Duplicate job name '$($job.Name)'.")
        }
        $names[[string]$job.Name] = $true
        if (-not $job.ContainsKey('Source') -or -not $job.Source) { $errors.Add("Job '$($job.Name)' requires Source.") }
        if (-not $job.ContainsKey('Destination') -or -not $job.Destination) { $errors.Add("Job '$($job.Name)' requires Destination.") }

        $mode = if ($job.ContainsKey('Mode') -and $job.Mode) { [string]$job.Mode } else { $defaultMode }
        if ($mode -notin @('Update', 'Mirror', 'Snapshot')) {
            $errors.Add("Job '$($job.Name)' has unsupported Mode '$mode'.")
        }
        if ($mode -eq 'Mirror') {
            if (-not $job.ContainsKey('AllowDelete') -or -not $job.AllowDelete) {
                $errors.Add("Mirror job '$($job.Name)' must set AllowDelete = `$true in its local plan.")
            }
            if (-not $AllowDelete) {
                $errors.Add("Mirror job '$($job.Name)' also requires invocation-level -AllowDelete.")
            }
        }
        if ($mode -eq 'Snapshot' -and $job.ContainsKey('Destination') -and $job.Destination -match '\{Timestamp\}') {
            $warnings.Add("Snapshot job '$($job.Name)' uses an explicit {Timestamp} token; the runner also supports automatic timestamp suffixes.")
        }
    }

    [pscustomobject]@{
        Valid = ($errors.Count -eq 0)
        Errors = @($errors)
        Warnings = @($warnings)
    }
}

function Get-ViperJobArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Job,
        [Parameter(Mandatory = $true)][hashtable]$Defaults,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [switch]$PlanOnly
    )

    $mode = if ($Job.ContainsKey('Mode') -and $Job.Mode) { [string]$Job.Mode } else { [string]$Defaults.Mode }
    $retry = if ($Job.ContainsKey('RetryCount') -and $null -ne $Job.RetryCount) { [int]$Job.RetryCount } else { [int]$Defaults.RetryCount }
    $wait = if ($Job.ContainsKey('RetryWaitSeconds') -and $null -ne $Job.RetryWaitSeconds) { [int]$Job.RetryWaitSeconds } else { [int]$Defaults.RetryWaitSeconds }
    $threads = if ($Job.ContainsKey('MultiThreadCount') -and $null -ne $Job.MultiThreadCount) { [int]$Job.MultiThreadCount } else { [int]$Defaults.MultiThreadCount }

    $arguments = New-Object Collections.Generic.List[string]
    $arguments.Add([string]$Job.Source)
    $arguments.Add([string]$Job.ResolvedDestination)
    $includeFiles = if ($Job.ContainsKey('IncludeFiles')) { @($Job.IncludeFiles) } else { @() }
    foreach ($pattern in $includeFiles) {
        if ($pattern) { $arguments.Add([string]$pattern) }
    }
    if ($mode -eq 'Mirror') { $arguments.Add('/MIR') } else { $arguments.Add('/E') }
    $arguments.Add('/COPY:DAT')
    $arguments.Add('/DCOPY:DAT')
    $arguments.Add('/XJ')
    $arguments.Add("/R:$retry")
    $arguments.Add("/W:$wait")
    if ($threads -gt 1) { $arguments.Add("/MT:$threads") }
    $arguments.Add('/NP')
    $arguments.Add('/BYTES')
    $arguments.Add('/FP')
    $arguments.Add('/TS')
    $arguments.Add("/LOG:$LogPath")
    if ($PlanOnly) { $arguments.Add('/L') }

    $excludeDirectories = if ($Job.ContainsKey('ExcludeDirectories')) { @($Job.ExcludeDirectories) } else { @() }
    foreach ($directory in $excludeDirectories) {
        if ($directory) {
            $arguments.Add('/XD')
            $arguments.Add([string]$directory)
        }
    }
    $excludeFiles = if ($Job.ContainsKey('ExcludeFiles')) { @($Job.ExcludeFiles) } else { @() }
    foreach ($file in $excludeFiles) {
        if ($file) {
            $arguments.Add('/XF')
            $arguments.Add([string]$file)
        }
    }
    return ,$arguments.ToArray()
}

function Start-ViperRobocopyProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = (Get-Command robocopy.exe -ErrorAction Stop).Source
    $startInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument $_ }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'Robocopy process failed to start.'
    }
    return $process
}

function New-ViperRunLock {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$StateDirectory)

    if (-not (Test-Path -LiteralPath $StateDirectory)) {
        New-Item -ItemType Directory -Path $StateDirectory -Force | Out-Null
    }
    $lockPath = Join-Path $StateDirectory 'viper-backup.lock'
    try {
        $stream = New-Object IO.FileStream($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $writer = New-Object IO.StreamWriter($stream)
        $writer.WriteLine("PID=$PID")
        $writer.WriteLine("StartedUtc=$([datetime]::UtcNow.ToString('o'))")
        $writer.Flush()
        return [pscustomobject]@{ Path = $lockPath; Stream = $stream; Writer = $writer }
    }
    catch {
        throw "Another Viper Backup run may be active. Lock: $lockPath"
    }
}

function Remove-ViperRunLock {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Lock)

    try { $Lock.Writer.Dispose() } catch {}
    try { $Lock.Stream.Dispose() } catch {}
    Remove-Item -LiteralPath $Lock.Path -Force -ErrorAction SilentlyContinue
}

function Get-ViperRetentionCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateRange(1, 10000)][int]$KeepLast = 30,
        [ValidateRange(1, 36500)][int]$MaxAgeDays = 90,
        [datetime]$Now = (Get-Date)
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return @() }
    $cutoff = $Now.AddDays(-$MaxAgeDays)
    $items = @(Get-ChildItem -LiteralPath $Path -Directory -Force | Sort-Object LastWriteTimeUtc -Descending)
    $keep = @()
    for ($index = 0; $index -lt [Math]::Min($KeepLast, $items.Count); $index++) {
        $keep += $items[$index].FullName
    }
    return @($items | Where-Object {
        $_.LastWriteTimeUtc -lt $cutoff -and $_.FullName -notin $keep
    })
}

function Remove-ViperBackupRunHistory {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)][string]$StateDirectory,
        [ValidateRange(1, 10000)][int]$KeepLast = 30,
        [ValidateRange(1, 36500)][int]$MaxAgeDays = 90
    )

    $resolved = [IO.Path]::GetFullPath($StateDirectory).TrimEnd('\', '/')
    $stateRoot = [IO.Path]::GetFullPath((Join-Path $script:RepositoryRoot 'state')).TrimEnd('\', '/')
    $comparison = [StringComparison]::OrdinalIgnoreCase
    if (-not ($resolved.Equals($stateRoot, $comparison) -or $resolved.StartsWith("$stateRoot\", $comparison))) {
        throw 'Run-history cleanup is restricted to this repository state directory.'
    }
    foreach ($candidate in @(Get-ViperRetentionCandidates -Path $resolved -KeepLast $KeepLast -MaxAgeDays $MaxAgeDays)) {
        if ($PSCmdlet.ShouldProcess($candidate.FullName, 'Remove expired Viper Backup run history')) {
            Remove-Item -LiteralPath $candidate.FullName -Recurse -Force
        }
    }
}

function Write-ViperRunSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Summary,
        [Parameter(Mandatory = $true)][string]$RunPath
    )

    $jsonPath = Join-Path $RunPath 'summary.json'
    $textPath = Join-Path $RunPath 'summary.txt'
    $Summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    $lines = @(
        "Viper Backup Run: $($Summary.RunId)"
        "Plan: $($Summary.PlanName)"
        "Mode: $($Summary.Mode)"
        "Status: $($Summary.Status)"
    )
    if ($Summary.Contains('Error') -and $Summary.Error) { $lines += "Error: $($Summary.Error)" }
    $lines += ''
    $lines += 'Jobs:'
    foreach ($result in @($Summary.Results)) {
        $exitCode = if ($result.PSObject.Properties['ExitCode'] -and $null -ne $result.ExitCode) { $result.ExitCode } else { 'n/a' }
        $severity = if ($result.PSObject.Properties['Severity'] -and $result.Severity) { $result.Severity } else { 'n/a' }
        $lines += "- $($result.Name): $($result.Status) (exit=$exitCode, severity=$severity)"
    }
    $lines | Set-Content -LiteralPath $textPath -Encoding UTF8
    return [pscustomobject]@{ Json = $jsonPath; Text = $textPath }
}

function Invoke-ViperBackupPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PlanPath,
        [switch]$Execute,
        [switch]$AllowDelete,
        [ValidateRange(1, 16)][int]$MaxParallelJobs = 1,
        [scriptblock]$VolumeResolver = ${function:Get-ViperDestinationVolume},
        [scriptblock]$ProcessStarter = ${function:Start-ViperRobocopyProcess}
    )

    $planFile = (Resolve-Path -LiteralPath $PlanPath -ErrorAction Stop).Path
    $plan = Import-PowerShellDataFile -LiteralPath $planFile
    $validation = Test-ViperBackupPlan -Plan $plan -AllowDelete:$AllowDelete
    if (-not $validation.Valid) {
        throw ($validation.Errors -join [Environment]::NewLine)
    }

    $statePath = Resolve-ViperPath -Path ([string]$plan.StateDirectory) -BasePath $script:RepositoryRoot
    $lock = New-ViperRunLock -StateDirectory $statePath
    $runId = $null
    $runPath = $null
    $startedUtc = [datetime]::UtcNow.ToString('o')
    $results = New-Object Collections.Generic.List[object]
    $pending = New-Object Collections.Queue
    $output = $null

    try {
        $runId = Get-ViperTimestamp
        $runPath = Join-Path $statePath $runId
        $suffix = 0
        while (Test-Path -LiteralPath $runPath) {
            $suffix++
            $runPath = Join-Path $statePath ("{0}-{1:D2}" -f $runId, $suffix)
        }
        $runId = Split-Path -Leaf $runPath
        New-Item -ItemType Directory -Path $runPath | Out-Null

        $planDefaults = if ($plan.ContainsKey('Defaults')) { $plan.Defaults } else { @{} }
        $defaults = @{
            Mode = if ($planDefaults.ContainsKey('Mode') -and $planDefaults.Mode) { $planDefaults.Mode } else { 'Update' }
            RetryCount = if ($planDefaults.ContainsKey('RetryCount') -and $null -ne $planDefaults.RetryCount) { $planDefaults.RetryCount } else { 1 }
            RetryWaitSeconds = if ($planDefaults.ContainsKey('RetryWaitSeconds') -and $null -ne $planDefaults.RetryWaitSeconds) { $planDefaults.RetryWaitSeconds } else { 2 }
            MultiThreadCount = if ($planDefaults.ContainsKey('MultiThreadCount') -and $null -ne $planDefaults.MultiThreadCount) { $planDefaults.MultiThreadCount } else { 4 }
        }

        foreach ($sourceJob in @($plan.Jobs)) {
            if ($sourceJob.ContainsKey('Enabled') -and -not $sourceJob.Enabled) {
                $results.Add([pscustomobject]@{ Name = $sourceJob.Name; Status = 'Disabled'; ExitCode = $null; Log = $null })
                continue
            }
            $job = @{}
            foreach ($key in $sourceJob.Keys) { $job[$key] = $sourceJob[$key] }
            $job.Source = [Environment]::ExpandEnvironmentVariables([string]$job.Source)
            $job.Destination = [Environment]::ExpandEnvironmentVariables([string]$job.Destination)
            if (Test-ViperPathOverlap -Source $job.Source -Destination $job.Destination) {
                throw "Source and destination overlap for job '$($job.Name)'."
            }
            if (-not (Test-Path -LiteralPath $job.Source -PathType Container)) {
                if ($job.ContainsKey('Required') -and $job.Required) { throw "Required source for job '$($job.Name)' is unavailable: $($job.Source)" }
                $results.Add([pscustomobject]@{ Name = $job.Name; Status = 'SkippedUnavailable'; ExitCode = $null; Log = $null })
                continue
            }

            [void](Assert-ViperDestinationIdentity -Job $job -VolumeResolver $VolumeResolver)
            if ($job.ContainsKey('CloudAware') -and $job.CloudAware) {
                $hydration = Test-ViperCloudHydration -Path $job.Source
                if (-not $hydration.Available -or -not $hydration.FullyHydrated) {
                    throw "Cloud-aware job '$($job.Name)' is unavailable or contains online-only files."
                }
            }

            $mode = if ($job.ContainsKey('Mode') -and $job.Mode) { [string]$job.Mode } else { [string]$defaults.Mode }
            if ($mode -eq 'Snapshot') {
                $job.ResolvedDestination = Join-Path $job.Destination $runId
            }
            else {
                $job.ResolvedDestination = $job.Destination
            }
            $safeName = ([string]$job.Name -replace '[^A-Za-z0-9._-]', '_')
            $logPath = Join-Path $runPath "$safeName.robocopy.log"
            $arguments = Get-ViperJobArguments -Job $job -Defaults $defaults -LogPath $logPath -PlanOnly:(-not $Execute)
            $pending.Enqueue([pscustomobject]@{ Job = $job; Arguments = $arguments; LogPath = $logPath })
        }

        while ($pending.Count -gt 0) {
            $active = New-Object Collections.Generic.List[object]
            try {
                while ($pending.Count -gt 0 -and $active.Count -lt $MaxParallelJobs) {
                    $item = $pending.Dequeue()
                    $process = & $ProcessStarter $item.Arguments
                    $active.Add([pscustomobject]@{ Item = $item; Process = $process })
                }
            }
            catch {
                foreach ($started in $active) {
                    try { $started.Process.WaitForExit() } catch {}
                }
                throw
            }
            $batchFailures = New-Object Collections.Generic.List[string]
            foreach ($entry in $active) {
                $entry.Process.WaitForExit()
                $classification = Get-RobocopyResult -ExitCode ([int]$entry.Process.ExitCode)
                $status = if ($classification.Failed) { 'Failed' } elseif ($Execute) { 'Completed' } else { 'Planned' }
                $results.Add([pscustomobject]@{
                    Name = $entry.Item.Job.Name
                    Mode = if ($entry.Item.Job.ContainsKey('Mode') -and $entry.Item.Job.Mode) { $entry.Item.Job.Mode } else { $defaults.Mode }
                    Status = $status
                    ExitCode = $classification.ExitCode
                    Severity = $classification.Severity
                    Log = $entry.Item.LogPath
                })
                if ($classification.Failed) {
                    $batchFailures.Add("'$($entry.Item.Job.Name)' (exit $($classification.ExitCode))")
                }
            }
            if ($batchFailures.Count -gt 0) {
                throw "Robocopy failed for job(s): $($batchFailures -join ', ')."
            }
        }

        $summary = [ordered]@{
            SchemaVersion = 1
            RunId = $runId
            PlanName = $plan.Name
            Mode = if ($Execute) { 'Execute' } else { 'PlanOnly' }
            Status = 'Completed'
            StartedUtc = $startedUtc
            CompletedUtc = [datetime]::UtcNow.ToString('o')
            Results = $results.ToArray()
        }
        $summaryPaths = Write-ViperRunSummary -Summary $summary -RunPath $runPath
        if ($Execute -and $plan.ContainsKey('RunRetention') -and $plan.RunRetention.ContainsKey('AutoTrim') -and $plan.RunRetention.AutoTrim) {
            $keepLast = if ($plan.RunRetention.ContainsKey('KeepLast') -and $plan.RunRetention.KeepLast) { [int]$plan.RunRetention.KeepLast } else { 30 }
            $maxAgeDays = if ($plan.RunRetention.ContainsKey('MaxAgeDays') -and $plan.RunRetention.MaxAgeDays) { [int]$plan.RunRetention.MaxAgeDays } else { 90 }
            Remove-ViperBackupRunHistory -StateDirectory $statePath -KeepLast $keepLast -MaxAgeDays $maxAgeDays -Confirm:$false
        }
        $output = [pscustomobject]@{ RunId = $runId; RunPath = $runPath; SummaryPath = $summaryPaths.Json; TextSummaryPath = $summaryPaths.Text; Results = $results.ToArray() }
    }
    catch {
        $failure = $_
        if ($runPath -and (Test-Path -LiteralPath $runPath -PathType Container)) {
            $summary = [ordered]@{
                SchemaVersion = 1
                RunId = $runId
                PlanName = $plan.Name
                Mode = if ($Execute) { 'Execute' } else { 'PlanOnly' }
                Status = 'Failed'
                StartedUtc = $startedUtc
                CompletedUtc = [datetime]::UtcNow.ToString('o')
                Error = $failure.Exception.Message
                Results = $results.ToArray()
            }
            [void](Write-ViperRunSummary -Summary $summary -RunPath $runPath)
        }
        throw
    }
    finally {
        Remove-ViperRunLock -Lock $lock
    }
    return $output
}

Export-ModuleMember -Function @(
    'Assert-ViperDestinationIdentity',
    'ConvertTo-WindowsCommandLineArgument',
    'Get-RobocopyResult',
    'Get-ViperJobArguments',
    'Get-ViperRetentionCandidates',
    'Get-ViperTimestamp',
    'Invoke-ViperBackupPlan',
    'Remove-ViperBackupRunHistory',
    'Test-ViperBackupPlan',
    'Test-ViperCloudHydration',
    'Test-ViperPathOverlap'
)
