#!/bin/bash
while :
do
    read -p "是否要安装 1Panel ?(y/N):" pkey
    case ${pkey} in
    [yY])
        curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh
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