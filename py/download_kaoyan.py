import os
import random
import sys
import time

import httpx
from bs4 import BeautifulSoup


def get_method(url, headers=None, timeout=5, max_retries=5):
    k = 1
    while k <= max_retries:
        try:
            res = httpx.get(url, headers=headers, timeout=timeout)
        except Exception as e:
            k = k + 1
            print(sys._getframe().f_code.co_name + ": " + str(e))
            time.sleep(1)
            continue
        else:
            break
    try:
        return res
    except Exception:
        sys.exit(sys._getframe().f_code.co_name + ": " + "Max retries exceeded")


def post_method(url, postdata=None, postjson=None, headers=None, timeout=5, max_retries=5):
    k = 1
    while k <= max_retries:
        try:
            res = httpx.post(url, data=postdata, json=postjson, headers=headers, timeout=timeout)
        except Exception as e:
            k = k + 1
            print(sys._getframe().f_code.co_name + ": " + str(e))
            time.sleep(1)
            continue
        else:
            break
    try:
        return res
    except Exception:
        sys.exit(sys._getframe().f_code.co_name + ": " + "Max retries exceeded")


def make_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)


def download_kaoyan(url: str, download_dir: str):
    res = get_method(url)
    html = res.text
    soup = BeautifulSoup(html, 'html.parser')
    file_list = soup.find_all('a', attrs={"aria-label": "File"})
    for file in file_list:
        file_name = file['data-name']
        file_path = download_dir + "\\" + str(file_name)
        file_url = file['href'] + "&download=1"
        print("正在下载: " + file_path.replace(py_dir + "\\", ''))
        if not os.path.exists(file_path):
            make_dir(file_path[:file_path.rfind('\\')])
            file_content = get_method(file_url).content
            with open(file_path, 'wb') as f:
                f.write(file_content)
            time.sleep(random.randint(1, 5))
    folder_list = soup.find_all('a', attrs={"aria-label": "Folder"})
    for folder in folder_list:
        folder_name = folder['data-name']
        folder_url = folder['href']
        download_kaoyan(folder_url, download_dir + "\\" + folder_name)


py_path = __file__
py_dir = py_path[:py_path.rfind('\\')]

kaoyan_url = "https://pan.uvooc.com/Learn/Kaoyan?hash=867M0pkv"
download_kaoyan(kaoyan_url, py_dir)
