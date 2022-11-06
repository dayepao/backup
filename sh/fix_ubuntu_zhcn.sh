#!/bin/bash
while :
do
    read -p "是否要修复Ubuntu中文乱码?(y/N):" fkey
    case ${fkey} in
    [yY])
        locale-gen en_US.UTF-8
        locale-gen zh_CN.UTF-8
        update-locale "LANG=en_US.UTF-8"
        update-locale "LANGUAGE=zh_CN:zh:en_US:en"
        locale-gen --purge
        dpkg-reconfigure --frontend noninteractive locales
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