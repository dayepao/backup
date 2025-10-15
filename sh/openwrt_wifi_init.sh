#!/bin/sh

# 返回码约定：
# 0 = 进行了重新配置
# 2 = 检测到已有无线接口，未重新配置（跳过）

setup_wifi() {
    # 检查是否已有无线设备配置
    if iw dev | grep -q "Interface"; then
        logger "检测到已有无线设备配置，跳过重新配置。"
        return 2
    fi

    logger "未检测到无线设备，开始重新配置..."

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
    uci set wireless.wifinet1.ssid='TJ-DORM-WIFI'
    uci set wireless.wifinet1.encryption='none'

    uci commit wireless
    wifi

    sleep 5
    uci set wireless.@wifi-iface[0].disabled='0'
    uci commit wireless
    wifi

    sleep 5
    uci set wireless.@wifi-iface[0].disabled='1'
    uci commit wireless
    wifi

    /etc/init.d/network restart

    return 0
}

restart_openclash() {
    if [ -x /etc/init.d/openclash ]; then
        logger "重启 OpenClash..."
        /etc/init.d/openclash restart
    else
        logger "未找到 /etc/init.d/openclash，跳过重启。"
    fi
}

# 根据参数决定执行逻辑
case "$1" in
    init)
        logger "初始化模式"
        setup_wifi
        sleep 60
        setup_wifi
        sleep 60
        setup_wifi
        sleep 60
        ;;
    check)
        logger "检测模式"
        setup_wifi
        rc=$?
        if [ "$rc" -eq 0 ]; then
            logger "Wi-Fi 已重新配置，准备重启 OpenClash。"
            restart_openclash
        else
            logger "Wi-Fi 无需重新配置，不重启 OpenClash。"
        fi
        ;;
    *)
        logger "初始化WiFi脚本：参数错误"
        exit 1
        ;;
esac
