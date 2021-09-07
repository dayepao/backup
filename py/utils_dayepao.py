import os
import sys
import time

import __main__
import httpx


def get_method(url, headers=None, timeout=5, max_retries=5):
    """
    max_retries: 最大尝试次数，默认为 5 次，为 0 时禁用
    """
    k = 1
    while (k <= max_retries) or (max_retries == 0):
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
    """
    max_retries: 最大尝试次数，默认为 5 次，为 0 时禁用
    """
    k = 1
    while (k <= max_retries) or (max_retries == 0):
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
    """
    `make_dir(file_path[:file_path.rfind('\\')])`

    file_path: 文件完整路径 (包括文件名)
    """
    if not os.path.exists(path):
        os.makedirs(path)


def get_self_dir():
    """
    返回 (py_path, py_dir)

    py_path: 当前.py文件完整路径 (包括文件名)
    py_dir: 当前.py文件所在文件夹路径
    """
    py_path = __main__.__file__
    py_dir = py_path[:py_path.rfind('\\')]
    return py_path, py_dir


if __name__ == "__main__":
    print(get_self_dir())
