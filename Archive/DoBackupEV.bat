@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Mary EVO
REM *************************************************

set BACKUP_SRC=U:
set BACKUP_DEST=D:\Backup_Family\CMIS-957903A-EV

call netuse %BACKUP_SRC% \\cmis-957903a-ev\cdrive$ 

REM call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "Google Drive" /XD hp.* 
call backup "\Users" /XD Music /XD AppData /XD scott /XD "Google Drive" /XD Downloads /XD hp.*
REM call backup "\Users" /XD Music /XD AppData 

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

