#!/bin/bash
while :
do
    echo "请选择测试模式"
    echo "1.快速测试"
    echo "2.完整测试"
    echo "0.退出"
    read -p "请选择：" key
    case ${key} in
        1)
            curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast
            rm -rf LemonBench.Result.txt
            break 1
            ;;
        2)
            curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s full
            rm -rf LemonBench.Result.txt
            break 1
            ;;
        0)
            break 1
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done