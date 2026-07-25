@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Molly NI Tablet
REM *************************************************
:BackupNI

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Family\CMIS-957903A-NI

call netuse %BACKUP_SRC% \\cmis-957903a-ni\cdrive$

call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

