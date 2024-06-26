import base64
import hashlib
import hmac
import json
import os
import re
import smtplib
import sys
import threading
import time
import urllib.parse
from email.header import Header
from email.mime.text import MIMEText
from email.utils import formataddr

import httpx

# 主线程的锁
mutex = threading.Lock()


# 定义新的 print 函数
def _print(text, *args, **kw):
    """
    使输出有序进行，不出现多线程同一时间输出导致错乱的问题。
    """
    with mutex:
        print(text, *args, **kw)


# 定义 http 请求方法
def http_request(method_name: str, url: str, timeout=5, max_retries=5, c: httpx.Client = None, **kwargs) -> httpx.Response:
    """
    method: 请求方法，如 'get', 'post', 'put', 'delete'等
    url: 请求的URL
    timeout: 超时时间, 单位秒(s), 默认为 5 秒, 为 `None` 时禁用
    max_retries: 最大尝试次数, 默认为 5 次, 为 0 时禁用
    c: httpx.Client 对象
    **kwargs: 其他传递给 httpx 请求方法的参数, 如 headers, data, json, verify 等
    """
    method_name = method_name.lower()  # 先转换为小写

    if not method_name:
        raise ValueError("请求方法不能为空")

    try:
        if c is not None:
            request_method = getattr(c, method_name)
        else:
            request_method = getattr(httpx, method_name)
    except AttributeError:
        raise ValueError(f"不支持的请求方法: '{method_name}'")

    k = 1
    while (k <= max_retries) or (max_retries == 0):
        try:
            res = request_method(url=url, timeout=timeout, **kwargs)
        except Exception as e:
            k = k + 1
            _print(f"{sys._getframe().f_code.co_name} 出错: {str(e)}")
            time.sleep(1)
            continue
        else:
            break
    try:
        return res
    except Exception:
        sys.exit(f"{sys._getframe().f_code.co_name} 出错: 已达到最大重试次数")


# 检查是否可以访问互联网
def check_network():
    """
    检查是否可以访问互联网。
    """
    response = http_request("get", "http://cp.cloudflare.com/", timeout=10, follow_redirects=True)
    return bool(response.status_code == 204)


# 通知服务
# fmt: off
push_config = {
    'HITOKOTO': False,                  # 启用一言（随机句子）

    'BARK_PUSH': '',                    # bark IP 或设备码，例：https://api.day.app/DxHcxxxxxRxxxxxxcm/
    'BARK_ARCHIVE': '',                 # bark 推送是否存档
    'BARK_GROUP': '',                   # bark 推送分组
    'BARK_SOUND': '',                   # bark 推送声音
    'BARK_ICON': '',                    # bark 推送图标

    'CONSOLE': True,                    # 控制台输出

    'DD_BOT_SECRET': '',                # 钉钉机器人的 DD_BOT_SECRET
    'DD_BOT_TOKEN': '',                 # 钉钉机器人的 DD_BOT_TOKEN

    'FSKEY': '',                        # 飞书机器人的 FSKEY

    'GOBOT_URL': '',                    # go-cqhttp
                                        # 推送到个人QQ：http://127.0.0.1/send_private_msg
                                        # 群：http://127.0.0.1/send_group_msg
    'GOBOT_QQ': '',                     # go-cqhttp 的推送群或用户
                                        # GOBOT_URL 设置 /send_private_msg 时填入 user_id=个人QQ
                                        #               /send_group_msg   时填入 group_id=QQ群
    'GOBOT_TOKEN': '',                  # go-cqhttp 的 access_token

    'GOTIFY_URL': '',                   # gotify地址,如https://push.example.de:8080
    'GOTIFY_TOKEN': '',                 # gotify的消息应用token
    'GOTIFY_PRIORITY': 0,               # 推送消息优先级,默认为0

    'IGOT_PUSH_KEY': '',                # iGot 聚合推送的 IGOT_PUSH_KEY

    'SERVERJ_PUSH_KEY': '',             # server 酱的 PUSH_KEY，兼容旧版与 Turbo 版

    'DEER_KEY': '',                     # PushDeer 的 PUSHDEER_KEY
    'DEER_URL': '',                     # PushDeer 的 PUSHDEER_URL

    'SYNOLOGY_CHAT_URL': '',            # synology chat url
    'SYNOLOGY_CHAT_TOKEN': '',          # synology chat token

    'PUSH_PLUS_TOKEN': '',              # push+ 微信推送的用户令牌
    'PUSH_PLUS_USER': '',               # push+ 微信推送的群组编码

    'QMSG_KEY': '',                     # qmsg 酱的 QMSG_KEY
    'QMSG_TYPE': '',                    # qmsg 酱的 QMSG_TYPE

    'QYWX_ORIGIN': '',                  # 企业微信代理地址

    'QYWX_AM': '',                      # 企业微信应用 corpid,corpsecret,touser(注:多个成员ID使用|隔开),agentid,消息类型(选填,不填默认文本消息类型) 注意用,号隔开(英文输入法的逗号)，例如：wwcfrs,B-76WERQ,qinglong,1000001,2COat

    'QYWX_KEY': '',                     # 企业微信机器人

    'TG_BOT_TOKEN': '',                 # tg 机器人的 TG_BOT_TOKEN，例：1407203283:AAG9rt-6RDaaX0HBLZQq0laNOh898iFYaRQ
    'TG_USER_ID': '',                   # tg 机器人的 TG_USER_ID，例：1434078534
    'TG_API_HOST': '',                  # tg 代理 api
    'TG_PROXY_AUTH': '',                # tg 代理认证参数
    'TG_PROXY_HOST': '',                # tg 机器人的 TG_PROXY_HOST
    'TG_PROXY_PORT': '',                # tg 机器人的 TG_PROXY_PORT

    'AIBOTK_KEY': '',                   # 智能微秘书 个人中心的apikey 文档地址：http://wechat.aibotk.com/docs/about
    'AIBOTK_TYPE': '',                  # 智能微秘书 发送目标 room 或 contact
    'AIBOTK_NAME': '',                  # 智能微秘书  发送群名 或者好友昵称和type要对应好

    'SMTP_SERVER': '',                  # SMTP 发送邮件服务器，形如 smtp.exmail.qq.com:465
    'SMTP_SSL': 'false',                # SMTP 发送邮件服务器是否使用 SSL，填写 true 或 false
    'SMTP_EMAIL': '',                   # SMTP 收发件邮箱，通知将会由自己发给自己
    'SMTP_PASSWORD': '',                # SMTP 登录密码，也可能为特殊口令，视具体邮件服务商说明而定
    'SMTP_NAME': '',                    # SMTP 收发件人姓名，可随意填写

    'PUSHME_KEY': '',                   # PushMe 酱的 PUSHME_KEY
}
# fmt: on

# 首先读取 面板变量 或者 github action 运行变量
for k in push_config:
    if os.getenv(k):
        v = os.getenv(k)
        push_config[k] = v


def bark(title: str, content: str) -> None:
    """
    使用 bark 推送消息。
    """
    if not push_config.get("BARK_PUSH"):
        _print("bark 服务的 BARK_PUSH 未设置!!\n取消推送")
        return
    _print("bark 服务启动")

    if push_config.get("BARK_PUSH").startswith("http"):
        url = f'{push_config.get("BARK_PUSH")}/{urllib.parse.quote_plus(title)}/{urllib.parse.quote_plus(content)}'
    else:
        url = f'https://api.day.app/{push_config.get("BARK_PUSH")}/{urllib.parse.quote_plus(title)}/{urllib.parse.quote_plus(content)}'

    bark_params = {
        "BARK_ARCHIVE": "isArchive",
        "BARK_GROUP": "group",
        "BARK_SOUND": "sound",
        "BARK_ICON": "icon",
    }
    params = ""
    for pair in filter(
        lambda pairs: pairs[0].startswith("BARK_") and pairs[0] != "BARK_PUSH" and pairs[1] and bark_params.get(pairs[0]),
        push_config.items(),
    ):
        params += f"{bark_params.get(pair[0])}={pair[1]}&"
    if params:
        url = url + "?" + params.rstrip("&")
    response = http_request("get", url).json()

    if response["code"] == 200:
        _print("bark 推送成功！")
    else:
        _print("bark 推送失败！")


def console(title: str, content: str) -> None:
    """
    使用 控制台 推送消息。
    """
    _print(f"{title}\n\n{content}")


def dingding_bot(title: str, content: str) -> None:
    """
    使用 钉钉机器人 推送消息。
    """
    if not push_config.get("DD_BOT_SECRET") or not push_config.get("DD_BOT_TOKEN"):
        _print("钉钉机器人 服务的 DD_BOT_SECRET 或者 DD_BOT_TOKEN 未设置!!\n取消推送")
        return
    _print("钉钉机器人 服务启动")

    timestamp = str(round(time.time() * 1000))
    secret_enc = push_config.get("DD_BOT_SECRET").encode("utf-8")
    string_to_sign = "{}\n{}".format(timestamp, push_config.get("DD_BOT_SECRET"))
    string_to_sign_enc = string_to_sign.encode("utf-8")
    hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
    sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
    url = f'https://oapi.dingtalk.com/robot/send?access_token={push_config.get("DD_BOT_TOKEN")}&timestamp={timestamp}&sign={sign}'
    headers = {"Content-Type": "application/json;charset=utf-8"}
    data = {"msgtype": "text", "text": {"content": f"{title}\n\n{content}"}}
    response = http_request("post", url=url, data=json.dumps(data), headers=headers, timeout=15).json()

    if not response["errcode"]:
        _print("钉钉机器人 推送成功！")
    else:
        _print("钉钉机器人 推送失败！")


def feishu_bot(title: str, content: str) -> None:
    """
    使用 飞书机器人 推送消息。
    """
    if not push_config.get("FSKEY"):
        _print("飞书 服务的 FSKEY 未设置!!\n取消推送")
        return
    _print("飞书 服务启动")

    url = f'https://open.feishu.cn/open-apis/bot/v2/hook/{push_config.get("FSKEY")}'
    data = {"msg_type": "text", "content": {"text": f"{title}\n\n{content}"}}
    response = http_request("post", url=url, data=json.dumps(data)).json()

    if response.get("StatusCode") == 0:
        _print("飞书 推送成功！")
    else:
        _print("飞书 推送失败！错误信息如下：\n", response)


def go_cqhttp(title: str, content: str) -> None:
    """
    使用 go_cqhttp 推送消息。
    """
    if not push_config.get("GOBOT_URL") or not push_config.get("GOBOT_QQ"):
        _print("go-cqhttp 服务的 GOBOT_URL 或 GOBOT_QQ 未设置!!\n取消推送")
        return
    _print("go-cqhttp 服务启动")

    url = f'{push_config.get("GOBOT_URL")}?access_token={push_config.get("GOBOT_TOKEN")}&{push_config.get("GOBOT_QQ")}&message=标题:{title}\n内容:{content}'
    response = http_request("get", url).json()

    if response["status"] == "ok":
        _print("go-cqhttp 推送成功！")
    else:
        _print("go-cqhttp 推送失败！")


def gotify(title: str, content: str) -> None:
    """
    使用 gotify 推送消息。
    """
    if not push_config.get("GOTIFY_URL") or not push_config.get("GOTIFY_TOKEN"):
        _print("gotify 服务的 GOTIFY_URL 或 GOTIFY_TOKEN 未设置!!\n取消推送")
        return
    _print("gotify 服务启动")

    url = f'{push_config.get("GOTIFY_URL")}/message?token={push_config.get("GOTIFY_TOKEN")}'
    data = {
        "title": title,
        "message": content,
        "priority": push_config.get("GOTIFY_PRIORITY"),
    }
    response = http_request("post", url=url, data=data).json()

    if response.get("id"):
        _print("gotify 推送成功！")
    else:
        _print("gotify 推送失败！")


def iGot(title: str, content: str) -> None:
    """
    使用 iGot 推送消息。
    """
    if not push_config.get("IGOT_PUSH_KEY"):
        _print("iGot 服务的 IGOT_PUSH_KEY 未设置!!\n取消推送")
        return
    _print("iGot 服务启动")

    url = f'https://push.hellyw.com/{push_config.get("IGOT_PUSH_KEY")}'
    data = {"title": title, "content": content}
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = http_request("post", url=url, data=data, headers=headers).json()

    if response["ret"] == 0:
        _print("iGot 推送成功！")
    else:
        _print(f'iGot 推送失败！{response["errMsg"]}')


def serverJ(title: str, content: str) -> None:
    """
    通过 server酱 推送消息。
    """
    if not push_config.get("SERVERJ_PUSH_KEY"):
        _print("server酱 服务的 PUSH_KEY 未设置!!\n取消推送")
        return
    _print("server酱 服务启动")

    data = {"text": title, "desp": content.replace("\n", "\n\n")}
    if push_config.get("SERVERJ_PUSH_KEY").find("SCT") != -1:
        url = f'https://sctapi.ftqq.com/{push_config.get("SERVERJ_PUSH_KEY")}.send'
    else:
        url = f'https://sc.ftqq.com/{push_config.get("SERVERJ_PUSH_KEY")}.send'
    response = http_request("post", url=url, data=data).json()

    if response.get("errno") == 0 or response.get("code") == 0:
        _print("server酱 推送成功！")
    else:
        _print(f'server酱 推送失败！错误码：{response["message"]}')


def pushdeer(title: str, content: str) -> None:
    """
    通过 PushDeer 推送消息
    """
    if not push_config.get("DEER_KEY"):
        _print("PushDeer 服务的 DEER_KEY 未设置!!\n取消推送")
        return
    _print("PushDeer 服务启动")
    data = {
        "text": title,
        "desp": content,
        "type": "markdown",
        "pushkey": push_config.get("DEER_KEY"),
    }
    url = "https://api2.pushdeer.com/message/push"
    if push_config.get("DEER_URL"):
        url = push_config.get("DEER_URL")

    response = http_request("post", url=url, data=data).json()

    if len(response.get("content").get("result")) > 0:
        _print("PushDeer 推送成功！")
    else:
        _print("PushDeer 推送失败！错误信息：", response)


def synology_chat(title: str, content: str) -> None:
    """
    通过 Synology Chat 推送消息
    """
    if not push_config.get("SYNOLOGY_CHAT_URL") or not push_config.get("SYNOLOGY_CHAT_TOKEN"):
        _print("Synology Chat 服务的 SYNOLOGY_CHAT_URL 或 SYNOLOGY_CHAT_TOKEN 未设置!!\n取消推送")
        return
    _print("Synology Chat 服务启动")
    data = "payload=" + json.dumps({"text": title + "\n" + content})
    url = push_config.get("SYNOLOGY_CHAT_URL") + push_config.get("SYNOLOGY_CHAT_TOKEN")
    response = http_request("post", url=url, data=data)

    if response.status_code == 200:
        _print("Synology Chat 推送成功！")
    else:
        _print("Synology Chat 推送失败！错误信息：", response)


def pushplus_bot(title: str, content: str) -> None:
    """
    通过 push+ 推送消息。
    """
    if not push_config.get("PUSH_PLUS_TOKEN"):
        _print("PUSHPLUS 服务的 PUSH_PLUS_TOKEN 未设置!!\n取消推送")
        return
    _print("PUSHPLUS 服务启动")

    url = "http://www.pushplus.plus/send"
    data = {
        "token": push_config.get("PUSH_PLUS_TOKEN"),
        "title": title,
        "content": content,
        "topic": push_config.get("PUSH_PLUS_USER"),
    }
    body = json.dumps(data).encode(encoding="utf-8")
    headers = {"Content-Type": "application/json"}
    response = http_request("post", url=url, data=body, headers=headers).json()

    if response["code"] == 200:
        _print("PUSHPLUS 推送成功！")

    else:
        url_old = "http://pushplus.hxtrip.com/send"
        headers["Accept"] = "application/json"
        response = http_request("post", url=url_old, data=body, headers=headers).json()

        if response["code"] == 200:
            _print("PUSHPLUS(hxtrip) 推送成功！")

        else:
            _print("PUSHPLUS 推送失败！")


def qmsg_bot(title: str, content: str) -> None:
    """
    使用 qmsg 推送消息。
    """
    if not push_config.get("QMSG_KEY") or not push_config.get("QMSG_TYPE"):
        _print("qmsg 的 QMSG_KEY 或者 QMSG_TYPE 未设置!!\n取消推送")
        return
    _print("qmsg 服务启动")

    url = f'https://qmsg.zendee.cn/{push_config.get("QMSG_TYPE")}/{push_config.get("QMSG_KEY")}'
    payload = {"msg": f'{title}\n\n{content.replace("----", "-")}'.encode("utf-8")}
    response = http_request("post", url=url, params=payload).json()

    if response["code"] == 0:
        _print("qmsg 推送成功！")
    else:
        _print(f'qmsg 推送失败！{response["reason"]}')


def wecom_app(title: str, content: str) -> None:
    """
    通过 企业微信APP 推送消息。
    """
    if not push_config.get("QYWX_AM"):
        _print("QYWX_AM 未设置!!\n取消推送")
        return
    QYWX_AM_AY = re.split(",", push_config.get("QYWX_AM"))
    if 4 < len(QYWX_AM_AY) > 5:
        _print("QYWX_AM 设置错误!!\n取消推送")
        return
    _print("企业微信 APP 服务启动")

    corpid = QYWX_AM_AY[0]
    corpsecret = QYWX_AM_AY[1]
    touser = QYWX_AM_AY[2]
    agentid = QYWX_AM_AY[3]
    try:
        media_id = QYWX_AM_AY[4]
    except IndexError:
        media_id = ""
    wx = WeCom(corpid, corpsecret, agentid)
    # 如果没有配置 media_id 默认就以 text 方式发送
    if not media_id:
        message = title + "\n\n" + content
        response = wx.send_text(message, touser)
    else:
        response = wx.send_mpnews(title, content, media_id, touser)

    if response == "ok":
        _print("企业微信推送成功！")
    else:
        _print("企业微信推送失败！错误信息如下：\n", response)


class WeCom:
    def __init__(self, corpid, corpsecret, agentid):
        self.CORPID = corpid
        self.CORPSECRET = corpsecret
        self.AGENTID = agentid
        self.ORIGIN = "https://qyapi.weixin.qq.com"
        if push_config.get("QYWX_ORIGIN"):
            self.ORIGIN = push_config.get("QYWX_ORIGIN")

    def get_access_token(self):
        url = f"{self.ORIGIN}/cgi-bin/gettoken"
        values = {
            "corpid": self.CORPID,
            "corpsecret": self.CORPSECRET,
        }
        req = http_request("post", url=url, params=values)
        data = json.loads(req.text)
        return data["access_token"]

    def send_text(self, message, touser="@all"):
        send_url = f"{self.ORIGIN}/cgi-bin/message/send?access_token={self.get_access_token()}"
        send_values = {
            "touser": touser,
            "msgtype": "text",
            "agentid": self.AGENTID,
            "text": {"content": message},
            "safe": "0",
        }
        send_msges = bytes(json.dumps(send_values), "utf-8")
        respone = http_request("post", url=send_url, data=send_msges)
        respone = respone.json()
        return respone["errmsg"]

    def send_mpnews(self, title, message, media_id, touser="@all"):
        send_url = f"https://{self.ORIGIN}/cgi-bin/message/send?access_token={self.get_access_token()}"
        send_values = {
            "touser": touser,
            "msgtype": "mpnews",
            "agentid": self.AGENTID,
            "mpnews": {
                "articles": [
                    {
                        "title": title,
                        "thumb_media_id": media_id,
                        "author": "Author",
                        "content_source_url": "",
                        "content": message.replace("\n", "<br/>"),
                        "digest": message,
                    }
                ]
            },
        }
        send_msges = bytes(json.dumps(send_values), "utf-8")
        respone = http_request("post", url=send_url, data=send_msges)
        respone = respone.json()
        return respone["errmsg"]


def wecom_bot(title: str, content: str) -> None:
    """
    通过 企业微信机器人 推送消息。
    """
    if not push_config.get("QYWX_KEY"):
        _print("企业微信机器人 服务的 QYWX_KEY 未设置!!\n取消推送")
        return
    _print("企业微信机器人服务启动")

    origin = "https://qyapi.weixin.qq.com"
    if push_config.get("QYWX_ORIGIN"):
        origin = push_config.get("QYWX_ORIGIN")

    url = f"{origin}/cgi-bin/webhook/send?key={push_config.get('QYWX_KEY')}"
    headers = {"Content-Type": "application/json;charset=utf-8"}
    data = {"msgtype": "text", "text": {"content": f"{title}\n\n{content}"}}
    response = http_request("post", url=url, data=json.dumps(data), headers=headers, timeout=15).json()

    if response["errcode"] == 0:
        _print("企业微信机器人推送成功！")
    else:
        _print("企业微信机器人推送失败！")


def telegram_bot(title: str, content: str) -> None:
    """
    使用 telegram机器人 推送消息。
    """
    if not push_config.get("TG_BOT_TOKEN") or not push_config.get("TG_USER_ID"):
        _print("tg 服务的 bot_token 或者 user_id 未设置!!\n取消推送")
        return
    _print("tg 服务启动")

    if push_config.get("TG_API_HOST"):
        url = f"https://{push_config.get('TG_API_HOST')}/bot{push_config.get('TG_BOT_TOKEN')}/sendMessage"
    else:
        url = f"https://api.telegram.org/bot{push_config.get('TG_BOT_TOKEN')}/sendMessage"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    payload = {
        "chat_id": str(push_config.get("TG_USER_ID")),
        "text": f"{title}\n\n{content}",
        "disable_web_page_preview": "true",
    }
    proxies = None
    if push_config.get("TG_PROXY_HOST") and push_config.get("TG_PROXY_PORT"):
        if push_config.get("TG_PROXY_AUTH") is not None and "@" not in push_config.get("TG_PROXY_HOST"):
            push_config["TG_PROXY_HOST"] = push_config.get("TG_PROXY_AUTH") + "@" + push_config.get("TG_PROXY_HOST")
        proxyStr = "http://{}:{}".format(push_config.get("TG_PROXY_HOST"), push_config.get("TG_PROXY_PORT"))
        proxies = {"http": proxyStr, "https": proxyStr}
    response = http_request("post", url=url, headers=headers, params=payload, proxies=proxies).json()

    if response["ok"]:
        _print("tg 推送成功！")
    else:
        _print("tg 推送失败！")


def aibotk(title: str, content: str) -> None:
    """
    使用 智能微秘书 推送消息。
    """
    if not push_config.get("AIBOTK_KEY") or not push_config.get("AIBOTK_TYPE") or not push_config.get("AIBOTK_NAME"):
        _print("智能微秘书 的 AIBOTK_KEY 或者 AIBOTK_TYPE 或者 AIBOTK_NAME 未设置!!\n取消推送")
        return
    _print("智能微秘书 服务启动")

    if push_config.get("AIBOTK_TYPE") == "room":
        url = "https://api-bot.aibotk.com/openapi/v1/chat/room"
        data = {
            "apiKey": push_config.get("AIBOTK_KEY"),
            "roomName": push_config.get("AIBOTK_NAME"),
            "message": {"type": 1, "content": f"【青龙快讯】\n\n{title}\n{content}"},
        }
    else:
        url = "https://api-bot.aibotk.com/openapi/v1/chat/contact"
        data = {
            "apiKey": push_config.get("AIBOTK_KEY"),
            "name": push_config.get("AIBOTK_NAME"),
            "message": {"type": 1, "content": f"【青龙快讯】\n\n{title}\n{content}"},
        }
    body = json.dumps(data).encode(encoding="utf-8")
    headers = {"Content-Type": "application/json"}
    response = http_request("post", url=url, data=body, headers=headers).json()
    _print(response)
    if response["code"] == 0:
        _print("智能微秘书 推送成功！")
    else:
        _print(f'智能微秘书 推送失败！{response["error"]}')


def smtp(title: str, content: str) -> None:
    """
    使用 SMTP邮件 推送消息。
    """
    if not push_config.get("SMTP_SERVER") or not push_config.get("SMTP_SSL") or not push_config.get("SMTP_EMAIL") or not push_config.get("SMTP_PASSWORD") or not push_config.get("SMTP_NAME"):
        _print("SMTP 邮件 的 SMTP_SERVER 或者 SMTP_SSL 或者 SMTP_EMAIL 或者 SMTP_PASSWORD 或者 SMTP_NAME 未设置!!\n取消推送")
        return
    _print("SMTP 邮件 服务启动")

    message = MIMEText(content, "plain", "utf-8")
    message["From"] = formataddr(
        (
            Header(push_config.get("SMTP_NAME"), "utf-8").encode(),
            push_config.get("SMTP_EMAIL"),
        )
    )
    message["To"] = formataddr(
        (
            Header(push_config.get("SMTP_NAME"), "utf-8").encode(),
            push_config.get("SMTP_EMAIL"),
        )
    )
    message["Subject"] = Header(title, "utf-8")

    try:
        smtp_server = smtplib.SMTP_SSL(push_config.get("SMTP_SERVER")) if push_config.get("SMTP_SSL") == "true" else smtplib.SMTP(push_config.get("SMTP_SERVER"))
        smtp_server.login(push_config.get("SMTP_EMAIL"), push_config.get("SMTP_PASSWORD"))
        smtp_server.sendmail(
            push_config.get("SMTP_EMAIL"),
            push_config.get("SMTP_EMAIL"),
            message.as_bytes(),
        )
        smtp_server.close()
        _print("SMTP 邮件 推送成功！")
    except Exception as e:
        _print(f"SMTP 邮件 推送失败！{e}")


def pushme(title: str, content: str) -> None:
    """
    使用 PushMe 推送消息。
    """
    if not push_config.get("PUSHME_KEY"):
        _print("PushMe 服务的 PUSHME_KEY 未设置!!\n取消推送")
        return
    _print("PushMe 服务启动")

    url = f'https://push.i-i.me/?push_key={push_config.get("PUSHME_KEY")}'
    data = {
        "title": title,
        "content": content,
    }
    response = http_request("post", url=url, data=data)

    if response.status_code == 200 and response.text == "success":
        _print("PushMe 推送成功！")
    else:
        _print(f"PushMe 推送失败！{response.status_code} {response.text}")


def one() -> str:
    """
    获取一条一言。
    :return:
    """
    url = "https://v1.hitokoto.cn/"
    res = http_request("get", url=url).json()
    return res["hitokoto"] + "    ----" + res["from"]


def send_message(title: str, content: str, channels: list = None, is_channels_visible: bool = False) -> None:
    """
    title: 消息标题

    content: 消息内容

    channels: 推送渠道，默认全部推送，可选项：
    - bark
    - console
    - dingding_bot
    - feishu_bot
    - go_cqhttp
    - gotify
    - iGot
    - serverJ
    - pushdeer
    - synology_chat
    - pushplus_bot
    - qmsg_bot
    - wecom_app
    - wecom_bot
    - telegram_bot
    - aibotk
    - smtp
    - pushme

    is_channels_visible: 是否在控制台显示 channels 信息，默认不显示
    """

    # 确保 title 和 content 是字符串
    title = str(title)
    content = str(content)

    # 确保 channel_list 是一个列表
    if not channels:
        channels = []
    channels = [channels] if not isinstance(channels, list) else channels

    if not content:
        _print(f"{title} 推送内容为空！")
        return

    # 确保可以访问互联网
    if not check_network():
        _print("无法访问互联网！")
        return

    # 根据标题跳过一些消息推送，环境变量：SKIP_PUSH_TITLE 用回车分隔
    skipTitle = os.getenv("SKIP_PUSH_TITLE")
    if skipTitle:
        if title in re.split("\n", skipTitle):
            _print(f"{title} 在SKIP_PUSH_TITLE环境变量内，跳过推送！")
            return

    notify_function = []
    functions_map = {
        "BARK_PUSH": bark,
        "CONSOLE": console,
        ("DD_BOT_TOKEN", "DD_BOT_SECRET"): dingding_bot,
        "FSKEY": feishu_bot,
        ("GOBOT_URL", "GOBOT_QQ"): go_cqhttp,
        ("GOTIFY_URL", "GOTIFY_TOKEN"): gotify,
        "IGOT_PUSH_KEY": iGot,
        "SERVERJ_PUSH_KEY": serverJ,
        "DEER_KEY": pushdeer,
        ("SYNOLOGY_CHAT_URL", "SYNOLOGY_CHAT_TOKEN"): synology_chat,
        "PUSH_PLUS_TOKEN": pushplus_bot,
        ("QMSG_KEY", "QMSG_TYPE"): qmsg_bot,
        "QYWX_AM": wecom_app,
        "QYWX_KEY": wecom_bot,
        ("TG_BOT_TOKEN", "TG_USER_ID"): telegram_bot,
        ("AIBOTK_KEY", "AIBOTK_TYPE", "AIBOTK_NAME"): aibotk,
        ("SMTP_SERVER", "SMTP_SSL", "SMTP_EMAIL", "SMTP_PASSWORD", "SMTP_NAME"): smtp,
        "PUSHME_KEY": pushme
    }

    notify_function = []
    for keys, function in functions_map.items():
        if isinstance(keys, tuple):
            if all(push_config.get(key) for key in keys) and (not channels or function.__name__ in channels):
                notify_function.append(function)
        elif push_config.get(keys) and (not channels or function.__name__ in channels):
            notify_function.append(function)
    if is_channels_visible:
        _print(f"本次推送使用到的通道：{[f.__name__ for f in notify_function]}")

    if (text := (one() if push_config.get("HITOKOTO") else "")):
        content += "\n\n" + text

    ts = [threading.Thread(target=mode, args=(title, content), name=mode.__name__) for mode in notify_function]
    [t.start() for t in ts]
    [t.join() for t in ts]


def main(title: str = "title", content: str = "content"):
    send_message(title, content, is_channels_visible=True)


if __name__ == "__main__":
    if len(sys.argv) > 2:
        main(sys.argv[1], sys.argv[2])
    else:
        main()
