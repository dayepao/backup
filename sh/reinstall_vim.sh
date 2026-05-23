#!/bin/bash

is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

while :; do
    read -p "是否要重新安装vim?(y/N):" rkey
    case ${rkey} in
    [yY])
        if is_package_installed vim; then
            echo "vim 已安装，跳过重新安装"
            break 1
        fi

        if ! is_package_installed vim-common; then
            echo "vim-common 未安装，跳过重新安装"
            break 1
        fi

        echo "检测到 vim-common 已安装且 vim 未安装，开始重新安装 vim"
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
