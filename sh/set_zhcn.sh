#!/bin/bash

is_supported_system() {
    [ -r /etc/os-release ] || return 1

    . /etc/os-release

    case " ${ID:-} ${ID_LIKE:-} " in
    *" debian "* | *" ubuntu "*) ;;
    *)
        return 1
        ;;
    esac

    command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1
}

while :; do
    read -p "是否要设置系统语言为中文?(y/N):" skey
    case ${skey} in
    [yY])
        if ! is_supported_system; then
            echo -e "\033[31;1m [错误] \033[0m 当前脚本只支持 Debian/Ubuntu 及其衍生系统"
            exit 1
        fi

        if ! dpkg-query -W -f='${Status}' locales 2>/dev/null | grep -q "install ok installed"; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y locales
        fi

        sed -i '/^LANG=/s/^\(LANG=.*\)/# \1/' $HOME/.profile
        sed -i '/^LANGUAGE=/s/^\(LANGUAGE=.*\)/# \1/' $HOME/.profile
        sed -i '/#.*zh_CN.UTF-8 UTF-8/s/^#[[:space:]]*//' /etc/locale.gen && ! grep -qE "^[[:space:]]*zh_CN.UTF-8 UTF-8" /etc/locale.gen && echo "zh_CN.UTF-8 UTF-8" >>/etc/locale.gen
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
