@Echo Off

if %BACKUP_ROBO% == YES goto RoboBackup

if X\%1 == X\ goto Usage
if X\%2 == X\ goto Backup

echo xcopy %1 %2 /Y /C /D /I /R /K /Z
xcopy %1 %2 /Y /C /D /I /R /K /Z || goto Error

goto End

REM --------------------------------------------
:RoboBackup

if X\%BACKUP_SRC% == X\ goto Usage
if X\%BACKUP_DEST% == X\ goto Usage

echo.
echo ===============================================================================

net use
net use >> Backup_Details.log

echo ===============================================================================
echo.

REM ** This version has the log file
REM echo robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /DST /MIR /R:0 /W:2 /XA:S /XD .tmp* /XD Temp* /XF *.tmp /XJ /NP /LOG+:Backup_Details.log /TEE /NDL %2 %3 %4 %5 %6 %7 %8 %9
REM robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /DST /MIR /R:0 /W:2 /XA:S /XD .tmp* /XD Temp* /XF *.tmp /NP /XJ /LOG+:Backup_Details.log /TEE /NDL %2 %3 %4 %5 %6 %7 %8 %9

echo robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /DST /MIR /R:0 /W:2 /XA:S /XD .tmp* /XD Temp* /XF *.tmp /XJ /NP /LOG+:Backup_Details.log /TEE /NDL %2 %3 %4 %5 %6 %7 %8 %9
robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /DST /MIR /R:0 /W:2 /XA:S /XD .tmp* /XD Temp* /XF *.tmp /NP /XJ /LOG+:Backup_Details.log /TEE /NDL %2 %3 %4 %5 %6 %7 %8 %9

REM echo robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /MIR /R:0 /W:2 /XA:S /XD Crypto /XD ReportArchive /XD UpdatusUser /XD Temp* /XF *.tmp /XJ /NDL %2 %3 %4 %5 %6 %7 %8 %9
REM robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /MIR /R:0 /W:2 /XA:S /XD Crypto /XD ReportArchive /XD UpdatusUser /XD Temp* /XF *.tmp /XJ /NDL %2 %3 %4 %5 %6 %7 %8 %9

goto End

REM --------------------------------------------
:Backup
if X\%BACKUP_SRC% == X\ goto Usage
if X\%BACKUP_DEST% == X\ goto Usage

echo xcopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /Y /C /D /I /H /R /K /E /Z %2 %3 %4 %5 %6 %7 %8 %9
xcopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /Y /C /D /I /H /R /K /E /Z %2 %3 %4 %5 %6 %7 %8 %9 || goto Error

goto End

REM --------------------------------------------
:Usage

echo Invalid argument list
echo.
echo Usage:
echo.
echo   backup [folder] [dest folder]
echo.

goto End

REM --------------------------------------------
:Error
echo ***************************************************************************  >> Backup_Details.Log
echo *** FATAL ERROR OCCURRED -- FIGURE OUT WHAT HAPPENED!!!  >> Backup_Details.Log
echo ***************************************************************************  >> Backup_Details.Log

REM pause

REM --------------------------------------------
:End
echo.