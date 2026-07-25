@{
    SchemaVersion = 1
    Name = 'Example timestamped configuration snapshot'
    StateDirectory = 'state\runs'
    Defaults = @{
        Mode = 'Snapshot'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 2
    }
    Jobs = @(
        @{
            Name = 'Example application configuration'
            Enabled = $true
            Required = $true
            Source = 'C:\ExampleApplication'
            Destination = 'D:\ExampleSnapshots\ApplicationConfig'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
            }
            Mode = 'Snapshot'
            CloudAware = $false
            IncludeFiles = @('*.ini', '*.bak')
            ExcludeDirectories = @('Cache', 'Temp')
            ExcludeFiles = @()
        }
    )
}
