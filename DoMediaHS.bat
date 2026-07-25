@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:
set BACKUP_DEST=S:

call netuse %BACKUP_DEST% \\cmis-957903a-hs\ddrive$

call backup "\Media"
REM call backup "\Mobile"
REM call backup "\Movies"
REM call backup "\Music"

call backup "\Setup"
call backup "\Setup Games"
REM call backup "\Setup Microsoft"

call netuse %BACKUP_DEST% /d


if "%1" == "" pause