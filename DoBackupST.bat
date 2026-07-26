@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup ST Gaming
REM *************************************************
:BackupST

set BACKUP_SRC=C:
set BACKUP_DEST=D:\Backup_Desktop\CMIS-957903A-ST

REM Keep broad AppData excluded: it contains caches, locked databases, cloud
REM client state, and other volatile data. Restore-worthy settings are added
REM selectively below. One /XD accepts multiple names and stays within the
REM eight option slots forwarded by BACKUP.CMD.
REM call backup "\Users" /XD Music AppData "OneDrive" "Google Drive" hp.*
call backup "\Users" /XD Music AppData "Google Drive" .vscode hp.*
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call backup "\Users\scott\AppData\Roaming\.minecraft"
call backup "\Users\scott\AppData\Local\VirtualStore\Program Files (x86)\Sony\EverQuest"

REM *************************************************
REM ** Selective ST AppData settings bridge
REM ** Keep these narrow until the PowerShell plan replaces legacy /MIR.
REM *************************************************

if exist "%BACKUP_SRC%\Users\scott\AppData\Roaming\Code\User\" call backup "\Users\scott\AppData\Roaming\Code\User" /XD workspaceStorage globalStorage History
if exist "%BACKUP_SRC%\Users\scott\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\" call backup "\Users\scott\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" /XF state.json
if exist "%BACKUP_SRC%\Users\scott\AppData\Roaming\Microsoft\Templates\" call backup "\Users\scott\AppData\Roaming\Microsoft\Templates"

call backup "\Program Files\EQTimer"

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

echo "%1"
if "%1" == "" pause

