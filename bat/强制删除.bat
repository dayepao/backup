@echo off
title ǿ��ɾ��
:delete
set input=
set /p input=�Ƿ�ǿ��ɾ��(y/n):
if "%input%"=="y" (
    DEL /F /A /Q \\?\%1
    RD /S /Q \\?\%1
)