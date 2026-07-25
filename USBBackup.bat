@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Transfer Files to USB Drive
REM *************************************************
:MTransfer

set BACKUP_SRC=D:
set BACKUP_DEST=E:

call backup "\Backup" /A-:NT
call backup "\Backup_Desktop" /A-:NT

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

