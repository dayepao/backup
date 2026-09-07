#!/bin/sh

# 计数文件（放 /tmp，上电重启也会自然清零）
COUNT_FILE="/tmp/TJDORMWIFI_auth_fail_count"
MAX_FAIL=5

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

# 尝试访问认证页面
resp="$(curl -fsSL --connect-timeout 3 -m 5 http://172.21.0.62/ 2>/dev/null)"
auth_status=$?

# 初始化最终故障标记：0=正常，1=彻底失败
network_dead=0

if [ $auth_status -ne 0 ]; then
    # 认证页面访问失败了，检查外网(204)是否正常
    probe_code=$(curl -s -I -m 5 --connect-timeout 3 -o /dev/null -w %{http_code} http://www.google.cn/generate_204)

    if [ "${probe_code}" = "204" ]; then
        reset_fail_count
        logger "校园网认证：外网访问正常，跳过认证"
        exit 0
    fi

    # 外网也不通 (既不是认证页，也不是204)，判定为彻底失败
    network_dead=1
fi

# 只有无法访问认证页且无法访问外网的时候，才执行报错逻辑
if [ $network_dead -eq 1 ]; then
    # 累加失败次数
    inc_fail_count
    logger "校园网认证：检测到认证页面与外网均无法访问，连续失败 ${FAIL_COUNT} 次"

    # 达到阈值，清空计数并重启 OpenWrt
    if [ "$FAIL_COUNT" -ge "$MAX_FAIL" ]; then
        logger "校园网认证：连续失败已达 ${MAX_FAIL} 次，清空计数并重启 OpenWrt"
        reset_fail_count
        reboot
        exit 3
    fi

    exit 2
fi

# 能访问认证页面，清空失败计数
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
auth=$(curl -s --connect-timeout 3 -m 10 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0" "${loginURL}")
login_status=$?

# curl 超时或失败时，已收到的响应仍会保留，但不能保证完整。
case "$login_status" in
0) login_result="登录请求完成" ;;
28) login_result="登录请求超时，响应可能不完整" ;;
*) login_result="登录请求失败（curl 退出码：${login_status}），响应可能不完整" ;;
esac

logger "校园网认证：${login_result}，响应：${auth:-未收到响应体}"
exit "$login_status"
