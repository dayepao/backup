import requests,sys,datetime,urllib.parse,json,string,ast,re
import urllib,os
from bs4 import BeautifulSoup

def download() :
    url = "https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=2&nc=1610239683659&pid=hp&uhd=1&uhdwidth=3840&uhdheight=2160"
    res = requests.get(url)
    html = res.text
    soup = BeautifulSoup(html,'html.parser')
    jsonstr = json.loads(soup.text)
    images = str(jsonstr['images'])
    images = images[1:-2]
    images = images.split('}, ')
    key = 0
    while key < len(images) :
        image = ast.literal_eval(images[key] + "}")
        imgurl = "https://cn.bing.com" + image['url']
        filename = "img\\" + ''.join(re.findall('[,，\u4e00-\u9fa5]',image['copyright'])) + ".jpg"
        imgr = requests.get(imgurl)
        print("正在下载 " + filename)
        with open(filename,'wb') as f:
            f.write(imgr.content)
        key = key + 1

if (os.path.exists('img')) :
    download()
else :
    os.mkdir('img')
    download()