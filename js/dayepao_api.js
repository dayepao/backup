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
    if (pathname == '/img') {
        return api_img(request, params)
    }
    if (pathname == '/ip') {
        return api_ip(request)
    }
    return new Response('大液泡的API')
}

addEventListener("fetch", event => {
    return event.respondWith(select_api(event.request))
})