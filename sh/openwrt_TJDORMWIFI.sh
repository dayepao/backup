#!/bin/sh

# 计数文件（放 /tmp，上电重启也会自然清零）
COUNT_FILE="/tmp/TJDORMWIFI_auth_fail_count"
MAX_FAIL=10

inc_fail_count() {
    # 从文件读取
    if [ -f "$COUNT_FILE" ]; then
        FAIL_COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
    else
        FAIL_COUNT=0
    fi

    # 防止文件脏内容
    case "$FAIL_COUNT" in
    '' | *[!0-9]*) FAIL_COUNT=0 ;;
    esac

    # 直接对全局变量加一
    FAIL_COUNT=$((FAIL_COUNT + 1))

    # 写回文件
    echo "$FAIL_COUNT" >"$COUNT_FILE"
}

reset_fail_count() {
    rm -f "$COUNT_FILE"
}

# 这里判断是否已经属于登录状态 如果是则退出脚本
# captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
# if [ "${captiveReturnCode}" = "204" ]; then
resp="$(curl -fsSL --connect-timeout 3 -m 5 http://172.21.0.62/ 2>/dev/null)"
curl_status=$?

if [ $curl_status -ne 0 ]; then
    # 无法访问认证页面，累加失败次数
    inc_fail_count
    logger "校园网认证：检测到无法访问认证页面，连续失败 ${FAIL_COUNT} 次"

    # 达到阈值，清空计数并重启 OpenWrt
    if [ "$FAIL_COUNT" -ge "$MAX_FAIL" ]; then
        logger "校园网认证：连续失败已达 ${MAX_FAIL} 次，清空计数并重启 OpenWrt"
        reset_fail_count
        reboot
        exit 3
    fi

    # 未达到阈值，重启 WiFi 和 OpenClash
    logger "尝试重启 Wi-Fi 接口以恢复连接"
    if command -v wifi >/dev/null 2>&1; then
        wifi reload 2>/dev/null || wifi
    else
        /etc/init.d/network reload || /etc/init.d/network restart
    fi

    logger "已重启 Wi-Fi，准备重启 OpenClash"
    sleep 5

    if [ -x /etc/init.d/openclash ]; then
        logger "重启 OpenClash..."
        /etc/init.d/openclash restart
    else
        logger "未找到 /etc/init.d/openclash，跳过重启。"
    fi
    exit 2
fi

# 能访问认证页面，说明网络至少是通的，清空失败计数
reset_fail_count

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

loginURL="${loginURL}?callback=${callback}&DDDDD=${DDDDD}&upass=${upass}&0MKKey=${tmp0MKKey}&R1=${R1}&R2=${R2}&R3=${R3}&R6=${R6}&para=${para}&v6ip=${v6ip}&terminal_type=${terminal_type}&lang=${lang1}&jsVersion=${jsVersion}&v=${v}&lang=${lang2}"
auth=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36" "${loginURL}")
logger $auth
