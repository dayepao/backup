#!/bin/bash
read -p "请输入onedrive路径（从VPS/开始）: " path
echo "开始进入限速模式"
/usr/sbin/wondershaper eth0 7000 30000
while read filename
do
OneDriveUploader -s "$filename" -r "$path"
done < list.txt
/usr/sbin/wondershaper clear eth0
echo "已退出限速模式"
