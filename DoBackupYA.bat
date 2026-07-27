@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Emily YA Gaming
REM *************************************************
:BackupYA

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Family\CMIS-957903A-YA

call netuse %BACKUP_SRC% \\cmis-957903a-ya\cdrive$

REM Personal-data scope excludes live registry hives.
call backup "\Users" /XD Music AppData "OneDrive" "Google Drive" hp.* /XF NTUSER.DAT*
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause
