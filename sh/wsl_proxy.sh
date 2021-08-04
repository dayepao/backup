# 添加到/home/user_name/.bashrc中

proxy=$(cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }')

setp(){
    export http_proxy="http://${proxy}:10809"  # http代理地址
    echo "启动http代理"
    export https_proxy="http://${proxy}:10809" # https代理地址
    echo "启动https代理"
}

unsetp(){
    unset http_proxy
    echo "停止http代理"
    unset https_proxy
    echo "停止https代理"
}