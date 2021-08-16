#!/bin/bash
chose_para(){
    while :
    do
        echo ""
        echo "请选择要安装的内容: "
        echo "1.lnmp"
        echo "2.lamp"
        echo "3.lnmpa"
        echo "4.单独安装 nginx"
        echo "5.单独安装数据库"
        read -p "请选择: " parakey
        case ${parakey} in
            1)
                ./install.sh lnmp
                break 1
                ;;
            2)
                ./install.sh lamp
                break 1
                ;;
            3)
                ./install.sh lnmpa
                break 1
                ;;
            4)
                ./install.sh nginx
                break 1
                ;;
            5)
                ./install.sh db
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
    echo "安装完成"
    echo -e "输入\033[32;1m lnmp vhost add \033[0m添加网站"
}

while :
do
    read -p "是否要安装 lnmp ?（y/N）:" lkey
    case ${lkey} in
    [yY])
        wget http://soft.vpser.net/lnmp/lnmp1.8.tar.gz -cO lnmp1.8.tar.gz
        tar zxf lnmp1.8.tar.gz
        cd lnmp1.8
        chose_para
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