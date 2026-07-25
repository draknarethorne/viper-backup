@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup ST Gaming
REM *************************************************
:BackupST

set BACKUP_SRC=C:
set BACKUP_DEST=D:\Backup_Desktop\CMIS-957903A-ST

REM call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.*
call backup "\Users" /XD Music /XD AppData /XD "Google Drive" /XD .vscode /XD hp.*
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call backup "\Users\scott\AppData\Roaming\.minecraft"
call backup "\Users\scott\AppData\Local\VirtualStore\Program Files (x86)\Sony\EverQuest"

call backup "\Program Files\EQTimer"

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

echo "%1"
if "%1" == "" pause

