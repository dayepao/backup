import requests,sys,datetime,urllib.parse
import urllib,os
from bs4 import BeautifulSoup

def download() :
    key = 1
    while key < 1765 :
        url = "https://tbing.cn/detail/" + str(key)
        res = requests.get(url)
        html = res.text
        soup = BeautifulSoup(html,'html.parser')
        imgs = soup.find_all('img')
        src = imgs[0].get('src')
        imgr = requests.get(src)
        filename = "img\\" + str(key) + ".jpg"
        print("正在下载" + filename)
        with open(filename,'wb') as f:
            f.write(imgr.content)
        key = key + 1
if (os.path.exists('img')) :
    download()
else :
    os.mkdir('img')
    download()