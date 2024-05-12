#!/bin/bash
while :; do
    read -p "是否要安装编译openwrt所需依赖?(y/N):" rkey
    case ${rkey} in
    [yY])
        sudo apt update -y
        sudo apt full-upgrade -y
        os_id=$(awk -F= '$1=="ID" {print $2}' /etc/os-release | tr -d '"')
        os_version_id=$(awk -F= '$1=="VERSION_ID" {print $2}' /etc/os-release | tr -d '"')
        if [ "${os_id}" == "ubuntu" ] && [ "${os_version_id}" == "24.04" ]; then
            sudo apt install -y bison build-essential clang file flex g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools qemu-utils rsync swig unzip wget zlib1g-dev
        else
            sudo apt install -y bison build-essential clang file flex g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-distutils qemu-utils rsync unzip wget zlib1g-dev
        fi
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
