$root = Split-Path -Parent $PSScriptRoot

Describe 'Legacy ST AppData bridge' {
    $scriptPath = Join-Path $root 'DoBackupST.bat'
    $content = Get-Content -Raw -LiteralPath $scriptPath
    $activeLines = @(Get-Content -LiteralPath $scriptPath | Where-Object {
        $_ -match '\S' -and $_ -notmatch '^\s*(REM\b|::)'
    })

    It 'keeps broad AppData excluded from the Users mirror' {
        $usersLine = @($activeLines | Where-Object { $_ -match '^\s*call backup "\\Users"' })
        $usersLine.Count | Should Be 1
        $usersLine[0] | Should Match '/XD\s+Music\s+AppData'
    }

    It 'uses consolidated exclusions within the BACKUP.CMD argument limit' {
        $usersLine = @($activeLines | Where-Object { $_ -match '^\s*call backup "\\Users"' })[0]
        ([regex]::Matches($usersLine, '/XD')).Count | Should Be 1
        $usersLine | Should Match '"Google Drive"\s+\.vscode\s+hp\.\*'
    }

    It 'guards and includes high-value ST settings paths' {
        $content | Should Match 'if exist .*AppData\\Roaming\\Code\\User'
        $content | Should Match 'call backup "\\Users\\scott\\AppData\\Roaming\\Code\\User" /XD workspaceStorage globalStorage History'
        $content | Should Match 'if exist .*Microsoft\.WindowsTerminal_8wekyb3d8bbwe\\LocalState'
        $content | Should Match 'call backup .*Microsoft\.WindowsTerminal_8wekyb3d8bbwe\\LocalState" /XF state\.json'
        $content | Should Match 'if exist .*AppData\\Roaming\\Microsoft\\Templates'
    }

    It 'does not add broad browser or cloud-client AppData mirrors' {
        ($activeLines -join [Environment]::NewLine) | Should Not Match 'call backup .*AppData.*(Chrome|Edge|Firefox|OneDrive|Google\\Drive)'
    }

    It 'remains active from the daily orchestrator' {
        (Get-Content -Raw -LiteralPath (Join-Path $root 'DoBackup.bat')) | Should Match '(?m)^call DoBackupST\.bat NoPause\s*$'
    }
}