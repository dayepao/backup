async function handleRequest(request, env) {
  const KV_NAMESPACE = "PSUB";
  // 获取请求 URL 的查询参数
  const url = new URL(request.url)
  const requestKey = url.searchParams.get('key')

  // 从 KV 命名空间中获取预定义的 AUTH_KEY
  const authKey = await env[KV_NAMESPACE].get('AUTH_KEY')

  // 检查请求中的 key 是否匹配
  if (requestKey !== authKey) {
    return new Response('Unauthorized', { status: 200 })
  }

  // 获取 KV 存储中的所有键值对，排除 AUTH_KEY
  const keys = await env[KV_NAMESPACE].list()
  const linkKeys = keys.keys.filter(key => key.name !== 'AUTH_KEY')

  // 读取所有键对应的值
  const values = await Promise.all(linkKeys.map(key => env[KV_NAMESPACE].get(key.name)))

  // 将所有值组合成一个字符串，每个链接占一行
  const combinedLinks = values.join('\n')

  // 将组合好的字符串转换为 base64 编码
  const base64EncodedLinks = btoa(combinedLinks)

  // 返回 base64 编码后的字符串
  return new Response(base64EncodedLinks, {
    headers: {
      'Content-Type': 'text/plain'
    }
  })
}

export default {
  async fetch(request, env, ctx) {
    return handleRequest(request, env);
  },
};