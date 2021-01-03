#!/bin/bash
read -p "请输入链接：" url
read -p "请输入要剑皇的总流量(0表示无上限，单位MB)：" bw
key=0
mb=0
while [ "$(echo "${mb}<${bw}"|bc)" -eq "1" ] || [ "$bw" -eq "0" ]
do
    rm -rf jh.lyh
    wget "$url" -O jh.lyh
    key=$(($key+1))
    size=$(du -sb jh.lyh|cut -f1)
    mb=$(echo "scale=3;${mb}+${size}/1048576"|bc)
    echo ""
    echo -e "\033[32;1m ----------已下载${key}次，总流量${mb}MB，流量阈值${bw}MB---------- \033[0m"
    echo ""
done
echo -e "\033[32;1m ----------剑皇结束---------- \033[0m"
