@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Home Server
REM *************************************************

set BACKUP_SRC=X:
set BACKUP_DEST=D:\Backup_Server\CMIS-957903A-HS

call netuse %BACKUP_SRC% \\cmis-957903a-hs\cdrive$ 

call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData /XD hp.*

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

