@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup GT Gaming
REM *************************************************
:BackupGT

set BACKUP_SRC=Z:
set BACKUP_DEST=D:\Backup_Desktop\CMIS-957903A-GT

call netuse %BACKUP_SRC% \\cmis-957903a-gt\cdrive$

call backup "\Users" /XD AppData /XD "My Drive (*" /XD "Google Drive" /XD .vscode 
REM call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call backup "\Users\scott\AppData\Roaming\.minecraft"
call backup "\Users\scott\AppData\Local\VirtualStore\Program Files (x86)\Sony\EverQuest"

call backup "\Program Files\EQTimer"

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

