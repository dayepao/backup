#!/bin/sh

# 替换成你的用户名
userId="123456"

# 替换成你的密码
password="123456"

# 这里判断是否已经属于登录状态 如果是则退出脚本
captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
if [ "${captiveReturnCode}" = "204" ]; then
    echo 'You are already online!'
    exit 0
fi

# your_ip_address 替换成自己锐捷认证的ip，例如：192.0.1.128
loginURL='http://192.168.2.135/eportal/InterFace.do?method=login'

case $1 in
    xyw)
        # service是运营商中文经过两次UrlEncode编码的结果,
        # 提供编码网址为https://tool.chinaz.com/tools/urlencode.aspx
        service='internet'
        ;;
    dx)
        # service是运营商中文经过两次UrlEncode编码的结果,
        # 提供编码网址为https://tool.chinaz.com/tools/urlencode.aspx
        # 例如：电信出口 这四个中文字符经过两次UrlEncode得到如下结果，如果你使用其他运营商请自行修改
        service='%E7%94%B5%E4%BF%A1%E5%87%BA%E5%8F%A3'
        ;;
    *)
        echo -e "参数错误"
        exit 0
        ;;
esac
# 此处参数已混淆，你需要使用chrome浏览器F12打开控制台
# 复制你成功登录的queryString进行替换即可
# 要是登录太快来不及复制就Network把网络请求速度调至最低的1kb/s
queryString='wlanuca6d68893ff5fc'
queryString="${queryString//&/%2526}"
queryString="${queryString//=/%253D}"

# 这里无需进行替换
# 看到返回的JSON中包含success代表认证成功
auth=`curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36" -e "${loginURL}" -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" -d "userId=${userId}&password=${password}&service=${service}&queryString=${queryString}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" "${loginURL}"`
echo $auth
