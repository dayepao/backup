#!/bin/bash
add_ipv6(){
    read -p "请输入控制面板中的IPv6地址(包括子网掩码\"/64\"): " ipv6_address
    ipv6_gateway="${ipv6_address:0:9}::1"
    wget "https://raw.githubusercontent.com/dayepao/backup/main/src/spt-ipv6.yaml" -O spt-ipv6.yaml
    sed -i "s/ipv6_address/${ipv6_address//\//\\/}/g" spt-ipv6.yaml
    sed -i "s/ipv6_gateway/${ipv6_gateway}/g" spt-ipv6.yaml
    mv spt-ipv6.yaml /etc/netplan/spt-ipv6.yaml
    netplan apply
    echo "添加IPv6完成"
}
while :
do
    read -p "是否要为斯巴达添加IPv6（适用于netplan）?(y/N):" ipv6key
    case ${ipv6key} in
    [yY])
        add_ipv6
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