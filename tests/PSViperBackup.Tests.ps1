$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

Describe 'Viper Backup core safety behavior' {
    It 'uses sortable invariant timestamps' {
        Get-ViperTimestamp -Value ([datetime]'2026-07-25T18:45:30') | Should Be '20260725-184530'
    }

    It 'classifies Robocopy codes 0 through 7 as nonfatal' {
        foreach ($code in 0..7) {
            (Get-RobocopyResult -ExitCode $code).Failed | Should Be $false
        }
    }

    It 'classifies Robocopy codes 8 and above as failures' {
        foreach ($code in @(8, 9, 16, 24)) {
            (Get-RobocopyResult -ExitCode $code).Failed | Should Be $true
        }
    }

    It 'quotes paths with spaces for Windows process invocation' {
        ConvertTo-WindowsCommandLineArgument 'C:\Example Data\Backup' | Should Be '"C:\Example Data\Backup"'
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
        (Test-ViperBackupPlan -Plan $plan).Valid | Should Be $false
        $plan.Jobs[0].AllowDelete = $true
        (Test-ViperBackupPlan -Plan $plan).Valid | Should Be $false
        (Test-ViperBackupPlan -Plan $plan -AllowDelete).Valid | Should Be $true
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
        (Test-ViperBackupPlan -Plan $plan).Valid | Should Be $false
        (Test-ViperBackupPlan -Plan $plan -AllowDelete).Valid | Should Be $true
    }

    It 'reports malformed plan structures without throwing' {
        $plan = @{ Defaults = 'invalid'; Jobs = @('invalid') }
        $result = Test-ViperBackupPlan -Plan $plan
        $result.Valid | Should Be $false
        $result.Errors.Count | Should BeGreaterThan 3
    }

    It 'rejects a mismatched destination label' {
        $job = @{
            Name = 'Identity test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Wrong'; Serial = 'x' } }
        { Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver } | Should Throw
    }

    It 'accepts a matching destination label' {
        $job = @{
            Name = 'Identity test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Expected'; Serial = 'x' } }
        (Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver).Label | Should Be 'Expected'
    }

    It 'rejects insufficient destination free space' {
        $job = @{
            Name = 'Space test'
            Destination = 'D:\Backup'
            DestinationVolume = @{ DriveLetter = 'D'; ExpectedLabel = 'Expected'; ExpectedSerial = $null; MinFreeGiB = 10 }
        }
        $resolver = { param($destination) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'D'; Label = 'Expected'; Serial = 'x'; FreeBytes = 1GB } }
        { Assert-ViperDestinationIdentity -Job $job -VolumeResolver $resolver } | Should Throw
    }

    It 'rejects nested or identical source and destination paths' {
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'C:\Data' | Should Be $true
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'C:\Data\Backup' | Should Be $true
        Test-ViperPathOverlap -Source 'C:\Data\Backup' -Destination 'C:\Data' | Should Be $true
        Test-ViperPathOverlap -Source 'C:\Data' -Destination 'D:\Backup' | Should Be $false
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
        $arguments -contains '/L' | Should Be $true
        $arguments -contains '/E' | Should Be $true
        $arguments -contains '/MIR' | Should Be $false
        $arguments -contains 'Temp Folder' | Should Be $true
    }

    It 'detects hydrated ordinary temporary files' {
        $path = Join-Path $TestDrive 'cloud'
        New-Item -ItemType Directory -Path $path | Out-Null
        Set-Content -LiteralPath (Join-Path $path 'local.txt') -Value 'fixture'
        $result = Test-ViperCloudHydration -Path $path
        $result.Available | Should Be $true
        $result.FullyHydrated | Should Be $true
        $result.InspectedFiles | Should Be 1
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
        $candidates.Count | Should Be 2
        ($candidates.Name -contains 'run-1') | Should Be $true
        ($candidates.Name -contains 'run-2') | Should Be $true
    }

    It 'previews safely, removes only expired history, and rejects outside paths' {
        $fixtureRoot = Join-Path (Join-Path $PSScriptRoot '..\state') ("retention-test-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $oldest = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '20200101-000000') -Force
            $newest = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '20200102-000000') -Force
            $oldest.LastWriteTimeUtc = [datetime]'2020-01-01T00:00:00Z'
            $newest.LastWriteTimeUtc = [datetime]'2020-01-02T00:00:00Z'

            Remove-ViperBackupRunHistory -StateDirectory $fixtureRoot -KeepLast 1 -MaxAgeDays 1 -WhatIf -Confirm:$false
            Test-Path -LiteralPath $oldest.FullName | Should Be $true

            Remove-ViperBackupRunHistory -StateDirectory $fixtureRoot -KeepLast 1 -MaxAgeDays 1 -Confirm:$false
            Test-Path -LiteralPath $oldest.FullName | Should Be $false
            Test-Path -LiteralPath $newest.FullName | Should Be $true
            { Remove-ViperBackupRunHistory -StateDirectory $TestDrive -Confirm:$false } | Should Throw
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
        ($script:capturedArguments -contains '/L') | Should Be $true
        ($result.Results | Where-Object Name -eq 'Fixture').Status | Should Be 'Planned'
        ($result.Results | Where-Object Name -eq 'Offline optional').Status | Should Be 'SkippedUnavailable'
        Test-Path -LiteralPath $result.SummaryPath | Should Be $true
        Test-Path -LiteralPath $result.TextSummaryPath | Should Be $true
        (Get-Content -Raw $result.SummaryPath | ConvertFrom-Json).Mode | Should Be 'PlanOnly'
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

        { Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver -ProcessStarter $starter } | Should Throw
        $summaries = @(Get-ChildItem -LiteralPath $state -Filter summary.json -Recurse)
        $summaries.Count | Should Be 1
        (Get-Content -Raw $summaries[0].FullName | ConvertFrom-Json).Status | Should Be 'Failed'
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
        $tracker.Started | Should Be 2
        $tracker.WaitedTooEarly | Should Be $false
        @($result.Results | Where-Object Status -eq 'Planned').Count | Should Be 2
    }
}
