@Echo Off

echo Removing mapping %1 ...
net use %1 /d /yes 2> nul
if errorlevel 1 echo %1 mapping does not exist.
echo.

if x\%2 == x\/d GoTo End

:NetUse

echo. >> Backup_Details.log
echo ============================================ >> Backup_Details.log
echo net use %1 %2 %3 %4 %5 %6 %7 %8 %9 >> Backup_Details.log
echo ============================================ >> Backup_Details.log

echo Mapping drive %1 ...
echo net use %1 %2 %3 %4 %5 %6 %7 %8 %9
net use %1 %2 %3 %4 %5 %6 %7 %8 %9

:End
REM
