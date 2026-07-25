@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:\Media
set BACKUP_DEST=T:

REM call netuse %BACKUP_DEST% \\cmis-957903a-ni\media$

REM call backup "\Music"
REM call backup "\Pictures" /XD "200*" /XD "2010" /XD "2011" /XD "2012" /XD "2013"

REM call netuse %BACKUP_DEST% /d

REM ******************************************************
REM *** Backup D:\Setup to NI Machine
REM ******************************************************
:SetupNI

set BACKUP_SRC=D:
set BACKUP_DEST=T:

REM call netuse %BACKUP_DEST% \\cmis-957903a-ni\ddrive$

REM call backup "\Setup"
REM call backup "\Setup Games"

REM call netuse %BACKUP_DEST% /d

if "%1" == "" pause