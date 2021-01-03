#!/bin/bash
echo "#安装/更新 trojan面板"
echo "source <(curl -sL https://git.io/trojan-install)"
echo "#卸载 trojan面板"
echo "source <(curl -sL https://git.io/trojan-install) --remove"
echo -e "\033[31;1m [注意] \033[0m 若要使用trojan面板，必须安装docker"
key=$(which docker)
if [[ ${key} =~ "docker" ]];then
    echo -e "docker状态:\033[32;1m 已安装 \033[0m"
else
    echo -e "docker状态:\033[31;1m 未安装 \033[0m"
fi
while :
do
    read -p "是否要安装并启动docker?（y/N）:" dkey
    case ${dkey} in
    [yY])
        curl -fsSL https://get.docker.com | bash -s docker
        systemctl enable docker
        systemctl start docker
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