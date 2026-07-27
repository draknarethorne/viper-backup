@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Transfer Files to E Drive
REM *************************************************

set BACKUP_SRC=D:
set BACKUP_DEST=E:

call Backup "\." /XD Cam* /XD Mo* /XD Mu* /XD $* /XD "System*" 
REM call Backup "\." /A-:NT /XD Cameras /XD Movies /XD Mobile /XD $RECYCLE.BIN /XD "System*" 

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause
