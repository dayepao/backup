#!/bin/bash
while :
do
    read -p "是否要安装trojan面板?（y/N）:" tkey
    case ${tkey} in
    [yY])
        curl -fsSL https://get.docker.com | bash -s docker
        systemctl enable docker
        systemctl start docker
        echo "#安装/更新"
        echo "source <(curl -sL https://git.io/trojan-install)"
        echo "#卸载"
        echo "source <(curl -sL https://git.io/trojan-install) --remove"
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