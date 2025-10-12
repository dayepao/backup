#!/bin/sh

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

sleep 2
uci set wireless.@wifi-iface[0].disabled='0'
uci commit wireless
wifi

sleep 2
uci set wireless.@wifi-iface[0].disabled='1'
uci commit wireless
wifi
