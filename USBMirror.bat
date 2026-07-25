@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Transfer Files to USB Drive
REM *************************************************
:MTransfer

set BACKUP_SRC=D:
set BACKUP_DEST=E:\My_Data

call Backup "\." /A-:NT /XD $RECYCLE.BIN /XD "System*" /XD "Program Files" 

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

