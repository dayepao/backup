#!/bin/bash
while :
do
    read -p "是否要运行VPS跑分多合一脚本?（y/N）:" skey
    case ${skey} in
    [yY])
        wget git.io/vpstest && bash vpstest
        rm -rf vpsTest
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