@Echo off
set BACKUP_ROBO=YES

set BACKUP_SRC=D:\Media
set BACKUP_DEST=E:\Media

call backup "\Pictures\2012" /A-:NT
call backup "\Pictures\2013" /A-:NT
call backup "\Pictures\2014" /A-:NT
call backup "\Pictures\2015" /A-:NT
call backup "\Pictures\2016" /A-:NT
call backup "\Pictures\2017" /A-:NT
call backup "\Pictures\2018" /A-:NT
call backup "\Pictures\2019" /A-:NT
call backup "\Pictures\2020" /A-:NT
call backup "\Pictures\2021" /A-:NT
call backup "\Pictures\2022" /A-:NT
call backup "\Pictures\2023" /A-:NT
call backup "\Pictures\2024" /A-:NT
call backup "\Pictures\2025" /A-:NT
call backup "\Pictures\2026" /A-:NT

if "%1" == "" pause