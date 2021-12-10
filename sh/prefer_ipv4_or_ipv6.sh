#!/bin/bash
prefer_ipv4(){
    sed -i "s/label 2002::\/16   2/precedence ::ffff:0:0\/96  100/g" /etc/gai.conf
    grep -qE '^[ ]*precedence[ ]*::ffff:0:0/96[ ]*100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
    echo "[完成] 配置IPv4优先"
}
prefer_ipv6(){
    sed -i "s/precedence ::ffff:0:0\/96  100/label 2002::\/16   2/g" /etc/gai.conf
    grep -qE '^[ ]*label[ ]*2002::/16[ ]*2' /etc/gai.conf || echo 'label 2002::/16   2' >> /etc/gai.conf
    echo "[完成] 配置IPv6优先"
}
while :
do
    echo "0.退出"
    echo "1.IPv4优先"
    echo "2.IPv6优先"
    read -p "请选择: " pkey
    case ${pkey} in
    0)
        break 1
        ;;
    1)
        prefer_ipv4
        break 1
        ;;
    2)
        prefer_ipv6
        break 1
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 请重新输入"
        ;;
    esac
done