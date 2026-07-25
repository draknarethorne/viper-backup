[CmdletBinding()]
param(
    [string]$PlanPath = (Join-Path $PSScriptRoot '..\local\backup-plan.psd1'),
    [switch]$Execute,
    [switch]$AllowDelete,
    [ValidateRange(1, 16)][int]$MaxParallelJobs = 1
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

if ($Execute) {
    Write-Warning 'EXECUTE mode can write backup destinations.'
}
else {
    Write-Host 'PLAN-ONLY mode: Robocopy will receive /L and will not copy or delete files.' -ForegroundColor Cyan
}

$result = Invoke-ViperBackupPlan -PlanPath $PlanPath -Execute:$Execute -AllowDelete:$AllowDelete -MaxParallelJobs $MaxParallelJobs
$result.Results | Format-Table Stage, Name, Mode, Status, ExitCode, Severity -AutoSize
Write-Host "Summary: $($result.SummaryPath)"
