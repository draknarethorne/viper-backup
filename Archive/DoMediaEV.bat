@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:
set BACKUP_DEST=T:

call netuse %BACKUP_DEST% \\cmis-957903a-ev\ddrive$

call backup "\Media"
call backup "\Mobile"
REM call backup "\Movies"
call backup "\Music"

call backup "\Setup"
REM call backup "\Setup Games"
REM call backup "\Setup Microsoft"

call netuse %BACKUP_DEST% /d



if "%1" == "" pause
