@echo off
title hash_lyh
:hash
set input=
set /p input=请选择校验类型(MD2 MD4 MD5 SHA1 SHA256 SHA384 SHA512):
echo 正在处理...
certutil -hashfile %1 %input%
goto hash