#!/bin/bash
fix_route(){
    gateway=$(grep "gateway" /etc/network/interfaces)
    nline=${gateway//gateway /}
    nline="post-up /sbin/ip -r route del ${nline::-1}0/24"
    grep -qE "${nline}" /etc/network/interfaces || echo "$nline" >> /etc/network/interfaces
    /etc/init.d/networking restart
}
while :
do
    read -p "是否要修复斯巴达同网段路由问题?（y/N）:" fkey
    case ${fkey} in
    [yY])
        fix_route
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