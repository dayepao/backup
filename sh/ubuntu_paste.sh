#/bin/bash
if [[ -z "$(command -v curl)" ]];then
    echo "没有curl, 请安装"
exit 1
fi
content=$*
if [[ "$content" ]];then
    share_link="https://paste.ubuntu.com"$(curl -v --data-urlencode "content=${content}" -d "poster=dayepao" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | grep "Location" | awk '{print $3}')
    echo $share_link
else
    echo "没有传入要上传的文本"
    echo -e "一般是这样: \e[31mbash $0 \e[32m你要上传的文本\e[0m"
fi
