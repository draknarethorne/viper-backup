@{
    SchemaVersion = 1
    Name = 'Example staged daily suite'
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
        # Stage 1: acquire current local/network data and small history.
        @{
            Name = 'Required local selected folders'
            Stage = 1
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
            Stage = 1
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
            Stage = 1
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
            Name = 'Fully local OneDrive timestamped snapshot'
            Stage = 1
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

        # Stage 2 cannot start until every started Stage 1 job finishes without
        # a Robocopy failure and every required Stage 1 source is available.
        @{
            Name = 'Data hub to verified second-copy device'
            Stage = 2
            Enabled = $true
            Required = $true
            Source = 'D:\ExampleDataHub'
            Destination = 'K:\ExampleSecondCopy\DataHub'
            DestinationVolume = @{
                DriveLetter = 'K'
                ExpectedLabel = 'Example Backup'
                ExpectedSerial = $null
                MinFreeGiB = 100
            }
            Mode = 'Update'
            AllowDelete = $false
            CloudAware = $false
            ExcludeDirectories = @('$RECYCLE.BIN', 'System Volume Information')
            ExcludeFiles = @('*.tmp')
        }
    )
}
