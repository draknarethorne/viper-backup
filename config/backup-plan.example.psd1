@{
    SchemaVersion = 1
    Name = 'Example workstation plan'

    # Runtime state is local and ignored. Relative paths resolve from repo root.
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
            Name = 'Required user documents'
            Enabled = $true
            Required = $true
            Source = 'C:\Users\ExampleUser\Documents'
            Destination = 'D:\ExampleBackup\Documents'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                # Put a real serial only in ignored local configuration.
                ExpectedSerial = $null
                MinFreeGiB = 10
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @('Cache', 'Temp')
            ExcludeFiles = @('*.tmp', '~$*')
        }
        @{
            Name = 'Optional network machine'
            Enabled = $true
            Required = $false
            Source = '\\example-machine\users$\ExampleUser\Documents'
            Destination = 'D:\ExampleBackup\NetworkMachine\Documents'
            DestinationVolume = @{
                DriveLetter = 'D'
                ExpectedLabel = 'Example Data'
                ExpectedSerial = $null
            }
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @()
            ExcludeFiles = @('*.tmp')
        }
        @{
            Name = 'Manual mirror example - disabled'
            Enabled = $false
            Required = $false
            Source = 'D:\ExampleBackup'
            Destination = 'K:\ExampleSecondCopy'
            DestinationVolume = @{
                DriveLetter = 'K'
                ExpectedLabel = 'Example Backup'
                ExpectedSerial = $null
            }
            Mode = 'Mirror'
            AllowDelete = $false
            CloudAware = $false
            ExcludeDirectories = @('$RECYCLE.BIN', 'System Volume Information')
            ExcludeFiles = @()
        }
    )
}
