#!/bin/sh
# 用法: ./init_wifi.sh "SSID" "BSSID(optional, 11:22:33:44:55:66)"
# 返回码：0 = 重新配置；2 = 已有接口，跳过

SSID="${1:-TJ-DORM-WIFI}"
BSSID_RAW="$2"

to_upper() { echo "$1" | tr 'a-f' 'A-F'; }
is_mac() { echo "$1" | grep -Eiq '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$'; }

BSSID=""
if [ -n "$BSSID_RAW" ]; then
    BSSID="$(to_upper "$BSSID_RAW")"
    if ! is_mac "$BSSID"; then
        logger "BSSID 格式不合法: $BSSID_RAW，已忽略"
        BSSID=""
    fi
fi

reload_wifi() {
    if command -v wifi >/dev/null 2>&1; then
        wifi reload 2>/dev/null || wifi
    else
        /etc/init.d/network reload || /etc/init.d/network restart
    fi
}

has_ssid_iface() {
    iw dev 2>/dev/null | awk -v target="$SSID" '
        /^[[:space:]]*ssid[[:space:]]/ {
            ssid = $0
            sub(/^[[:space:]]*ssid[[:space:]]+/, "", ssid)
            if (ssid == target) {
                found = 1
            }
        }
        END { exit found ? 0 : 1 }
    '
}

# 固件 bug workaround：对无线接口做禁用<->启用抖动
# bounce_default_iface() {
#     if uci -q get wireless.@wifi-iface[1] >/dev/null 2>&1; then
#         uci set wireless.@wifi-iface[0].disabled='0'
#         uci set wireless.@wifi-iface[1].disabled='1'
#         uci commit wireless
#         reload_wifi

#         sleep 5
#         uci set wireless.@wifi-iface[0].disabled='1'
#         uci set wireless.@wifi-iface[1].disabled='0'
#         uci commit wireless
#         reload_wifi
#         logger "已按固件 workaround 对无线接口进行禁用<->启用切换"
#     else
#         logger "未找到 wifi-iface[1]，跳过 workaround"
#     fi
# }

init_wifi() {
    # 检查是否已有目标 SSID 对应的无线接口，若存在则跳过重配
    if has_ssid_iface; then
        logger "检测到已有 SSID(${SSID}) 对应的无线接口，跳过重新配置。"
        return 2
    fi

    logger "未检测到 SSID(${SSID}) 对应的无线接口，开始重新配置..."

    rm -f /etc/config/wireless
    wifi config

    uci set wireless.radio0=wifi-device
    uci set wireless.radio0.band='5g'
    uci set wireless.radio0.channel='auto'
    uci set wireless.radio0.htmode='VHT20'
    uci set wireless.radio0.cell_density='0'
    uci set wireless.radio0.disabled='0'

    uci set wireless.wifinet1=wifi-iface
    uci set wireless.wifinet1.device='radio0'
    uci set wireless.wifinet1.mode='sta'
    uci set wireless.wifinet1.network='wwan'
    uci set wireless.wifinet1.ssid="${SSID}"
    uci set wireless.wifinet1.encryption='none'

    # 指定 BSSID（仅当提供且合法时），否则确保清除可能存在的旧 bssid 锁定
    if [ -n "$BSSID" ]; then
        uci set wireless.wifinet1.bssid="${BSSID}"
        logger "已锁定到指定 BSSID: ${BSSID}"
    else
        uci -q delete wireless.wifinet1.bssid
        logger "未指定或格式不合法，未设置 BSSID 锁定。"
    fi

    uci commit wireless
    reload_wifi

    # 执行固件 bug workaround
    # sleep 5
    # bounce_default_iface

    logger "Wi-Fi 已重新配置，准备重启 OpenClash。"
    sleep 5

    if [ -x /etc/init.d/openclash ]; then
        logger "重启 OpenClash..."
        /etc/init.d/openclash restart
    else
        logger "未找到 /etc/init.d/openclash，跳过重启。"
    fi

    return 0
}

init_wifi
