@echo off
title 强制删除
:delete
set input=
set /p input=是否强制删除(y/n):
if "%input%"=="y" (
    DEL /F /A /Q \\?\%1
    RD /S /Q \\?\%1
)