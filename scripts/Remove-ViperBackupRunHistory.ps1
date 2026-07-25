[CmdletBinding()]
param(
    [string]$StateDirectory = (Join-Path $PSScriptRoot '..\state\runs'),
    [ValidateRange(1, 10000)][int]$KeepLast = 30,
    [ValidateRange(1, 36500)][int]$MaxAgeDays = 90,
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
Import-Module $modulePath -Force

if (-not $Execute) {
    Write-Host 'PLAN-ONLY cleanup: no run-history directories will be removed.' -ForegroundColor Cyan
}
Remove-ViperBackupRunHistory -StateDirectory $StateDirectory -KeepLast $KeepLast -MaxAgeDays $MaxAgeDays -WhatIf:(-not $Execute) -Confirm:$false
