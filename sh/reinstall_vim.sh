#!/bin/bash

is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

if is_package_installed vim || ! is_package_installed vim-common; then
    exit 0
fi

while :
do
    read -p "是否要重新安装vim?(y/N):" rkey
    case ${rkey} in
    [yY])
        apt remove -y vim-common
        apt install -y vim
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
