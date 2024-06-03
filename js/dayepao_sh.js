async function handleRequest(request) {
    // Cloudflare Workers 分配的域名
    cf_worker_host = "sh.dayepao.workers.dev"
    // 自定义的域名
    origin_host = "sh.dayepao.com"
    // GitHub 仓库文件地址
    github_host = "raw.githubusercontent.com/dayepao/backup/main/sh"
    // 单独处理sh.dayepao.com的请求
    const request_url = new URL(request.url)
    if (request_url.pathname == "/") {
        url = "https://raw.githubusercontent.com/dayepao/backup/main/sh/Toolbox.sh"
        return fetch(url)
    }
    // 替换 2 次以同时兼容 Worker 来源和域名来源
    url = request.url.replace(cf_worker_host, github_host).replace(origin_host, github_host)
    return fetch(url)
}

addEventListener("fetch", event => {
    return event.respondWith(handleRequest(event.request))
})