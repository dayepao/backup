#!/bin/bash
key=$(sysctl -n net.ipv4.tcp_congestion_control)
if [[ $key == *bbr* ]];then
    echo -e "bbr状态:\033[32;1m 已开启 \033[0m"
else
    echo -e "bbr状态:\033[31;1m 未开启 \033[0m"
fi
while :
do
    echo "1.开启bbr"
    echo "2.关闭bbr"
    echo "0.退出"
    read -p "请选择操作:" bbrkey
    case ${bbrkey} in
        1)
            if [[ $key != *bbr* ]];then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                sysctl -p
            fi
            echo "bbr开启成功, 请查看下方显示内容是否包含bbr"
            sysctl -n net.ipv4.tcp_congestion_control
            lsmod | grep bbr
            break 1
            ;;
        2)
            sed -i "/net.core.default_qdisc/d" /etc/sysctl.conf
            sed -i "/net.ipv4.tcp_congestion_control/d" /etc/sysctl.conf
            sysctl -p
            echo "bbr关闭成功, 请重启后查看效果"
            break 1
            ;;
        0)
            break 1
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done