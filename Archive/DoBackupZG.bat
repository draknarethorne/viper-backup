@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup ZG Gaming
REM *************************************************
:BackupZG

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Desktop\CMIS-957903A-ZG

call netuse %BACKUP_SRC% \\cmis-957903a-zg\cdrive$

REM call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
call backup "\Users" /XD Music /XD AppData /XD "Google Drive" /XD hp.*
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call backup "\Users\scotte\AppData\Roaming\.minecraft"
call backup "\Users\scotte\AppData\Local\VirtualStore\Program Files (x86)\Sony\EverQuest"

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause
