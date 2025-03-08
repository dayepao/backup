#!/bin/bash
while :
do
    read -p "是否要安装 3x-ui ?(y/N):" v2key
    case ${v2key} in
    [yY])
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
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