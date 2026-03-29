#!/bin/bash
while :
do
    read -p "是否要将时区设置为北京时区?(y/N):" key
    case ${key} in
    [yY])
        timedatectl set-timezone Asia/Shanghai
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