#!/bin/sh

# 这里判断是否已经属于登录状态 如果是则退出脚本
# captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
# if [ "${captiveReturnCode}" = "204" ]; then
resp="$(curl -fsSL --connect-timeout 3 -m 5 http://172.21.0.62/ 2>/dev/null)"
curl_status=$?

if [ $curl_status -ne 0 ]; then
    logger "校园网认证：检测到无法访问认证页面，重启 WiFi"
    wifi reload 2>/dev/null || wifi
    exit 2
fi

if echo "$resp" | grep -q "uid="; then
    logger "校园网认证：已认证"
    exit 0
fi

loginURL="http://172.21.0.62/drcom/login"

# 用户名
username=$1

# 密码
password=$2

# 运营商
case $3 in
    xyw)
        service="0"
        ;;
    yd)
        service="2"
        ;;
    lt)
        service="3"
        ;;
    dx)
        service="4"
        ;;
    *)
        logger "校园网认证：运营商参数错误"
        exit 0
        ;;
esac

callback="dr1003"
DDDDD=${username}
upass=${password}
tmp0MKKey="123456"
R1="0"
R2=""
R3=${service}
R6="0"
para="00"
v6ip=""
terminal_type="1"
lang1="zh-cn"
jsVersion="4.1"
v="5021"
lang2="zh"

auth=`curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36" "${loginURL}?callback=${callback}&DDDDD=${DDDDD}&upass=${upass}&0MKKey=${tmp0MKKey}&R1=${R1}&R2=${R2}&R3=${R3}&R6=${R6}&para=${para}&v6ip=${v6ip}&terminal_type=${terminal_type}&lang=${lang1}&jsVersion=${jsVersion}&v=${v}&lang=${lang2}"`
logger $auth
