#!/bin/bash
while :
do
    read -p "是否要安装 v2-ui ?（y/N）:" v2key
    case ${v2key} in
    [yY])
        wget "https://blog.sprov.xyz/v2-ui.sh" -O v2ui_install.sh
        bash v2ui_install.sh
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