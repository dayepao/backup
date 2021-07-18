#!/bin/bash
while :
do
    read -p "是否要运行一键bbr脚本?（y/N）:" bbrkey
    case ${bbrkey} in
    [yY])
        rm -rf tcp.sh
        wget -N --no-check-certificate -O tcp.sh "https://github.000060000.xyz/tcp.sh"
        bash tcp.sh
        rm -rf tcp.sh
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