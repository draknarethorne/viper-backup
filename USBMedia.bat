@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:
set BACKUP_DEST=E:

call backup "\Media" /A-:NT

if "%1" == "" pause
