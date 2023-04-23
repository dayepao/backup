while :
do
    read -p "是否要检测流媒体解锁情况?(y/N):" mckey
    case ${mckey} in
    [yY])
        # apt install -y jq
        # bash <(curl -sSL "https://github.com/CoiaPrant/MediaUnlock_Test/raw/main/check.sh")
        # rm -rf check.log
        bash <(curl -L -s check.unlock.media)
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