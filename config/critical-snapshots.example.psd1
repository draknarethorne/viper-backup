@{
    SchemaVersion = 1
    Name = 'Example critical timestamped snapshots'
    StateDirectory = 'state\runs'
    Defaults = @{
        Mode = 'Snapshot'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 2
    }
    Jobs = @(
        @{
            Name = 'Fully local OneDrive snapshot'
            Enabled = $true
            Required = $true
            Source = '%UserProfile%\OneDrive'
            Destination = 'D:\ExampleDataHub\Snapshots\OneDrive'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Snapshot'
            CloudAware = $true
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp', '~$*')
        }
        @{
            Name = 'Portable TAKP configuration snapshot'
            Enabled = $false
            Required = $true
            Source = 'C:\ExampleTAKP'
            Destination = 'D:\ExampleDataHub\Snapshots\TAKP-Portable'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Snapshot'
            CloudAware = $false
            # Replace fictional patterns with a reviewed local allowlist.
            IncludeFiles = @(
                'Character_Example.ini'
                'Timer_Example.ini'
            )
            ExcludeDirectories = @('Logs', 'Cache', 'CrashDumps')
            ExcludeFiles = @('eqclient.ini', '*.tmp', '*.log')
        }
    )
}
