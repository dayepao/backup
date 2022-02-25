#!/bin/bash
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