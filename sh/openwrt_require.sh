#!/bin/bash
while :
do
    read -p "是否要安装编译openwrt所需依赖?(y/N):" rkey
    case ${rkey} in
    [yY])
        sudo apt update -y
        sudo apt full-upgrade -y
        sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
        bzip2 ccache clang cmake cpio curl device-tree-compiler fastjar file flex gawk gettext gcc-multilib \
        g++ g++-multilib git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev \
        libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev \
        libpython3-dev libreadline-dev libssl-dev libtool lrzsz genisoimage msmtp ninja-build p7zip \
        p7zip-full patch pkgconf python3 python3-distutils python3-pyelftools python3-setuptools qemu-utils \
        rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
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