#!/bin/sh

# 设置优先BSSID，注意使用小写
PREF_BSSID=$1

# 获取当前BSSID
CUR_BSSID=$(iw dev phy0-sta0 link | grep "Connected to" | awk '{print $3}')

# 如果没有连接，直接重启wifi
if [ -z "$CUR_BSSID" ]; then
    logger "WiFi未连接，尝试重连"
    rm -f /etc/config/wireless
    wifi config

    uci set wireless.radio0=wifi-device
    uci set wireless.radio0.band='5g'
    uci set wireless.radio0.channel='auto'
    uci set wireless.radio0.htmode='VHT20'
    uci set wireless.radio0.cell_density='0'
    uci set wireless.radio0.disabled='0'

    # uci delete wireless.@wifi-iface[0]
    uci set wireless.wifinet1=wifi-iface
    uci set wireless.wifinet1.device='radio0'
    uci set wireless.wifinet1.mode='sta'
    uci set wireless.wifinet1.network='wwan'
    uci set wireless.wifinet1.ssid='TJ-DORM-WIFI'
    uci set wireless.wifinet1.encryption='none'

    uci commit wireless
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
