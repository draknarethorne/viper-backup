@{
    SchemaVersion = 1
    Name = 'Example household distribution'
    StateDirectory = 'state\runs'
    Defaults = @{
        Mode = 'Update'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 4
    }
    Jobs = @(
        @{
            Name = 'Music to example workstation'
            Enabled = $true
            Required = $false
            DestinationRequired = $false
            Source = 'D:\ExampleDataHub\Music'
            Destination = '\\example-workstation\data$\Music'
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp')
        }
        @{
            Name = 'Mobile archive to example family computer'
            Enabled = $true
            Required = $false
            DestinationRequired = $false
            Source = 'D:\ExampleDataHub\Mobile'
            Destination = '\\example-family\data$\Mobile'
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp')
        }
        @{
            Name = 'Setup collection to example home server'
            Enabled = $true
            Required = $false
            DestinationRequired = $false
            Source = 'D:\ExampleDataHub\Setup'
            Destination = '\\example-server\data$\Setup'
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp')
        }
    )
}
