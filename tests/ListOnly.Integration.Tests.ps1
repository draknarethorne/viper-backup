. "$PSScriptRoot\PesterAssertionCompatibility.ps1"

$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

Describe 'Real Robocopy list-only integration' {
    It 'plans tiny fixtures without creating the destination' {
        $source = Join-Path $TestDrive 'real-source'
        $destination = Join-Path $TestDrive 'must-not-be-created'
        $state = Join-Path $TestDrive 'real-state'
        New-Item -ItemType Directory -Path (Join-Path $source 'nested') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'sample.txt') -Value 'fixture'
        Set-Content -LiteralPath (Join-Path $source 'nested\settings.ini') -Value '[Fixture]'
        $planPath = Join-Path $TestDrive 'real-plan.psd1'
        $escapedSource = $source.Replace("'", "''")
        $escapedDestination = $destination.Replace("'", "''")
        $escapedState = $state.Replace("'", "''")
        "@{ SchemaVersion=1; Name='Real list-only fixture'; StateDirectory='$escapedState'; Defaults=@{Mode='Update';RetryCount=0;RetryWaitSeconds=0;MultiThreadCount=1}; Jobs=@(@{Name='Real fixture';Enabled=`$true;Required=`$true;Source='$escapedSource';Destination='$escapedDestination';DestinationVolume=@{DriveLetter='T';ExpectedLabel='Fixture'};Mode='Update';CloudAware=`$false}) }" | Set-Content -LiteralPath $planPath
        $resolver = { param($destinationPath) [pscustomobject]@{ Kind = 'Local'; Available = $true; DriveLetter = 'T'; Label = 'Fixture'; Serial = 'fixture'; FreeBytes = 100GB } }

        $result = Invoke-ViperBackupPlan -PlanPath $planPath -VolumeResolver $resolver

        Test-Path -LiteralPath $destination | Should -Be $false
        $result.Results[0].Status | Should -Be 'Planned'
        $result.Results[0].ExitCode | Should -Be 1
        Test-Path -LiteralPath $result.Results[0].Log | Should -Be $true
        (Get-Content -Raw $result.SummaryPath | ConvertFrom-Json).Mode | Should -Be 'PlanOnly'
    }
}
