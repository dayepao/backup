@echo off
title youtube-dl助手
:youtube_dl
set url=
set /p url=请输入视频链接:
.\youtube-dl.exe %url% --external-downloader .\aria2c.exe --external-downloader-args "-x 16 -k 1M" --exec "move {} downloads\{}"
cd downloads
for %%i in (*.flv) do (
    ..\ffmpeg.exe -loglevel quiet -i "%%i" -c copy "%%~ni.mp4"
    del "%%i"
)
cd ..
set key=
set /p key=是否继续下载(y/n):
if "%key%"=="y" (
    goto youtube_dl
)