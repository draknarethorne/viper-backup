@{
    SchemaVersion = 1
    Name = 'Example daily acquisition'
    StateDirectory = 'state\runs'
    RunRetention = @{
        AutoTrim = $false
        KeepLast = 30
        MaxAgeDays = 90
    }
    Defaults = @{
        Mode = 'Update'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 4
    }
    Jobs = @(
        @{
            Name = 'Required local selected folders'
            Enabled = $true
            Required = $true
            Source = 'C:\ExampleProjects'
            Destination = 'D:\ExampleDataHub\Backup_Folders\ExampleProjects'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @('Cache', 'Temp')
            ExcludeFiles = @('*.tmp', '~$*')
        }
        @{
            Name = 'Required local TAKP tree'
            Enabled = $true
            Required = $true
            Source = 'C:\ExampleTAKP'
            Destination = 'D:\ExampleDataHub\Backup_Folders\TAKP'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @('Logs', 'Cache')
            ExcludeFiles = @('*.tmp')
        }
        @{
            Name = 'Optional regular workstation documents'
            Enabled = $true
            Required = $false
            Source = '\\example-workstation\users$\ExampleUser\Documents'
            Destination = 'D:\ExampleDataHub\Workstations\ExampleWorkstation\Documents'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp', '~$*')
        }
        @{
            Name = 'Optional home server active data'
            Enabled = $true
            Required = $false
            Source = '\\example-server\data$\Active'
            Destination = 'D:\ExampleDataHub\Server\Active'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
                MinFreeGiB = 20
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @('Cache', 'Temp')
            ExcludeFiles = @('*.tmp')
        }
    )
}
