import requests,sys,datetime,urllib.parse,imghdr
import urllib,os
from bs4 import BeautifulSoup

def download() :
    key = 1
    while key < 1800 :
        url = "https://tbing.cn/detail/" + str(key)
        res = requests.get(url)
        html = res.text
        soup = BeautifulSoup(html,'html.parser')
        imgs = soup.find_all('img')
        src = imgs[0].get('src')
        headers = {'referer' : 'https://tbing.cn/'}
        imgr = requests.get(src,headers=headers)
        filename = "bing\\" + str(key) + ".jpg"
        print("正在下载" + filename)
        with open(filename,'wb') as f:
            f.write(imgr.content)
        if (str(imghdr.what(filename)) == "None") :
            os.remove(filename)
            print("已删除" + filename)
        key = key + 1
if (os.path.exists('bing')) :
    download()
else :
    os.mkdir('bing')
    download()