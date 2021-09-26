#!/bin/bash
while :
do
    read -p "是否要安装编译openwrt所需依赖?（y/N）:" rkey
    case ${rkey} in
    [yY])
        sudo apt update
        sudo apt upgrade -y
        # sudo apt remove -y vim-common
        # sudo apt install -y vim
        sudo apt install -y build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
        sudo apt install -y libncurses5
        sudo apt install -y ninja-build pkg-config libnss3-dev
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