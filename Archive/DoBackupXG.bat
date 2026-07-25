@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup XG Gaming
REM *************************************************
:BackupXG

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Desktop\CMIS-957903A-XG

call netuse %BACKUP_SRC% \\cmis-957903a-xg\cdrive$

call backup "\ICAN"
call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

