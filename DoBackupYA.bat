@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Emily YA Gaming
REM *************************************************
:BackupYA

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Family\CMIS-957903A-YA

call netuse %BACKUP_SRC% \\cmis-957903a-ya\cdrive$

call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

