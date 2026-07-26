. "$PSScriptRoot\PesterAssertionCompatibility.ps1"

Describe 'PowerShell module packaging' {
    BeforeAll {
        $manifestPath = Join-Path $PSScriptRoot '..\src\PSViperBackup\PSViperBackup.psd1'
    }

    It 'has a valid module manifest' {
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'imports on Windows PowerShell 5.1' {
        { Import-Module $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
    }
}
