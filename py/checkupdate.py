import requests,sys,datetime,urllib.parse
from bs4 import BeautifulSoup

repos = ["hostloc-auto-get-points","BiliBiliTool","TiebaSignIn","AutoApiS","uptime-status","OneList"] #仓库名称
pushstr = ""
now = datetime.datetime.now()
now = now.strftime("%Y-%m-%d %H:%M:%S")
for repo in repos :
    url = "https://github.com/" + sys.argv[1] + "/" + repo
    res = requests.get(url)
    html = res.text
    soup = BeautifulSoup(html,'html.parser')
    items = soup.find_all(class_='d-flex flex-auto')
    for item in items:
        if "behind" in str(item) :
            pushstr = pushstr + repo + "有更新" + "\n\n"
if pushstr:
    pushstr = now + "\n\n" + pushstr
    print(pushstr)
    if len(sys.argv) > 2:
        pushurl = "https://sctapi.ftqq.com/" + sys.argv[2] + ".send"
        pushdata = {'text':'checkupdate','desp':pushstr}
        requests.post(pushurl,pushdata)
else:
    print(now + "\n\n" + "所有仓库都是最新的")