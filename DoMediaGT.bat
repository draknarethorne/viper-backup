@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:
set BACKUP_DEST=R:

call netuse %BACKUP_DEST% \\cmis-957903a-gt\ddrive$

call backup "\Archive"
call backup "\Archive_EQ"
call backup "\Archive_Games"
call backup "\Archive_MC"
call backup "\Archive_Server"
call backup "\Archive_UO"
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
