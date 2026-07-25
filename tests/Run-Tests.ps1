[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$testFiles = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.Tests.ps1' -File |
    Sort-Object Name |
    Select-Object -ExpandProperty FullName)

$results = Invoke-Pester -Script $testFiles -PassThru
if ($results.FailedCount -gt 0) {
    exit 1
}
exit 0
