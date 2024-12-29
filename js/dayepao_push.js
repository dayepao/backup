var contents = []
var debugkey = 0

async function gatherResponse(response) {
    const { headers } = response
    const contentType = headers.get("content-type") || ""
    if (contentType.includes("application/json")) {
      return JSON.stringify(await response.json())
    }
    else if (contentType.includes("application/text")) {
      return await response.text()
    }
    else if (contentType.includes("text/html")) {
      return await response.text()
    }
    else {
      return await response.text()
    }
}

async function refresh_access_token(pushstrs, num) {
    const corpid = await DAYEPAOPUSH.get('corpid')
    const corpsecret = await DAYEPAOPUSH.get('corpsecret')
    const refresh_url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=" + corpid + "&corpsecret=" + corpsecret
    const response = await fetch(refresh_url)
    if (response.ok) {
        const data = await response.json()
        await DAYEPAOPUSH.put('access_token', data.access_token)
    }
    return dayepao_push(pushstrs, num)
}

async function dayepao_push(pushstrs, num) {
    if (num < 4) {
        const access_token = await DAYEPAOPUSH.get('access_token')
        var pushurl = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=" + access_token
        if (debugkey == 1) {
            pushurl = pushurl + "&debug=1"
        }
        var results = []
        for(var pushstr of pushstrs){
            const pushdata = {
            method:"POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: pushstr,
            }
            const response = await fetch(pushurl, pushdata)
            const result = await gatherResponse(response)
            if (result.indexOf("access_token") != -1) {
                return refresh_access_token(pushstrs, num+1)
            } else {
                results.push(result)
            }
        }
        return new Response(results)
    } else {
        return new Response("因access_token无效推送失败超过3次，请检查原因")
    }
}

async function reBytesStrArr(str, len) {
    if (!str || str == undefined) {
        return;
    }
    let num = 0;
    let result = '';
    for (let i = 0; i < str.length; i++) {
        num += ((str.charCodeAt(i) > 255) ? 4 : 1);
        if (num > len) {
            break;
        } else {
            result = str.substring(0, i + 1);
        }
    }
    contents.push(result)
    let nextStr = str.replace(result, '')
    reBytesStrArr(nextStr, len)
}

async function separate_from_xxB(request, xxB) {
    var pushstrs =[]
    var pushstr = await request.clone().text()
    var pushjson = JSON.parse(pushstr)
    if (pushjson.msgtype == "text_old") {
        var text = pushjson.text
        var content = JSON.stringify(text.content)
        content = content.slice(1);  // 从索引1开始，截取到字符串末尾
        content = content.slice(0, -1);  // 截取从头开始到倒数第二个字符
        if (!content){
            return new Response("要推送的消息为空消息")
        }
        reBytesStrArr(content, xxB)
        for(var contentpart of contents){
            text.content = contentpart
            pushjson.text = text
            pushstr = JSON.stringify(pushjson)
            pushstr = pushstr.replace(/\\\\/g, "\\")
                                .replace(/\\\\n/g, "\\n")
                                .replace(/\\\\'/g, "\\'")
                                .replace(/\\\\"/g, '\\"')
                                .replace(/\\\\&/g, "\\&")
                                .replace(/\\\\r/g, "\\r")
                                .replace(/\\\\t/g, "\\t")
                                .replace(/\\\\b/g, "\\b")
                                .replace(/\\\\f/g, "\\f")
            pushstrs.push(pushstr)
        }
    } else {
        pushstrs.push(pushstr)
    }
    return dayepao_push(pushstrs, 1)
}

async function verifykey(request) {
    const pushkey = await DAYEPAOPUSH.get('pushkey')
    const url = new URL(request.url)
    const rpushkey = url.searchParams.get('pushkey')
    const rdebugkey = url.searchParams.get('debug')
    if (rdebugkey == 1) {
        debugkey = 1
    }
    if (rpushkey == pushkey) {
        return separate_from_xxB(request, 2048)
    } else {
        return new Response('pushkey错误')
    }
}

addEventListener("fetch", event => {
    return event.respondWith(verifykey(event.request))
})