#!/bin/bash
while :
do
    read -p "是否要配置PVE的UPS连接?(y/N):" rkey
    case ${rkey} in
    [yY])
        apt install apcupsd -y
        sed -i "s/^DEVICE .*$/DEVICE/g" /etc/apcupsd/apcupsd.conf
        sed -i "s/^BATTERYLEVEL .*$/BATTERYLEVEL 50/g" /etc/apcupsd/apcupsd.conf
        sed -i "s/^MINUTES .*$/MINUTES 30/g" /etc/apcupsd/apcupsd.conf
        sed -i "s/^TIMEOUT .*$/TIMEOUT 300/g" /etc/apcupsd/apcupsd.conf
        systemctl enable apcupsd
        systemctl restart apcupsd
        break 1
        ;;
    [nN])
        break 1
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 请重新输入"
        ;;
    esac
done