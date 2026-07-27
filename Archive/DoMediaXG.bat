@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:
set BACKUP_DEST=T:

call netuse %BACKUP_DEST% \\cmis-957903a-zg\ddrive$

call backup "\Cameras"
call backup "\Media"
call backup "\Mobile"
call backup "\Movies"
call backup "\Music"
call backup "\Setup"
call backup "\Setup Games"
call backup "\Setup Microsoft"

call netuse %BACKUP_DEST% /d


if "%1" == "" pause
