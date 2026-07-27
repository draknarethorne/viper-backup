@Echo On

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
