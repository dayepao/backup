@echo off
title hash_lyh
:hash
set input=
set /p input=��ѡ��У������(MD2 MD4 MD5 SHA1 SHA256 SHA384 SHA512):
echo ���ڴ���...
certutil -hashfile %1 %input%
goto hash