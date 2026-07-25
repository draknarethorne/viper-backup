@Echo On
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Mary HP All-In-One
REM *************************************************

set BACKUP_SRC=W:
set BACKUP_DEST=D:\Backup_Family\CMIS-957903A-MB

call netuse %BACKUP_SRC% \\cmis-957903a-mb\cdrive$ 

call backup "\Users" /XD Music /XD AppData /XD scott /XD "My Drive*" /XD hp.*
REM call backup "\Users" /XD Music /XD AppData /XD "OneDrive" /XD "My Drive*" /XD hp.* 
REM call backup "\Users" /XD Music /XD AppData 

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

