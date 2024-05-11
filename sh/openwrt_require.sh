#!/bin/bash
while :; do
    read -p "是否要安装编译openwrt所需依赖?(y/N):" rkey
    case ${rkey} in
    [yY])
        sudo apt update -y
        sudo apt full-upgrade -y
        sudo apt install -y bison build-essential clang file flex g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-distutils qemu-utils rsync unzip wget zlib1g-dev
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
