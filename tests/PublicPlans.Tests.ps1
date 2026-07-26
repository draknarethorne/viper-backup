. "$PSScriptRoot\PesterAssertionCompatibility.ps1"

$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

Describe 'Public example plans' {
    It 'keeps every public example structurally valid without delete authorization' {
        $configPath = Join-Path $PSScriptRoot '..\config'
        $plans = @(Get-ChildItem -LiteralPath $configPath -Filter '*.example.psd1' -File)
        $plans.Count | Should -BeGreaterThan 0

        $failures = New-Object Collections.Generic.List[string]
        foreach ($file in $plans) {
            $plan = Import-PowerShellDataFile -LiteralPath $file.FullName
            $result = Test-ViperBackupPlan -Plan $plan
            if (-not $result.Valid) {
                $failures.Add("$($file.Name): $($result.Errors -join '; ')")
            }
        }

        @($failures).Count | Should -Be 0
    }

    It 'keeps enabled public jobs non-deleting by default' {
        $configPath = Join-Path $PSScriptRoot '..\config'
        foreach ($file in @(Get-ChildItem -LiteralPath $configPath -Filter '*.example.psd1' -File)) {
            $plan = Import-PowerShellDataFile -LiteralPath $file.FullName
            $defaultMode = if ($plan.ContainsKey('Defaults') -and $plan.Defaults.ContainsKey('Mode')) { $plan.Defaults.Mode } else { 'Update' }
            foreach ($job in @($plan.Jobs | Where-Object { -not $_.ContainsKey('Enabled') -or $_.Enabled })) {
                $mode = if ($job.ContainsKey('Mode')) { $job.Mode } else { $defaultMode }
                $mode | Should -Not -Be 'Mirror'
            }
        }
    }

    It 'keeps the daily second copy in Stage 2 after Stage 1 acquisition' {
        $plan = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '..\config\daily-suite.example.psd1')
        @($plan.Jobs | Where-Object Stage -eq 1).Count | Should -BeGreaterThan 0
        @($plan.Jobs | Where-Object Name -like '*second-copy*').Count | Should -Be 1
        ($plan.Jobs | Where-Object Name -like '*second-copy*').Stage | Should -Be 2
    }

    It 'keeps TAKP publication one-way with eqclient.ini excluded' {
        $plan = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '..\config\takp-sync.example.psd1')
        $plan.Jobs[0].Mode | Should -Be 'Update'
        $plan.Jobs[0].ExcludeFiles -contains 'eqclient.ini' | Should -Be $true
    }

    It 'keeps the OneDrive example snapshot cloud-aware' {
        $plan = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '..\config\critical-snapshots.example.psd1')
        $job = $plan.Jobs | Where-Object Name -like '*OneDrive*'
        $job.Mode | Should -Be 'Snapshot'
        $job.CloudAware | Should -Be $true
    }
}
