#!/bin/bash
while :
do
    read -p "是否要运行融合怪脚本?(y/N):" key
    case ${key} in
    [yY])
        curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
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