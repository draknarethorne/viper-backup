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
