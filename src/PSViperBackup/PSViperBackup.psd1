@{
    RootModule = 'PSViperBackup.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'ee28e01d-b53c-4e47-a04f-4d2238f250a8'
    Author = 'Draknaré Thorne'
    CompanyName = 'ViperTech'
    Copyright = '(c) 2026 Draknaré Thorne. MIT License.'
    Description = 'Safety-first Windows backup planning and Robocopy orchestration.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Assert-ViperDestinationIdentity'
        'ConvertTo-WindowsCommandLineArgument'
        'Get-RobocopyResult'
        'Get-ViperJobArguments'
        'Get-ViperRetentionCandidates'
        'Get-ViperTimestamp'
        'Invoke-ViperBackupPlan'
        'Remove-ViperBackupRunHistory'
        'Test-ViperBackupPlan'
        'Test-ViperCloudHydration'
        'Test-ViperPathOverlap'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Backup', 'Robocopy', 'Windows', 'Safety')
            LicenseUri = 'https://github.com/draknarethorne/viper-backup/blob/main/LICENSE'
            ProjectUri = 'https://github.com/draknarethorne/viper-backup'
        }
    }
}
