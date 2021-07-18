#!/bin/bash
echo ""
echo -e "\033[32;1m#安装/更新 trojan面板\033[0m"
echo "source <(curl -sL https://git.io/trojan-install)"
echo -e "\033[32;1m#卸载 trojan面板\033[0m"
echo "source <(curl -sL https://git.io/trojan-install) --remove"
echo ""
echo -e "\033[31;1m [注意] \033[0m 若要使用trojan面板，必须安装docker"
key=$(command -v docker)
if [[ ${key} =~ "docker" ]];then
    echo -e "docker状态:\033[32;1m 已安装 \033[0m"
else
    echo -e "docker状态:\033[31;1m 未安装 \033[0m"
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
fi
