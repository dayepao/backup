#!/bin/bash
while :
do
    read -p "是否要设置系统语言为中文?(y/N):" skey
    case ${skey} in
    [yY])
        sed -i '/^LANG=/s/^\(LANG=.*\)/# \1/' $HOME/.profile
        sed -i '/^LANGUAGE=/s/^\(LANGUAGE=.*\)/# \1/' $HOME/.profile
        sed -i '/#.*zh_CN.UTF-8 UTF-8/s/^#[[:space:]]*//' /etc/locale.gen && ! grep -qE "^[[:space:]]*zh_CN.UTF-8 UTF-8" /etc/locale.gen && echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen
        update-locale "LANG=zh_CN.UTF-8"
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