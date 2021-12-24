#!/bin/bash
get_ip(){
    ip_address=$(grep "address" /etc/network/interfaces | head -n 1)
    ip_address=${ip_address//address /}
}
while :
do
    read -p "是否要阻止Plex本地网络发现功能?（y/N）:" skey
    case ${skey} in
    [yY])
        ufw deny out from any to 239.255.255.250 port 1900
        get_ip
        echo -e "使用此命令进行监控: \033[32;1mtcpdump \"src ${ip_address} and dst 239.255.255.250\"\033[0m"
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