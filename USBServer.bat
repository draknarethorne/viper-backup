@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Transfer Files to USB Drive
REM *************************************************
:MTransfer

set BACKUP_SRC=D:
set BACKUP_DEST=E:

call backup "\Archive_Server" /A-:NT
call backup "\Backup_Server" /A-:NT

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause
