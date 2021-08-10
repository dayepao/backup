async function css() {
    const CSS = `
    body {
        background: #F4F5F7;
        text-align: center;
    }
    h1 {
        margin-bottom: 80px;
    }
    button {
        border-style: solid;
        border-width: 2px;
        border-radius: 5px;
        background: #FFFFFF;
        font-size: 30px;
        margin-bottom: 30px;
        width: 120px;
        height: 60px;
    }
    button:hover {
        cursor: pointer;
        background: #F4F5F7;
        opacity: 0.8;
    }
    `.replace(/^\s+/gm, "")
    return new Response(CSS, {
        headers: {
            "content-type": "text/css",
        }
    })
}
async function api() {
    const HTML = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>大液泡的API</title>
        <link rel="stylesheet" href="api.css">
    </head>

    <body>
    <h1>大液泡的API</h1>
    <div>
    <button id="button1" onclick="redirect_to_api_ip()">IP</button>
    </div>
    <div>
    <button id="button2" onclick="redirect_to_api_img()">img</button>
    </div>

    <script>
    function redirect_to_api_ip() {
        window.location.href="https://api.dayepao.com/ip"
    }
    function redirect_to_api_img() {
        window.location.href="https://api.dayepao.com/img"
    }
    </script>

    </body>
    </html>
    `.replace(/^\s+/gm, "")
    return new Response(HTML, {
        headers: {
            "content-type": "text/html;charset=UTF-8",
        }
    })
}
async function api_ip(request) {
    var cf = request.cf
    var result = {}
    result['IP'] = request.headers.get("cf-connecting-ip")
    result['HTTP协议'] = cf.httpProtocol || '未知'
    result['ASN'] = ('AS' + cf.asn) || '未知'
    result['国家'] = cf.country || '未知'
    result['区域'] = cf.region || '未知'
    result['时区'] = cf.timezone || '未知'
    result['纬度'] = cf.latitude || '未知'
    result['经度'] = cf.longitude || '未知'
    return new Response(JSON.stringify(result, null, 4))
}

async function api_img(request, params) {
    return fetch('https://img.dayepao.com/?' + params)
}

async function select_api(request) {
    const url = new URL(request.url)
    const pathname = url.pathname
    const params = url.searchParams.toString()
    if (pathname == '/api\.css') {
        return css()
    }
    if (pathname == '/img') {
        return api_img(request, params)
    }
    if (pathname == '/ip') {
        return api_ip(request)
    }
    return api()
}

addEventListener("fetch", event => {
    return event.respondWith(select_api(event.request))
})