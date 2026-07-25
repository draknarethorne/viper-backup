@{
    SchemaVersion = 1
    Name = 'Example daily second copy'
    StateDirectory = 'state\runs'
    Defaults = @{
        Mode = 'Update'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 8
    }
    Jobs = @(
        @{
            Name = 'Data hub to verified second-copy device'
            Enabled = $true
            Required = $true
            Source = 'D:\ExampleDataHub'
            Destination = 'K:\ExampleSecondCopy\DataHub'
            DestinationVolume = @{
                DriveLetter = 'K'
                ExpectedLabel = 'Example Backup'
                # A real serial belongs only in the ignored local plan.
                ExpectedSerial = $null
                MinFreeGiB = 100
            }
            # Keep Update during migration. Mirror requires changing Mode,
            # setting AllowDelete, and invoking with -AllowDelete.
            Mode = 'Update'
            AllowDelete = $false
            CloudAware = $false
            ExcludeDirectories = @('$RECYCLE.BIN', 'System Volume Information')
            ExcludeFiles = @('*.tmp')
        }
    )
}
