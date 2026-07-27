@Echo Off
set "BACKUP_LAST_EXIT=0"

if /I "%BACKUP_ROBO%" == "YES" goto RoboBackup

if X\%1 == X\ goto Usage
if X\%2 == X\ goto Backup

echo xcopy %1 %2 /Y /C /D /I /R /K /Z
xcopy %1 %2 /Y /C /D /I /R /K /Z
set "BACKUP_LAST_EXIT=%ERRORLEVEL%"
if not "%BACKUP_LAST_EXIT%" == "0" goto Error

goto EndWithExit

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
set "BACKUP_LAST_EXIT=%ERRORLEVEL%"
if %BACKUP_LAST_EXIT% GEQ 8 goto RobocopyError

REM echo robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /MIR /R:0 /W:2 /XA:S /XD Crypto /XD ReportArchive /XD UpdatusUser /XD Temp* /XF *.tmp /XJ /NDL %2 %3 %4 %5 %6 %7 %8 %9
REM robocopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /MIR /R:0 /W:2 /XA:S /XD Crypto /XD ReportArchive /XD UpdatusUser /XD Temp* /XF *.tmp /XJ /NDL %2 %3 %4 %5 %6 %7 %8 %9

goto EndWithExit

REM --------------------------------------------
:RobocopyError
set "BACKUP_FAILED=YES"
echo ***************************************************************************  >> Backup_Details.Log
echo *** ROBOCOPY FAILED WITH EXIT CODE %BACKUP_LAST_EXIT%  >> Backup_Details.Log
echo ***************************************************************************  >> Backup_Details.Log
goto EndWithExit

REM --------------------------------------------
:Backup
if X\%BACKUP_SRC% == X\ goto Usage
if X\%BACKUP_DEST% == X\ goto Usage

echo xcopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /Y /C /D /I /H /R /K /E /Z %2 %3 %4 %5 %6 %7 %8 %9
xcopy %BACKUP_SRC%%1 %BACKUP_DEST%%1 /Y /C /D /I /H /R /K /E /Z %2 %3 %4 %5 %6 %7 %8 %9
set "BACKUP_LAST_EXIT=%ERRORLEVEL%"
if not "%BACKUP_LAST_EXIT%" == "0" goto Error

goto EndWithExit

REM --------------------------------------------
:Usage

echo Invalid argument list
echo.
echo Usage:
echo.
echo   backup [folder] [dest folder]
echo.

set "BACKUP_LAST_EXIT=16"
set "BACKUP_FAILED=YES"
goto EndWithExit

REM --------------------------------------------
:Error
set "BACKUP_FAILED=YES"
if "%BACKUP_LAST_EXIT%" == "0" set "BACKUP_LAST_EXIT=1"
echo ***************************************************************************  >> Backup_Details.Log
echo *** FATAL ERROR OCCURRED -- FIGURE OUT WHAT HAPPENED!!!  >> Backup_Details.Log
echo ***************************************************************************  >> Backup_Details.Log

REM pause

REM --------------------------------------------
:EndWithExit
echo.
exit /b %BACKUP_LAST_EXIT%
