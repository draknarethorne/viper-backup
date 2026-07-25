[CmdletBinding()]
param(
    [string]$PlanPath = (Join-Path $PSScriptRoot '..\local\backup-plan.psd1'),
    [switch]$AllowDelete
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

$resolved = (Resolve-Path -LiteralPath $PlanPath -ErrorAction Stop).Path
$plan = Import-PowerShellDataFile -LiteralPath $resolved
$result = Test-ViperBackupPlan -Plan $plan -AllowDelete:$AllowDelete

$result.Warnings | ForEach-Object { Write-Warning $_ }
if (-not $result.Valid) {
    $result.Errors | ForEach-Object { Write-Error $_ }
    exit 2
}

Write-Host "Plan is structurally valid: $($plan.Name)" -ForegroundColor Green
