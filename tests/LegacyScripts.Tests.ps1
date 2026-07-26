. "$PSScriptRoot\PesterAssertionCompatibility.ps1"

$root = Split-Path -Parent $PSScriptRoot

Describe 'Legacy ST AppData bridge' {
    $scriptPath = Join-Path $root 'DoBackupST.bat'
    $content = Get-Content -Raw -LiteralPath $scriptPath
    $activeLines = @(Get-Content -LiteralPath $scriptPath | Where-Object {
        $_ -match '\S' -and $_ -notmatch '^\s*(REM\b|::)'
    })

    It 'keeps broad AppData excluded from the Users mirror' {
        $usersLine = @($activeLines | Where-Object { $_ -match '^\s*call backup "\\Users"' })
        $usersLine.Count | Should -Be 1
        $usersLine[0] | Should -Match '/XD\s+Music\s+AppData'
    }

    It 'uses consolidated exclusions within the BACKUP.CMD argument limit' {
        $usersLine = @($activeLines | Where-Object { $_ -match '^\s*call backup "\\Users"' })[0]
        ([regex]::Matches($usersLine, '/XD')).Count | Should -Be 1
        $usersLine | Should -Match '"Google Drive"\s+\.vscode\s+hp\.\*'
        $usersLine | Should -Match '/XF\s+NTUSER\.DAT\*'
    }

    It 'guards and includes high-value ST settings paths' {
        $content | Should -Match 'if exist .*AppData\\Roaming\\Code\\User'
        $content | Should -Match 'call backup "\\Users\\scott\\AppData\\Roaming\\Code\\User" /XD workspaceStorage globalStorage History'
        $content | Should -Match 'if exist .*Microsoft\.WindowsTerminal_8wekyb3d8bbwe\\LocalState'
        $content | Should -Match 'call backup .*Microsoft\.WindowsTerminal_8wekyb3d8bbwe\\LocalState" /XF state\.json'
        $content | Should -Match 'if exist .*AppData\\Roaming\\Microsoft\\Templates'
        $content | Should -Match 'call backup "\\Users\\scott\\AppData\\Roaming\\Microsoft\\Templates" /XF "~\$\*"'
    }

    It 'retires confirmed obsolete ST sources' {
        ($activeLines -join [Environment]::NewLine) | Should -Not -Match '\.minecraft|VirtualStore.*EverQuest|Program Files\\EQTimer'
        $content | Should -Match 'Retired ST paths'
    }

    It 'does not add broad browser or cloud-client AppData mirrors' {
        ($activeLines -join [Environment]::NewLine) | Should -Not -Match 'call backup .*AppData.*(Chrome|Edge|Firefox|OneDrive|Google\\Drive)'
    }

    It 'remains active from the daily orchestrator' {
        (Get-Content -Raw -LiteralPath (Join-Path $root 'DoBackup.bat')) | Should -Match '(?m)^call DoBackupST\.bat NoPause\s*$'
    }
}

Describe 'Legacy personal-data profile scope' {
    $profileScripts = @(
        'DoBackupGT.bat',
        'DoBackupHS.bat',
        'DoBackupMB.bat',
        'DoBackupST.bat',
        'DoBackupYA.bat'
    )

    foreach ($profileScript in $profileScripts) {
        It "excludes live profile hives in $profileScript" {
            $activeUsersLines = @(Get-Content -LiteralPath (Join-Path $root $profileScript) | Where-Object {
                $_ -match '^\s*call backup "\\Users"' -and $_ -notmatch '^\s*(REM\b|::)'
            })
            $activeUsersLines.Count | Should -Be 1
            ([regex]::Matches($activeUsersLines[0], '/XD')).Count | Should -Be 1
            $activeUsersLines[0] | Should -Match '/XF\s+NTUSER\.DAT\*'
        }
    }
}

Describe 'Legacy Robocopy status propagation' {
    $wrapper = Get-Content -Raw -LiteralPath (Join-Path $root 'BACKUP.CMD')
    $orchestrator = Get-Content -Raw -LiteralPath (Join-Path $root 'DoBackup.bat')

    It 'captures the Robocopy result immediately and classifies code 8 or greater as failure' {
        $wrapper | Should -Match 'robocopy[^\r\n]+\r?\nset "BACKUP_LAST_EXIT=%ERRORLEVEL%"'
        $wrapper | Should -Match 'if %BACKUP_LAST_EXIT% GEQ 8 goto RobocopyError'
        $wrapper | Should -Match ':RobocopyError[\s\S]+set "BACKUP_FAILED=YES"'
        $wrapper | Should -Match 'exit /b %BACKUP_LAST_EXIT%'
    }

    It 'initializes aggregate state and returns a failed completion result' {
        $orchestrator | Should -Match 'set "BACKUP_FAILED="'
        $orchestrator | Should -Match 'if /I "%BACKUP_FAILED%"=="YES" goto BackupFailed'
        $orchestrator | Should -Match 'Backup FAILED'
        $orchestrator | Should -Match 'exit /b %BACKUP_EXIT%'
    }
}