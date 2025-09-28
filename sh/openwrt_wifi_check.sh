#!/bin/sh

# 设置优先BSSID，注意使用小写
PREF_BSSID=$1

# 获取当前BSSID
CUR_BSSID=$(iw dev phy0-sta0 link | grep "Connected to" | awk '{print $3}')

# 如果没有连接，直接重启wifi
if [ -z "$CUR_BSSID" ]; then
    logger "WiFi未连接，尝试重连"
    wifi
    exit 0
fi

# 扫描是否能看到优先BSSID
SCAN=$(iw dev phy0-sta0 scan | grep "${PREF_BSSID}")

if [ "${CUR_BSSID}" != "${PREF_BSSID}" ]; then
    if [ -n "${SCAN}" ]; then
        logger "当前连接WIFI BSSID：${CUR_BSSID}，优先BSSID：${PREF_BSSID}可用，重启WiFi切换"
        wifi
    else
        logger "当前连接WIFI BSSID：${CUR_BSSID}，优先BSSID：${PREF_BSSID}不可用，保持现状"
    fi
else
    logger "已连接优先WIFI BSSID：${CUR_BSSID}"
fi
