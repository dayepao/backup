# 添加到/home/user_name/.bashrc中
set_up_proxy(){
    if [[ ${USER} == "root" ]];then
        bashrc_path="/root/.bashrc"
    else
        bashrc_path="/home/${USER}/.bashrc"
    fi

    echo "\${proxy}为\"WSL的宿主机地址\"或 \"127.0.0.1\""
    read -p "请输入http代理地址(默认为\"http://\${proxy}:10809\"): " http_proxy
    read -p "请输入https代理地址(默认与\"http代理地址\"相同): " https_proxy
    if [[ ${http_proxy} == '' ]];then
        http_proxy='http://${proxy}:10809'
    fi
    if [[ ${https_proxy} == '' ]];then
        https_proxy=${http_proxy}
    fi

cat >> ${bashrc_path} <<EOF


if [[ \$(uname -r) =~ 'WSL' ]];then
    proxy=\$(cat /etc/resolv.conf | grep nameserver | awk '{ print \$2 }')
else
    proxy="127.0.0.1"
fi

setp(){
    export http_proxy="${http_proxy}"  # http代理地址
    echo "启动http代理"
    export https_proxy="${https_proxy}" # https代理地址
    echo "启动https代理"
}

unsetp(){
    unset http_proxy
    echo "停止http代理"
    unset https_proxy
    echo "停止https代理"
}
EOF

echo "配置完成，重启终端生效"
echo "输入 setp 启用代理"
echo "输入 unsetp 停止代理"
}


while :
do
    read -p "是否要配置 bash 代理?（y/N）:" pkey
    case ${pkey} in
    [yY])
        set_up_proxy
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
