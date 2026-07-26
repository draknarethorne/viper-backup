. "$PSScriptRoot\PesterAssertionCompatibility.ps1"

$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

Describe 'Viper Backup core safety behavior' {
    It 'uses sortable invariant timestamps' {
        Get-ViperTimestamp -Value ([datetime]'2026-07-25T18:45:30') | Should -Be '20260725-184530'
    }

    It 'classifies Robocopy codes 0 through 7 as nonfatal' {
        foreach ($code in 0..7) {
            (Get-RobocopyResult -ExitCode $code).Failed | Should -Be $false
        }
    }

    It 'classifies Robocopy codes 8 and above as failures' {
        foreach ($code in @(8, 9, 16, 24)) {
            (Get-RobocopyResult -ExitCode $code).Failed | Should -Be $true
        }
    }

    It 'quotes paths with spaces for Windows process invocation' {
        ConvertTo-WindowsCommandLineArgument 'C:\Example Data\Backup' | Should -Be '"C:\Example Data\Backup"'
    }

    It 'requires both mirror delete authorizations' {
        $plan = @{
            SchemaVersion = 1
            Name = 'Mirror test'
            StateDirectory = 'state\runs'
            Jobs = @(@{
                Name = 'Mirror'
                Source = 'C:\Source'
                Destination = 'D:\Destination'
                Mode = 'Mirror'
                AllowDelete = $false
            })
        }
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
        $plan.Jobs[0].AllowDelete = $true
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
        (Test-ViperBackupPlan -Plan $plan -AllowDelete).Valid | Should -Be $true
    }

    It 'requires both delete authorizations for inherited Mirror mode' {
        $plan = @{
            SchemaVersion = 1
            Name = 'Inherited mirror gate'
            StateDirectory = 'state\runs'
            Defaults = @{ Mode = 'Mirror' }
            Jobs = @(@{
                Name = 'Mirror'
                Source = 'C:\Source'
                Destination = 'D:\Destination'
                AllowDelete = $true
            })
        }
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
        (Test-ViperBackupPlan -Plan $plan -AllowDelete).Valid | Should -Be $true
    }

    It 'allows a disabled Mirror job without deletion authorization' {
        $plan = @{
            SchemaVersion = 1
            Name = 'Disabled mirror'
            StateDirectory = 'state\runs'
            Jobs = @(@{
                Name = 'Mirror'
                Enabled = $false
                Source = 'C:\Source'
                Destination = 'D:\Destination'
                Mode = 'Mirror'
                AllowDelete = $false
            })
        }
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $true
    }

    It 'reports malformed plan structures without throwing' {
        $plan = @{ Defaults = 'invalid'; Jobs = @('invalid') }
        $result = Test-ViperBackupPlan -Plan $plan
        $result.Valid | Should -Be $false
        $result.Errors.Count | Should -BeGreaterThan 3
    }

    It 'rejects invalid or descending stages' {
        $plan = @{
            SchemaVersion = 1
            Name = 'Stage validation'
            StateDirectory = 'state\runs'
            Jobs = @(
                @{ Name = 'Later'; Source = 'C:\One'; Destination = 'D:\One'; Stage = 2 }
                @{ Name = 'Earlier'; Source = 'C:\Two'; Destination = 'D:\Two'; Stage = 1 }
            )
        }
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
        $plan.Jobs[1].Stage = 0
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
        $plan.Jobs[0].Stage = 2
        $plan.Jobs[1].Remove('Stage')
        (Test-ViperBackupPlan -Plan $plan).Valid | Should -Be $false
    }

    It 'rejects a mismatched destination label' {
        $job = @{
            Name = 'Identity test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Wrong'; Serial = 'x' } }
        { Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver } | Should -Throw
    }

    It 'accepts a matching destination label' {
        $job = @{
            Name = 'Identity test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Expected'; Serial = 'x' } }
        (Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver).Label | Should -Be 'Expected'
    }

    It 'rejects insufficient destination free space' {
        $job = @{
            Name = 'Space test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null; MinFreeGiB = 10 }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Expected'; Serial = 'x'; FreeBytes = 1GB } }
        { Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver } | Should -Throw
    }

    It 'rejects nested or identical source and destination paths' {
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'C:\Data' | Should -Be $true
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'C:\Data\Backup' | Should -Be $true
        Test-ViperPathOverlap -Source 'C:\Data\Backup' -Destination 'C:\Data' | Should -Be $true
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'D:\Backup' | Should -Be $false
    }

    It 'adds list-only and avoids mirror flags for Update plans' {
        $job = @{
            Name = 'Plan'
            Source = 'C:\Source'
            ResolvedDestination = 'D:\Destination'
            Mode = 'Update'
            IncludeFiles = @()
            ExcludeDirectories = @('Temp Folder')
            ExcludeFiles = @('*.tmp')
        }
        $defaults = @{ Mode = 'Update'; RetryCount = 1; RetryWaitSeconds = 2; MultiThreadCount = 4 }
        $arguments = Get-ViperJobArguments -Job $job -Defaults $defaults -LogPath 'C:\Logs\job.log' -PlanOnly
        $arguments -contains '/L' | Should -Be $true
        $arguments -contains '/E' | Should -Be $true
        $arguments -contains '/MIR' | Should -Be $false
        $arguments -contains 'Temp Folder' | Should -Be $true
    }

    It 'detects hydrated ordinary temporary files' {
        $path = Join-Path $TestDrive 'cloud'
        New-Item -ItemType Directory -Path $path | Out-Null
        Set-Content -LiteralPath (Join-Path $path 'local.txt') -Value 'fixture'
        $result = Test-ViperCloudHydration -Path $path
        $result.Available | Should -Be $true
        $result.FullyHydrated | Should -Be $true
        $result.InspectedFiles | Should -Be 1
    }
}

Describe 'Run-history retention' {
    It 'keeps the newest count even when old' {
        $root = Join-Path $TestDrive 'runs'
        New-Item -ItemType Directory -Path $root | Out-Null
        foreach ($index in 1..4) {
            $item = New-Item -ItemType Directory -Path (Join-Path $root "run-$index")
            $item.LastWriteTimeUtc = ([datetime]'2026-01-01').AddDays($index)
        }
        $candidates = @(Get-ViperRetentionCandidates -Path $root -KeepLast 2 -MaxAgeDays 30 -Now ([datetime]'2026-07-25'))
        $candidates.Count | Should -Be 2
        ($candidates.Name -contains 'run-1') | Should -Be $true
        ($candidates.Name -contains 'run-2') | Should -Be $true
    }

    It 'previews safely, removes only expired history, and rejects outside paths' {
        $fixtureRoot = Join-Path (Join-Path $PSScriptRoot '..\state') ("retention-test-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $oldest = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '20200101-000000') -Force
            $newest = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '20200102-000000') -Force
            $oldest.LastWriteTimeUtc = [datetime]'2020-01-01T00:00:00Z'
            $newest.LastWriteTimeUtc = [datetime]'2020-01-02T00:00:00Z'

            Remove-ViperBackupRunHistory -StateDirectory $fixtureRoot -KeepLast 1 -MaxAgeDays 1 -WhatIf -Confirm:$false
            Test-Path -LiteralPath $oldest.FullName | Should -Be $true

            Remove-ViperBackupRunHistory -StateDirectory $fixtureRoot -KeepLast 1 -MaxAgeDays 1 -Confirm:$false
            Test-Path -LiteralPath $oldest.FullName | Should -Be $false
            Test-Path -LiteralPath $newest.FullName | Should -Be $true
            { Remove-ViperBackupRunHistory -StateDirectory $TestDrive -Confirm:$false } | Should -Throw
        }
        finally {
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Plan-only orchestration with fake processes' {
    It 'uses list-only, skips optional sources, and writes a summary' {
        $source = Join-Path $TestDrive 'source'
        $destination = Join-Path $TestDrive 'destination'
        $state = Join-Path $TestDrive 'state'
        New-Item -ItemType Directory -Path $source, $destination | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'fixture.txt') -Value 'fixture'
        $planPath = Join-Path $TestDrive 'plan.psd1'
        $escapedSource = $source.Replace("'", "''")
        $escapedDestination = $destination.Replace("'", "''")
        $escapedState = $state.Replace("'", "''")
        @"
@{
    SchemaVersion = 1
    Name = 'Fixture plan'
    StateDirectory = '$escapedState'
    Defaults = @{ Mode = 'Update'; RetryCount = 0; RetryWaitSeconds = 0; MultiThreadCount = 1 }
    Jobs = @(
        @{ Name = 'Fixture'; Enabled = `$true; Required = `$true; Source = '$escapedSource'; Destination = '$escapedDestination'; DestinationVolume = @{ DriveLetter = 'T'; ExpectedLabel = 'Fixture'; ExpectedSerial = `$null }; Mode = 'Update'; CloudAware = `$false; IncludeFiles = @(); ExcludeDirectories = @(); ExcludeFiles = @() }
        @{ Name = 'Offline optional'; Enabled = `$true; Required = `$false; Source = 'Z:\missing-fixture'; Destination = '$escapedDestination'; DestinationVolume = @{ DriveLetter = 'T'; ExpectedLabel = 'Fixture'; ExpectedSerial = `$null }; Mode = 'Update'; CloudAware = `$false; IncludeFiles = @(); ExcludeDirectories = @(); ExcludeFiles = @() }
    )
}
"@ | Set-Content -LiteralPath $planPath

        $script:capturedArguments = $null
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture' } }
        $starter = {
            param([string[]]$arguments)
            $script:capturedArguments = $arguments
            $process = New-Object psobject -Property @{ ExitCode = 1 }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $process
        }

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter
        ($script:capturedArguments -contains '/L') | Should -Be $true
        ($result.Results | Where-Object Name -eq 'Fixture').Status | Should -Be 'Planned'
        ($result.Results | Where-Object Name -eq 'Offline optional').Status | Should -Be 'SkippedUnavailable'
        Test-Path -LiteralPath $result.SummaryPath | Should -Be $true
        Test-Path -LiteralPath $result.TextSummaryPath | Should -Be $true
        (Get-Content -Raw $result.SummaryPath | ConvertFrom-Json).Mode | Should -Be 'PlanOnly'
    }

    It 'classifies an optional source probe exception as unavailable' {
        $destination = Join-Path $TestDrive 'probe-destination'
        $state = Join-Path $TestDrive 'probe-state'
        New-Item -ItemType Directory -Path $destination | Out-Null
        $planPath = Join-Path $TestDrive 'probe-plan.psd1'
        $escapedDestination = $destination.Replace("'", "''")
        $escapedState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Probe exception'; StateDirectory='$escapedState'; Jobs=@(@{Name='Offline UNC';Required=`$false;Source='\\offline.invalid\share';Destination='$escapedDestination';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture' } }
        $sourceResolver = { param($sourcePath) throw 'Simulated network path failure.' }
        $starter = { throw 'Process starter must not run for an unavailable source.' }

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -SourceResolver $sourceResolver -ProcessStarter $starter
        $result.Results.Count | Should -Be 1
        $result.Results[0].Status | Should -Be 'SkippedUnavailable'
    }

    It 'fails and records a Robocopy exit code of 8' {
        $source = Join-Path $TestDrive 'failure-source'
        $destination = Join-Path $TestDrive 'failure-destination'
        $state = Join-Path $TestDrive 'failure-state'
        New-Item -ItemType Directory -Path $source, $destination | Out-Null
        $planPath = Join-Path $TestDrive 'failure-plan.psd1'
        $escapedSource = $source.Replace("'", "''")
        $escapedDestination = $destination.Replace("'", "''")
        $escapedState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Failure'; StateDirectory='$escapedState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='Fail';Enabled=`$true;Required=`$true;Source='$escapedSource';Destination='$escapedDestination';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture';ExpectedSerial=`$null};Mode='Update';CloudAware=`$false;IncludeFiles=@();ExcludeDirectories=@();ExcludeFiles=@()}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture' } }
        $starter = {
            param([string[]]$arguments)
            $process = New-Object psobject -Property @{ ExitCode = 8 }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $process
        }

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter } | Should -Throw
        $summaries = @(Get-ChildItem -LiteralPath $state -Filter summary.json -Recurse)
        $summaries.Count | Should -Be 1
        (Get-Content -Raw $summaries[0].FullName | ConvertFrom-Json).Status | Should -Be 'Failed'
    }

    It 'starts a bounded batch of jobs before waiting' {
        $sourceOne = Join-Path $TestDrive 'parallel-source-one'
        $sourceTwo = Join-Path $TestDrive 'parallel-source-two'
        $destination = Join-Path $TestDrive 'parallel-destination'
        $state = Join-Path $TestDrive 'parallel-state'
        New-Item -ItemType Directory -Path $sourceOne, $sourceTwo, $destination | Out-Null
        $planPath = Join-Path $TestDrive 'parallel-plan.psd1'
        $one = $sourceOne.Replace("'", "''")
        $two = $sourceTwo.Replace("'", "''")
        $dest = $destination.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Parallel'; StateDirectory='$runState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='One';Enabled=`$true;Required=`$true;Source='$one';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'};Mode='Update'},@{Name='Two';Enabled=`$true;Required=`$true;Source='$two';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'};Mode='Update'}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB } }
        $tracker = [hashtable]::Synchronized(@{ Started = 0; WaitedTooEarly = $false })
        $starter = {
            param([string[]]$arguments)
            $tracker.Started++
            $process = New-Object psobject -Property @{ ExitCode = 0; Tracker = $tracker }
            $waiter = { if ($this.Tracker.Started -lt 2) { $this.Tracker.WaitedTooEarly = $true } }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value $waiter
            return $process
        }.GetNewClosure()

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter -MaxParallelJobs 2
        $tracker.Started | Should -Be 2
        $tracker.WaitedTooEarly | Should -Be $false
        @($result.Results | Where-Object Status -eq 'Planned').Count | Should -Be 2
    }

    It 'does not start a third same-stage job before the first batch waits' {
        $sources = 1..3 | ForEach-Object { New-Item -ItemType Directory -Path (Join-Path $TestDrive "batch-source-$_") }
        $destination = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'batch-destination')
        $state = Join-Path $TestDrive 'batch-state'
        $planPath = Join-Path $TestDrive 'batch-plan.psd1'
        $sourceEntries = @($sources | ForEach-Object { $_.FullName.Replace("'", "''") })
        $dest = $destination.FullName.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Batch limit'; StateDirectory='$runState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='One';Source='$($sourceEntries[0])';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Two';Source='$($sourceEntries[1])';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Three';Source='$($sourceEntries[2])';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB } }
        $tracker = [hashtable]::Synchronized(@{ Started = 0; Waited = 0; ThirdStartedEarly = $false })
        $starter = {
            param([string[]]$arguments)
            $tracker.Started++
            if ($tracker.Started -eq 3 -and $tracker.Waited -lt 2) { $tracker.ThirdStartedEarly = $true }
            $process = New-Object psobject -Property @{ ExitCode = 0; Tracker = $tracker }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { $this.Tracker.Waited++ }
            return $process
        }.GetNewClosure()

        [void](Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter -MaxParallelJobs 2)
        $tracker.Started | Should -Be 3
        $tracker.ThirdStartedEarly | Should -Be $false
    }

    It 'waits for an earlier stage before starting the next stage' {
        $sourceOne = Join-Path $TestDrive 'stage-source-one'
        $sourceTwo = Join-Path $TestDrive 'stage-source-two'
        $sourceThree = Join-Path $TestDrive 'stage-source-three'
        $destination = Join-Path $TestDrive 'stage-destination'
        $state = Join-Path $TestDrive 'stage-state'
        New-Item -ItemType Directory -Path $sourceOne, $sourceTwo, $sourceThree, $destination | Out-Null
        $planPath = Join-Path $TestDrive 'stage-plan.psd1'
        $one = $sourceOne.Replace("'", "''")
        $two = $sourceTwo.Replace("'", "''")
        $three = $sourceThree.Replace("'", "''")
        $dest = $destination.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Stages'; StateDirectory='$runState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='One';Stage=1;Required=`$true;Source='$one';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Two';Stage=1;Required=`$true;Source='$two';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Three';Stage=2;Required=`$true;Source='$three';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB } }
        $tracker = [hashtable]::Synchronized(@{ Waited = 0; StageTwoStartedEarly = $false })
        $starter = {
            param([string[]]$arguments)
            if ($arguments[0] -eq $three -and $tracker.Waited -lt 2) { $tracker.StageTwoStartedEarly = $true }
            $process = New-Object psobject -Property @{ ExitCode = 0; Tracker = $tracker }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { $this.Tracker.Waited++ }
            return $process
        }.GetNewClosure()

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter -MaxParallelJobs 3
        $tracker.StageTwoStartedEarly | Should -Be $false
        @($result.Results | Where-Object Stage -eq 1).Count | Should -Be 2
        @($result.Results | Where-Object Stage -eq 2).Count | Should -Be 1
    }

    It 'does not start a later stage after an earlier Robocopy failure' {
        $sourceOne = Join-Path $TestDrive 'failed-stage-one'
        $sourceTwo = Join-Path $TestDrive 'blocked-stage-two'
        $destination = Join-Path $TestDrive 'failed-stage-destination'
        $state = Join-Path $TestDrive 'failed-stage-state'
        New-Item -ItemType Directory -Path $sourceOne, $sourceTwo, $destination | Out-Null
        $planPath = Join-Path $TestDrive 'failed-stage-plan.psd1'
        $one = $sourceOne.Replace("'", "''")
        $two = $sourceTwo.Replace("'", "''")
        $dest = $destination.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Failed stage'; StateDirectory='$runState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='Fails';Stage=1;Required=`$true;Source='$one';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Blocked';Stage=2;Required=`$true;Source='$two';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB } }
        $tracker = [hashtable]::Synchronized(@{ Started = 0 })
        $starter = {
            param([string[]]$arguments)
            $tracker.Started++
            $process = New-Object psobject -Property @{ ExitCode = 8 }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $process
        }.GetNewClosure()

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter -MaxParallelJobs 2 } | Should -Throw
        $tracker.Started | Should -Be 1
    }

    It 'completes earlier-stage work before checking a later destination' {
        $sourceOne = Join-Path $TestDrive 'available-stage-one'
        $sourceTwo = Join-Path $TestDrive 'unavailable-stage-two'
        $destinationOne = Join-Path $TestDrive 'available-stage-destination'
        $destinationTwo = Join-Path $TestDrive 'missing-device-stage-destination'
        $state = Join-Path $TestDrive 'deferred-preflight-state'
        New-Item -ItemType Directory -Path $sourceOne, $sourceTwo, $destinationOne | Out-Null
        $planPath = Join-Path $TestDrive 'deferred-preflight-plan.psd1'
        $one = $sourceOne.Replace("'", "''")
        $two = $sourceTwo.Replace("'", "''")
        $destOne = $destinationOne.Replace("'", "''")
        $destTwo = $destinationTwo.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Deferred preflight'; StateDirectory='$runState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='Acquisition';Stage=1;Required=`$true;Source='$one';Destination='$destOne';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Second copy';Stage=2;Required=`$true;Source='$two';Destination='$destTwo';DestinationVolume=@{DriveLetter='K';ExpectedLabel='Missing'}}) }" | Set-Content -LiteralPath $planPath
        $tracker = [hashtable]::Synchronized(@{ Started = 0; Waited = 0 })
        $resolver = {
            param($destinationPath)
            if ($destinationPath -eq $destTwo) { return [pscustomobject]@{ Kind = 'Local'; Available = $false } }
            return [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB }
        }.GetNewClosure()
        $starter = {
            param([string[]]$arguments)
            $tracker.Started++
            $process = New-Object psobject -Property @{ ExitCode = 0; Tracker = $tracker }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { $this.Tracker.Waited++ }
            return $process
        }.GetNewClosure()

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter } | Should -Throw
        $tracker.Started | Should -Be 1
        $tracker.Waited | Should -Be 1
    }

    It 'starts no same-stage work when any job fails preflight' {
        $sourceOne = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'preflight-one')
        $sourceTwo = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'preflight-two')
        $destination = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'preflight-destination')
        $state = Join-Path $TestDrive 'whole-stage-preflight-state'
        $planPath = Join-Path $TestDrive 'whole-stage-preflight.psd1'
        $one = $sourceOne.FullName.Replace("'", "''")
        $two = $sourceTwo.FullName.Replace("'", "''")
        $dest = $destination.FullName.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Whole stage preflight'; StateDirectory='$runState'; Jobs=@(@{Name='Valid';Stage=1;Source='$one';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Invalid';Stage=1;Source='$two';Destination='K:\Missing';DestinationVolume=@{DriveLetter='K';ExpectedLabel='Missing'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) if ($destinationPath -like 'K:*') { [pscustomobject]@{ Kind='Local';Available=$false } } else { [pscustomobject]@{Kind='Local';Available=$true;DriveLetter='T';Label='Fixture';Serial='fixture';FreeBytes=100GB} } }
        $tracker = [hashtable]::Synchronized(@{ Started = 0 })
        $starter = { param([string[]]$arguments) $tracker.Started++; throw 'Must not start.' }.GetNewClosure()

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter } | Should -Throw
        $tracker.Started | Should -Be 0
    }

    It 'blocks later stages when a required earlier source is missing' {
        $laterSource = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'required-later-source')
        $destination = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'required-stage-destination')
        $state = Join-Path $TestDrive 'required-stage-state'
        $planPath = Join-Path $TestDrive 'required-stage-plan.psd1'
        $later = $laterSource.FullName.Replace("'", "''")
        $dest = $destination.FullName.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Required source gate'; StateDirectory='$runState'; Jobs=@(@{Name='Missing';Stage=1;Required=`$true;Source='Z:\DefinitelyMissing';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}},@{Name='Later';Stage=2;Required=`$true;Source='$later';Destination='$dest';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'}}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{Kind='Local';Available=$true;DriveLetter='T';Label='Fixture';Serial='fixture';FreeBytes=100GB} }
        $tracker = [hashtable]::Synchronized(@{ Started = 0 })
        $starter = { param([string[]]$arguments) $tracker.Started++; throw 'Must not start.' }.GetNewClosure()

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter } | Should -Throw
        $tracker.Started | Should -Be 0
    }

    It 'reports disabled Mirror without starting a process' {
        $source = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'disabled-mirror-source')
        $destination = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'disabled-mirror-destination')
        $state = Join-Path $TestDrive 'disabled-mirror-state'
        $planPath = Join-Path $TestDrive 'disabled-mirror-plan.psd1'
        $sourcePath = $source.FullName.Replace("'", "''")
        $dest = $destination.FullName.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Disabled Mirror'; StateDirectory='$runState'; Jobs=@(@{Name='Disabled';Enabled=`$false;Source='$sourcePath';Destination='$dest';Mode='Mirror';AllowDelete=`$false}) }" | Set-Content -LiteralPath $planPath
        $tracker = [hashtable]::Synchronized(@{ Started = 0 })
        $starter = { param([string[]]$arguments) $tracker.Started++; throw 'Must not start.' }.GetNewClosure()

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -ProcessStarter $starter
        $result.Results[0].Status | Should -Be 'Disabled'
        $tracker.Started | Should -Be 0
    }

    It 'skips only explicitly optional unavailable destinations' {
        $source = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'optional-target-source')
        $state = Join-Path $TestDrive 'optional-target-state'
        $planPath = Join-Path $TestDrive 'optional-target-plan.psd1'
        $sourcePath = $source.FullName.Replace("'", "''")
        $runState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Optional target'; StateDirectory='$runState'; Jobs=@(@{Name='Offline target';DestinationRequired=`$false;Source='$sourcePath';Destination='\\example-offline\data$\Target'}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind='Network';Available=$false } }
        $tracker = [hashtable]::Synchronized(@{ Started = 0 })
        $starter = { param([string[]]$arguments) $tracker.Started++; throw 'Must not start.' }.GetNewClosure()

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter
        $result.Results[0].Status | Should -Be 'SkippedDestinationUnavailable'
        $tracker.Started | Should -Be 0
    }
}
