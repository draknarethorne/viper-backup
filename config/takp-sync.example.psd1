@{
    SchemaVersion = 1
    Name = 'Example one-way TAKP publication'
    StateDirectory = 'state\runs'
    Defaults = @{
        Mode = 'Update'
        RetryCount = 1
        RetryWaitSeconds = 2
        MultiThreadCount = 4
    }
    Jobs = @(
        @{
            Name = 'Authoritative TAKP tree to gaming machine'
            Enabled = $true
            Required = $false
            DestinationRequired = $false
            Source = 'C:\ExampleTAKP'
            Destination = '\\example-gaming\games$\TAKP'
            # Update preserves destination-only machine settings during migration.
            Mode = 'Update'
            CloudAware = $false
            ExcludeDirectories = @('Logs', 'Cache', 'CrashDumps')
            ExcludeFiles = @(
                'eqclient.ini'
                '*.tmp'
                '*.log'
            )
        }
    )
}
