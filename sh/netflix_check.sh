while :
do
    read -p "是否要检测Netflix解锁情况?（y/N）:" nfkey
    case ${nfkey} in
    [yY])
        bash <(curl -sSL "https://raw.githubusercontent.com/CoiaPrant/Netflix_Unlock_Information/main/netflix.sh")
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