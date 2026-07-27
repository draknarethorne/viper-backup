REM @Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:\Media
set BACKUP_DEST=T:

call netuse %BACKUP_DEST% \\cmis-957903a-ya\media$

REM call backup "\Music"
call backup "\Pictures" /XD "200*"

call netuse %BACKUP_DEST% /d


REM ******************************************************
REM *** Backup D:\Setup to PV Machine
REM ******************************************************

set BACKUP_SRC=D:
set BACKUP_DEST=T:

call netuse %BACKUP_DEST% \\cmis-957903a-ya\ddrive$

call backup "\Setup"
call backup "\Setup Games"

call netuse %BACKUP_DEST% /d



if "%1" == "" pause
