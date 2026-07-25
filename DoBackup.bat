@Echo On
set BACKUP_ROBO=YES

Echo ******************************************************************** >> Backup.Log
Echo **      Backup Files - %DATE% %TIME%                  **>> Backup.Log
Echo ******************************************************************** >> Backup.Log
Echo. >> Backup.Log

@Echo Off

if exist Backup_Details_09.log del Backup_Details_09.log
if exist Backup_Details_08.log ren Backup_Details_08.log Backup_Details_09.log
if exist Backup_Details_07.log ren Backup_Details_07.log Backup_Details_08.log
if exist Backup_Details_06.log ren Backup_Details_06.log Backup_Details_07.log
if exist Backup_Details_05.log ren Backup_Details_05.log Backup_Details_06.log
if exist Backup_Details_04.log ren Backup_Details_04.log Backup_Details_05.log
if exist Backup_Details_03.log ren Backup_Details_03.log Backup_Details_04.log
if exist Backup_Details_02.log ren Backup_Details_02.log Backup_Details_03.log
if exist Backup_Details_01.log ren Backup_Details_01.log Backup_Details_02.log
if exist Backup_Details.log ren Backup_Details.log Backup_Details_01.log

Echo ******************************************************************** >> Backup_Details.Log
Echo **      Backup Files - %DATE% %TIME%                  **>> Backup_Details.Log
Echo ******************************************************************** >> Backup_Details.Log
Echo. >> Backup_Details.Log

REM *************************************************
REM ** Backup C: Folders
REM *************************************************

set BACKUP_SRC=C:
set BACKUP_DEST=D:\Backup_Folders

REM call backup "\Ant"
REM call backup "\EQTimer"
REM call backup "\ICAN"
REM call backup "\Gradle"
REM call backup "\Minecraft"
REM call backup "\RunUO"
REM call backup "\RunUO-Archive"
call backup "\Soverign-Territories"
call backup "\TAKP"
REM call backup "\THJ"
call backup "\Thorne-Timer"
call backup "\Thorne-UI"

REM *************************************************
REM ** Backup Users
REM *************************************************

call DoBackupGT.bat NoPause
call DoBackupHS.bat NoPause
call DoBackupMB.bat NoPause
call DoBackupST.bat NoPause
REM call DoBackupYA.bat NoPause

REM *************************************************
REM ** Backup to Server
REM *************************************************

call DoServerHS.bat NoPause

REM *************************************************
REM ** Backup Media to Computers
REM *************************************************

call DoMediaGT.bat NoPause
call DoMediaHS.bat NoPause
call DoMediaMB.bat NoPause

REM *************************************************
REM ** Backup to Internal Drives
REM *************************************************
 
REM call DoEDrive.bat NoPause
call DoKDrive.bat NoPause
REM call DoLDrive.bat NoPause

:End

Echo ******************************************************************** >> Backup_Details.Log
Echo **    Backup Complete - %DATE% %TIME%                  **>> Backup_Details.Log
Echo ******************************************************************** >> Backup_Details.Log
Echo. >> Backup_Details.Log

@Echo On
Echo ******************************************************************** >> Backup.Log
Echo **    Backup Complete - %DATE% %TIME%                  **>> Backup.Log
Echo ******************************************************************** >> Backup.Log
Echo. >> Backup.Log

if "%1" == "" pause

