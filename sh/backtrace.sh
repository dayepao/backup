#!/bin/bash
while :
do
    read -p "是否要测试回程路由?(y/N):" bkey
    case ${bkey} in
    [yY])
        curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
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