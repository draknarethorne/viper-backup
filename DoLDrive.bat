@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Transfer Files to L Drive
REM *************************************************

set BACKUP_SRC=D:
set BACKUP_DEST=L:\My_Backup

REM call Backup "\." /XD $RECYCLE.BIN /XD "System Volume Information" /XD WindowsImageBackup
call Backup "\." /A-:NT /XD $RECYCLE.BIN /XD "System Volume*" /XD Recovery /XD WindowsImageBackup
attrib -s -h %BACKUP_DEST%

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause

