#!/bin/bash
case $1 in
    start)
        wondershaper -a eth0 -u 1024000
        # wondershaper -a lo -d 512000
        ;;
    stop)
        wondershaper -c -a eth0
        # wondershaper -c -a lo
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 参数错误"
        ;;
esac
