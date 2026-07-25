@Echo off
set BACKUP_ROBO=YES

REM *************************************************
REM ** Backup Featherstone
REM *************************************************
:FeatherstoneServer

set BACKUP_SRC=Y:
set BACKUP_DEST=D:\Backup_Server\CMIS-957903A-HS

call netuse %BACKUP_SRC% \\cmis-957903a-hs\cdrive$

call backup "\Minecraft"
call backup "\Minecraft-Backups"
call backup "\Minecraft-Pokemon"
call backup "\RunUO"
call backup "\RunUO-Backups"

call netuse %BACKUP_SRC% /d

REM *************************************************
REM ** Backup Featherstone Archives
REM *************************************************
:FeatherstoneArchive

set BACKUP_SRC=Y:
set BACKUP_DEST=D:\Archive_Server\CMIS-957903A-HS

call netuse %BACKUP_SRC% \\cmis-957903a-hs\ddrive$\Backup_Folders

call backup "\Minecraft-Backups-Archive"
call backup "\RunUO-Archive"
call backup "\RunUO-Backups-Archive"

call netuse %BACKUP_SRC% /d

REM echo **************************************************
REM echo *** REMOVE THE PAUSE!!!!
REM echo **************************************************

REM if errorlevel 1 pause

if "%1" == "" pause