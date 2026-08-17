/**
 * Cloudflare Worker：按顺序获取上游 INI 配置，完成通用行操作和代理组调整后返回。
 *
 * 一、环境变量的一般约定
 *
 * - AUTH_KEY 建议使用 Secret；ALLOW_PUBLIC、CACHE_TTL 可以使用 Text。
 * - TARGET_URLS、INI_OPERATIONS、PROXY_GROUP_CONFIG 也可以使用 Cloudflare 的 JSON
 *   类型；如果使用 Text，内容必须是合法 JSON。
 * - CACHE_TTL 也接受 JSON Number，但不接受 Boolean、数组、对象或隐式数值转换。
 * - Cloudflare 网页端会压缩多行变量，因此所有 JSON 都应写成单行。INI_OPERATIONS
 *   的 lines 数组中，每个字符串代表一个完整逻辑行，不能嵌入 \r 或 \n。
 * - 字段名称、section、key、代理组名称和匹配内容均区分大小写。
 * - TARGET_URLS 的地址以及 anchor/selector 的字符串匹配字段不能包含 \r 或 \n。
 * - 未声明的字段不会退化成宽泛匹配；对应的个性化配置或操作会被安全跳过并记录警告。
 *
 * 二、环境变量
 *
 * 1. AUTH_KEY（Secret，通常必填）
 *
 *    必须是字符串。值会先去除首尾空白，路径段会先进行 URL 解码；支持以下两种基本
 *    访问路径，两者末尾都可以再带一个 /：
 *
 *    https://域名/<AUTH_KEY>
 *    https://域名/<AUTH_KEY>.ini
 *
 *    未配置 AUTH_KEY 时，只有同时设置 ALLOW_PUBLIC=true 才允许公开访问；否则返回
 *    HTTP 500。配置了 AUTH_KEY 后，ALLOW_PUBLIC 完全不参与判断，即使其值无效也会
 *    被忽略；路径与 AUTH_KEY 不匹配时返回 HTTP 403。公开访问模式不限制请求路径。
 *
 * 2. ALLOW_PUBLIC（Text 或 Boolean，可选，默认 false）
 *
 *    控制未配置 AUTH_KEY 时是否允许公开访问。可接受的值：
 *
 *    Boolean：true、false
 *    Text true：true、1、yes、on
 *    Text false：false、0、no、off
 *
 *    字符串会去除首尾空白且不区分大小写。除非明确需要公开订阅，否则应保持 false。
 *    Number、数组和对象无效。该变量只在 AUTH_KEY 为空时读取。
 *
 * 3. TARGET_URLS（JSON 或 Text，必填）
 *
 *    非空 URL 字符串数组。Worker 按数组顺序请求；某个地址发生网络错误、返回非
 *    2xx、无法完整读取正文，或正文为空/仅含空白时尝试下一个。代码中没有隐藏的默认
 *    地址或硬编码回退，数组中的全部地址都失败时返回 HTTP 502。错误正文第一行是总体
 *    说明，之后每个目标各占一行，包含目标序号、安全化 URL 和失败原因。安全化 URL
 *    保留协议、主机、端口和路径，但移除用户名、密码及全部查询参数；网络错误和正文
 *    读取错误使用固定描述，不向客户端透传底层异常消息。重复 URL 会自动去重，URL
 *    片段（#fragment）会被移除，仅允许 HTTP 和 HTTPS。
 *
 *    单行示例：
 *    ["https://example.com/primary.ini","https://example.com/fallback.ini"]
 *
 *    成功读取上游后的响应头 X-Upstream-Index 表示实际使用的目标序号（从 1 开始），
 *    X-Upstream-Count 表示去重后的目标总数；后续严格转换失败的 HTTP 500 也会携带
 *    这两个响应头。
 *
 * 4. CACHE_TTL（Text 或 Number，可选，默认 60）
 *
 *    上游 2xx 响应的 Cloudflare 缓存秒数，必须是 0～86400 的十进制整数。Text 会先
 *    去除首尾空白，再要求只包含数字；Number 必须是安全整数。未设置、null 或空字符串
 *    视为未配置并使用默认值；显式填写的纯空白 Text、指数或十六进制写法、Boolean、
 *    数组和对象均无效。无效值不会阻断订阅，而是回退到默认 60 并记录配置警告。上游
 *    非 2xx 响应不缓存。Worker 返回给订阅客户端的最终结果使用 Cache-Control: no-store。
 *
 * 5. INI_OPERATIONS（JSON 或 Text，可选，默认 []）
 *
 *    操作对象数组，按照数组顺序依次执行。只支持 insert 和 delete，不支持固定行号，
 *    推荐使用 section、key 或稳定文本作为语义锚点。
 *
 *    5.1 insert 操作
 *
 *    {
 *      "op": "insert",
 *      "position": "before",
 *      "anchor": {"section":"custom","raw":";锚点"},
 *      "lines": [";新增注释","foo=bar"],
 *      "onMissing": "skip"
 *    }
 *
 *    字段：
 *
 *    - op：必须为 "insert"。
 *    - position：必须是以下值之一：
 *      - "before"：插入到 anchor 匹配行之前。
 *      - "after"：插入到 anchor 匹配行之后。
 *      - "document-start"：插入到文档开头，不允许提供 anchor。
 *      - "document-end"：插入到文档末尾，不允许提供 anchor。
 *    - anchor：before/after 必填的选择器，必须最终定位到一行。
 *    - lines：非空数组，每项必须是一个不含换行符的字符串；空字符串表示插入空行。
 *    - onMissing：锚点未能唯一定位时的行为，包括零匹配或多匹配；可选 "error" 或
 *      "skip"，默认 "skip"。
 *      "skip" 只跳过当前操作；显式使用 "error" 会终止转换并返回 HTTP 500。
 *
 *    5.2 delete 操作
 *
 *    {
 *      "op": "delete",
 *      "selector": {"section":"custom","key":"foo","occurrence":"all"},
 *      "onMissing": "skip"
 *    }
 *
 *    字段：
 *
 *    - op：必须为 "delete"。
 *    - selector：必填选择器。默认删除全部匹配行。
 *    - onMissing：没有匹配行时的行为，可选 "error" 或 "skip"，默认 "skip"。
 *      "skip" 只跳过当前操作；显式使用 "error" 会终止转换并返回 HTTP 500。
 *
 *    5.3 anchor/selector 支持的字段
 *
 *    一个选择器可以同时填写多个字段，所有字段之间是 AND（同时满足）关系。例如：
 *
 *    {"lineType":"section","section":"custom"}
 *
 *    只匹配 [custom] 标题行。选择器在每项操作执行时匹配当前文档，因此前一项操作
 *    插入或删除的内容会影响后一项操作的匹配结果。
 *
 *    - lineType：可选的行类型过滤器，可使用以下五种值：
 *      - "blank"：空行或只包含空白字符的行。
 *        示例：{"lineType":"blank","section":"custom","occurrence":"all"}
 *      - "comment"：忽略行首空白后，以 ; 或 # 开头的注释行。
 *        示例：{"lineType":"comment","section":"custom","occurrence":"first"}
 *      - "section"：[section-name] 格式的 section 标题行；允许行首缩进、标题名称两侧
 *        空白、右括号后的空白以及 ;/# 尾部注释。
 *        示例：{"lineType":"section","section":"custom"}，只匹配 [custom] 标题本身。
 *      - "entry"：包含 = 且等号左侧存在非空 key 的键值行。
 *        示例：{"lineType":"entry","section":"custom","occurrence":"all"}
 *      - "other"：无法归入以上类型、但仍需原样保留的其他行。
 *        示例：{"lineType":"other","rawStartsWith":"----"}
 *
 *      lineType 通常可以省略：key、value、valueStartsWith 本身只会匹配 entry；精确 raw
 *      往往也已经能确定行类型。单独使用 lineType 可能非常宽泛，例如 delete 配合
 *      {"lineType":"comment"} 会删除文档中的全部注释。保留 "section" 类型很有必要：
 *      section 字段表示一行所属的区域，而 lineType:"section" 才明确表示标题行本身。
 *
 *    - section：限定一行所属的 section，使用 section 名称精确匹配，不包含方括号。
 *      section 标题本身也属于同名 section。省略 section 表示不限制所属区域，可同时
 *      匹配根区域和所有具名 section；只有需要把匹配范围明确限定在第一个显式 section
 *      之前的根区域时，才写 section:null。空字符串或纯空白字符串无效。
 *      示例：{"section":"custom","key":"ruleset"}
 *      匹配 [custom] 中的 ruleset 条目，不匹配其他 section 中的同名 key。
 *      根区域示例：{"section":null,"raw":"foo=bar"}
 *      section 标题示例：{"lineType":"section","section":"custom"}
 *
 *    - key：精确匹配 entry 行中第一个等号左侧的键名。比较前，解析器会去掉键名
 *      两端空白；非 entry 行永远不会匹配 key。
 *      示例：{"section":"custom","key":"custom_proxy_group"}
 *      可以匹配 custom_proxy_group=...，也可以匹配 custom_proxy_group = ...。
 *
 *    - value：精确匹配 entry 行中第一个等号右侧的完整值。解析器会忽略等号后紧邻的
 *      前导空白，但值末尾空白仍参与比较；非 entry 行永远不会匹配 value。
 *      示例：{"key":"foo","value":"bar"}
 *      可以匹配 foo=bar 和 foo = bar，但不会匹配 foo=bar-baz。
 *
 *    - raw：精确匹配完整原始行。缩进、等号周围空格、末尾空格和注释标记都属于
 *      raw 的一部分，因此适合锚定格式稳定且内容唯一的整行。
 *      示例：{"raw":";本地地址和域名直连"}
 *      不会匹配前面多一个空格的 " ;本地地址和域名直连"。
 *      注意：raw 是任意行类型都能使用的原始文本字段；lineType:"other" 则表示该行无法
 *      被解析为 blank、comment、section 或 entry，两者含义不同。
 *
 *    - rawStartsWith：匹配完整原始行的非空前缀，缩进也属于原始行的一部分。适合
 *      后半段可能变化、但开头稳定的行；空字符串无效，防止意外匹配全部行。
 *      示例：{"section":"custom","rawStartsWith":"ruleset=🎯 全球直连,"}
 *      匹配 [custom] 中所有以该文本开头的原始行。
 *
 *    - valueStartsWith：匹配 entry 行等号右侧值的非空前缀。与 key、section 组合使用，
 *      通常比匹配完整代理组行更能容忍上游修改后续选项；空字符串无效。
 *      示例：
 *      {"section":"custom","key":"custom_proxy_group","valueStartsWith":"💬 即时通讯`"}
 *      匹配“💬 即时通讯”代理组，不要求它后面的模式和选项保持不变。
 *
 *    - occurrence：先应用上述所有字段得到完整匹配列表，再从列表中选择指定项：
 *      - "all"：全部匹配项。
 *      - "first"：第一项。
 *      - "last"：最后一项。
 *      - 正整数：按 1 开始计数，例如 2 表示第二项。
 *      - 负整数：从末尾计数，例如 -1 表示最后一项，-2 表示倒数第二项。
 *      示例：{"key":"ruleset","occurrence":2}
 *      表示文档中第二个 key 为 ruleset 的条目。insert 锚点默认 "first"，且必须最终
 *      只定位到一行；delete 选择器默认 "all"，会删除所有匹配行。
 *
 *    注意：选择器必须至少包含一个 occurrence 之外的匹配字段。空选择器、只填写
 *    occurrence，或使用 rawStartWith 等拼错的字段都会安全跳过对应操作，不会退化成
 *    “匹配全部”。当前选择器不支持正则表达式、模糊包含或忽略大小写匹配。
 *
 * 6. PROXY_GROUP_CONFIG（JSON 或 Text，可选，默认 null）
 *
 *    在全部 INI_OPERATIONS 执行完成后，默认对 custom_proxy_group 条目进行结构化调整。
 *    完整格式：
 *
 *    {
 *      "section": "custom",
 *      "key": "custom_proxy_group",
 *      "delimiter": "`",
 *      "promote": {
 *        "option": "[]🚀 手动选择",
 *        "exceptGroups": ["🎮 游戏平台","🚀 测速工具"]
 *      },
 *      "overrides": {
 *        "🤖 ChatGPT": {
 *          "mode": "select",
 *          "options": ["[]🚀 手动选择","[]♻️ 自动选择-AI",".*"]
 *        }
 *      },
 *      "onMissingOverride": "skip"
 *    }
 *
 *    字段：
 *
 *    - section：代理组所在 section，默认 "custom"；必须是不含换行符的非空字符串并精确
 *      匹配，配置值不会自动去除首尾空白。
 *    - key：代理组条目的 INI 键名，默认 "custom_proxy_group"；必须是非空字符串并精确
 *      匹配，配置值不会自动去除首尾空白，也不能包含换行符。
 *    - delimiter：组名、模式和选项之间的非空分隔符，默认反引号 "`"，支持不含换行符的
 *      多字符分隔符。
 *    - promote：可选置顶规则。
 *      - option：需要移到选项首位的非空字符串。配置值以及上游各选项比较时都会去除
 *        首尾空白；仅处理原本已包含该选项的组，并把重复的目标选项合并为一个。
 *      - exceptGroups：不调整顺序的代理组名称数组，默认 []；名称会去除首尾空白。
 *    - overrides：以代理组名称为键的覆盖对象，默认 {}。组名会去除首尾空白；同名代理组
 *      条目会被全部覆盖。每个覆盖必须包含：
 *      - mode：去除首尾空白后非空的模式字符串，例如 "select"、"url-test"、"fallback"。
 *      - options：字符串数组，按给定顺序完整替换原组的全部选项。
 *    - promote.option、exceptGroups 中的组名、override 组名、mode 和每个 option 都不能
 *      包含换行符或 delimiter，否则跳过对应 promote 或单个 override 并记录配置警告。
 *    - onMissingOverride：overrides 中的组不存在时，可选 "error" 或 "skip"，
 *      默认 "skip"。显式使用 "error" 时，缺少覆盖目标会终止转换并返回 HTTP 500。
 *
 *    存在 promote 或有效 override 时，如果目标 section 中没有可成功解析的对应 key，
 *    则跳过整项代理组调整；如果只有个别条目无法解析出“组名 + 模式”，只跳过该条目
 *    并继续处理其他组。对应警告只记录按 delimiter 取得的第一个字段（组名），不记录
 *    模式和其余选项；组名为空时显示 unnamed group。promote 格式错误时只跳过 promote；
 *    overrides 不是对象时跳过全部 overrides，某个 override 格式错误时只跳过该 override；
 *    无效的 onMissingOverride 会回退为 "skip"。顶层 JSON 不是对象、含未知字段，或
 *    section、key、delimiter 无效时，才跳过整个 PROXY_GROUP_CONFIG。以上非致命问题
 *    都会记录配置警告。
 *
 * 三、请求与执行顺序
 *
 * 1. 校验 AUTH_KEY/ALLOW_PUBLIC 和请求路径。
 * 2. 仅接受 GET、HEAD；其他方法返回 HTTP 405。
 * 3. 在请求上游前严格校验鉴权和 TARGET_URLS；这些核心配置无效时返回 HTTP 500。
 *    CACHE_TTL 无效时使用默认 60；INI_OPERATIONS 或 PROXY_GROUP_CONFIG 无效时跳过
 *    对应个性化配置，并把这些问题计入配置警告。
 * 4. 按 TARGET_URLS 顺序选择第一个成功的 2xx 上游。
 * 5. 按顺序执行 INI_OPERATIONS。
 * 6. 执行 PROXY_GROUP_CONFIG 的 promote，再执行 overrides。
 * 7. 配置格式错误默认跳过并计入 X-Config-Warnings；运行时匹配失败默认跳过并计入
 *    X-Transform-Warnings。有效配置显式使用 "error" 时返回 HTTP 500；未预期的内部
 *    转换异常会放弃全部修改并返回上游原文。
 * 8. 没有有效转换动作，或转换未造成插入、删除和字段值变化时，直接返回上游原文。
 *    文档发生变化后，如果上游只使用一种换行符则保持该风格；混用换行符时按 CRLF、
 *    LF、CR 的优先级选择一种并统一输出。HEAD 执行相同校验和转换，所有响应都不返回正文。
 *    成功读取上游后，X-Transform-Status 为 ok、partial、bypassed 或 error；任一配置或
 *    转换警告都会使正常结果成为 partial。X-Transform-Warnings 是运行时转换警告/错误
 *    数量，X-Config-Warnings 是非致命配置格式警告数量。鉴权、请求方法、TARGET_URLS
 *    或全部上游失败等发生在转换阶段之前的响应，不携带这些转换状态响应头。
 *
 * 四、执行效率与缓存边界
 *
 * 1. TARGET_URLS 必须按配置顺序依次尝试，以保证主目标优先；不会并发请求全部目标。
 *    Cloudflare 只缓存各上游 URL 的 2xx 响应，最终转换结果仍为 no-store，因此每次请求
 *    都会重新执行鉴权、配置校验和必要的转换。
 * 2. 没有有效 INI_OPERATIONS、promote 或 override 时，不创建 INI 文档；存在转换动作但
 *    最终没有发生修改时，也直接返回已经读取的上游原文，避免无意义的重新序列化。
 * 3. INI 文档通常只完整解析一次。插入或删除普通行时会增量维护 section 归属；只有插入
 *    或删除 section 标题、可能改变后续行归属时，才重新解析当前文档。
 * 4. occurrence 为 "first" 或正整数时，找到目标项后立即停止扫描；"last" 和 -1 只保留
 *    最后一个匹配位置；"all" 及小于 -1 的负整数需要扫描并保存完整匹配列表。
 * 5. 代理组条目只集中扫描一次，并按组名建立索引；多个 override 不会各自重新遍历全部
 *    代理组。以上优化不改变操作顺序、AND 匹配、onMissing 或 target 回退语义。
 */

const DEFAULT_CACHE_TTL = 60;
const TEXT_ENCODER = new TextEncoder();

class ConfigurationError extends Error {
    constructor(message) {
        super(message);
        this.name = 'ConfigurationError';
    }
}

class StrictTransformationError extends Error {
    constructor(message) {
        super(message);
        this.name = 'StrictTransformationError';
    }
}

function normalize(value) {
    return String(value ?? '').trim();
}

function isPlainObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function assertAllowedKeys(object, allowedKeys, label) {
    const allowed = new Set(allowedKeys);
    const unknown = Object.keys(object).filter(key => !allowed.has(key));

    if (unknown.length > 0) {
        throw new ConfigurationError(
            `${label} contains unknown field(s): ${unknown.join(', ')}`,
        );
    }
}

function parseBoolean(value, defaultValue = false) {
    if (value === undefined || value === null || value === '') {
        return defaultValue;
    }

    if (typeof value === 'boolean') return value;
    if (typeof value !== 'string') {
        throw new ConfigurationError(`Invalid boolean value: ${value}`);
    }

    const normalized = normalize(value).toLowerCase();

    if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
    if (['0', 'false', 'no', 'off'].includes(normalized)) return false;

    throw new ConfigurationError(`Invalid boolean value: ${value}`);
}

function parseJsonBinding(value, name, defaultValue) {
    if (value === undefined || value === null || value === '') {
        return defaultValue;
    }

    if (typeof value !== 'string') return value;

    try {
        return JSON.parse(value);
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        throw new ConfigurationError(`${name} is not valid JSON: ${message}`);
    }
}

function parseCacheTtl(value) {
    if (value === undefined || value === null || value === '') {
        return DEFAULT_CACHE_TTL;
    }

    let ttl;

    if (typeof value === 'number') {
        ttl = value;
    } else if (typeof value === 'string') {
        const normalized = value.trim();

        if (!/^\d+$/.test(normalized)) {
            throw new ConfigurationError(
                'CACHE_TTL must be a decimal integer from 0 to 86400',
            );
        }

        ttl = Number(normalized);
    } else {
        throw new ConfigurationError(
            'CACHE_TTL must be a decimal integer from 0 to 86400',
        );
    }

    if (!Number.isSafeInteger(ttl) || ttl < 0 || ttl > 86400) {
        throw new ConfigurationError(
            'CACHE_TTL must be a decimal integer from 0 to 86400',
        );
    }

    return ttl;
}

function parseTargetUrls(value) {
    const rawTargets = parseJsonBinding(value, 'TARGET_URLS', null);

    if (!Array.isArray(rawTargets) || rawTargets.length === 0) {
        throw new ConfigurationError(
            'TARGET_URLS must be a non-empty JSON array',
        );
    }

    const targets = [];
    const seen = new Set();

    for (let index = 0; index < rawTargets.length; index += 1) {
        if (typeof rawTargets[index] !== 'string') {
            throw new ConfigurationError(
                `TARGET_URLS[${index}] must be a string`,
            );
        }

        if (/\r|\n/.test(rawTargets[index])) {
            throw new ConfigurationError(
                `TARGET_URLS[${index}] cannot contain line breaks`,
            );
        }

        let url;

        try {
            url = new URL(normalize(rawTargets[index]));
        } catch {
            throw new ConfigurationError(
                `TARGET_URLS[${index}] is not a valid URL`,
            );
        }

        if (url.protocol !== 'http:' && url.protocol !== 'https:') {
            throw new ConfigurationError(
                `TARGET_URLS[${index}] must use HTTP or HTTPS`,
            );
        }

        url.hash = '';
        const normalizedUrl = url.toString();

        if (!seen.has(normalizedUrl)) {
            seen.add(normalizedUrl);
            targets.push(normalizedUrl);
        }
    }

    return targets;
}

async function fetchTarget(targetUrl, cacheTtl) {
    try {
        const response = await fetch(targetUrl, {
            headers: { Accept: 'text/plain, */*;q=0.9' },
            cf: {
                cacheEverything: true,
                cacheTtlByStatus: {
                    '200-299': cacheTtl,
                    '300-599': -1,
                },
            },
        });

        if (response.ok) return { response, error: null };

        const error = `${response.status} ${response.statusText}`.trim();

        if (response.body) {
            try {
                await response.body.cancel();
            } catch {
                // Releasing a failed response is best effort only.
            }
        }

        return { response: null, error };
    } catch {
        return {
            response: null,
            error: 'network request failed',
        };
    }
}

function formatTargetUrlForError(targetUrl) {
    const url = new URL(targetUrl);
    url.username = '';
    url.password = '';
    url.search = '';
    url.hash = '';
    return url.toString();
}

async function fetchSource(targetUrls, cacheTtl) {
    const failures = [];
    const recordFailure = (index, reason) => {
        const displayUrl = formatTargetUrlForError(targetUrls[index]);
        failures.push(`target ${index + 1}: ${displayUrl} -> ${reason}`);
    };

    for (let index = 0; index < targetUrls.length; index += 1) {
        const result = await fetchTarget(targetUrls[index], cacheTtl);

        if (result.response) {
            try {
                const sourceText = await result.response.text();

                if (sourceText.trim() === '') {
                    recordFailure(index, 'empty response body');
                    continue;
                }

                return {
                    sourceText,
                    targetIndex: index,
                    targetCount: targetUrls.length,
                };
            } catch {
                recordFailure(index, 'response body read failed');
                continue;
            }
        }

        recordFailure(index, result.error);
    }

    throw new Error(failures.join('\n'));
}

function textResponse(body, status = 200, extraHeaders = {}) {
    return new Response(body, {
        status,
        headers: {
            'Content-Type': 'text/plain; charset=utf-8',
            'Cache-Control': 'no-store',
            'X-Content-Type-Options': 'nosniff',
            ...extraHeaders,
        },
    });
}

function safeEqual(left, right) {
    const leftBytes = TEXT_ENCODER.encode(left);
    const rightBytes = TEXT_ENCODER.encode(right);

    if (leftBytes.byteLength !== rightBytes.byteLength) return false;

    const subtle = globalThis.crypto?.subtle;

    if (typeof subtle?.timingSafeEqual === 'function') {
        return subtle.timingSafeEqual(leftBytes, rightBytes);
    }

    let difference = 0;

    for (let index = 0; index < leftBytes.length; index += 1) {
        difference |= leftBytes[index] ^ rightBytes[index];
    }

    return difference === 0;
}

function getPathToken(pathname) {
    const match = /^\/([^/]+)\/?$/.exec(pathname);

    if (!match) return null;

    try {
        return decodeURIComponent(match[1]);
    } catch {
        return null;
    }
}

function isAuthorized(pathname, authKey) {
    const pathToken = getPathToken(pathname);

    if (pathToken === null) return false;

    return safeEqual(pathToken, authKey) || safeEqual(pathToken, `${authKey}.ini`);
}

function chooseNewline(text) {
    if (text.includes('\r\n')) return '\r\n';
    if (text.includes('\n')) return '\n';
    if (text.includes('\r')) return '\r';
    return '\n';
}

function parseIniLine(raw, currentSection = null) {
    const trimmedStart = raw.trimStart();

    if (trimmedStart === '') {
        return { lineType: 'blank', raw, section: currentSection, dirty: false };
    }

    if (trimmedStart.startsWith(';') || trimmedStart.startsWith('#')) {
        return { lineType: 'comment', raw, section: currentSection, dirty: false };
    }

    const sectionMatch = /^\[([^\]]+)]\s*(?:[;#].*)?$/.exec(trimmedStart);

    if (sectionMatch) {
        const name = normalize(sectionMatch[1]);

        if (name) {
            return { lineType: 'section', raw, name, section: name, dirty: false };
        }
    }

    const delimiterIndex = trimmedStart.indexOf('=');

    if (delimiterIndex > 0) {
        const left = trimmedStart.slice(0, delimiterIndex);
        const key = normalize(left);

        if (key) {
            const right = trimmedStart.slice(delimiterIndex + 1);
            const spacing = right.match(/^\s*/)?.[0] ?? '';
            const indent = raw.slice(0, raw.length - trimmedStart.length);

            return {
                lineType: 'entry',
                raw,
                section: currentSection,
                key,
                value: right.slice(spacing.length),
                prefix: `${indent}${left}=${spacing}`,
                dirty: false,
            };
        }
    }

    return { lineType: 'other', raw, section: currentSection, dirty: false };
}

function serializeNode(node) {
    if (node.lineType === 'entry' && node.dirty) return `${node.prefix}${node.value}`;
    return node.raw;
}

function setEntryValue(node, value) {
    if (node.lineType !== 'entry') {
        throw new ConfigurationError('Only INI entries can receive a new value');
    }

    if (node.value === value) return false;

    node.value = value;
    node.dirty = true;
    return true;
}

const SELECTOR_FIELDS = [
    'lineType',
    'section',
    'key',
    'value',
    'raw',
    'rawStartsWith',
    'valueStartsWith',
    'occurrence',
];

function prepareOccurrence(value, defaultValue, label) {
    const occurrence = value ?? defaultValue;

    if (['all', 'first', 'last'].includes(occurrence)) return occurrence;
    if (Number.isSafeInteger(occurrence) && occurrence !== 0) return occurrence;

    throw new ConfigurationError(
        `${label} must be all, first, last, or a non-zero integer`,
    );
}

function prepareSelector(selector, label, defaultOccurrence) {
    if (!isPlainObject(selector)) {
        throw new ConfigurationError(`${label} must be a JSON object`);
    }

    assertAllowedKeys(selector, SELECTOR_FIELDS, label);

    const matchFields = SELECTOR_FIELDS.filter(
        field => field !== 'occurrence' && selector[field] !== undefined,
    );

    if (matchFields.length === 0) {
        throw new ConfigurationError(
            `${label} must contain at least one matching field`,
        );
    }

    const prepared = {
        occurrence: prepareOccurrence(
            selector.occurrence,
            defaultOccurrence,
            `${label}.occurrence`,
        ),
    };

    if (selector.lineType !== undefined) {
        const allowedLineTypes = ['blank', 'comment', 'section', 'entry', 'other'];

        if (!allowedLineTypes.includes(selector.lineType)) {
            throw new ConfigurationError(
                `${label}.lineType must be one of: ${allowedLineTypes.join(', ')}`,
            );
        }

        prepared.lineType = selector.lineType;
    }

    if (selector.section !== undefined) {
        if (selector.section !== null && typeof selector.section !== 'string') {
            throw new ConfigurationError(`${label}.section must be a string or null`);
        }

        if (
            typeof selector.section === 'string' &&
            normalize(selector.section) === ''
        ) {
            throw new ConfigurationError(
                `${label}.section cannot be empty or whitespace; use null for root`,
            );
        }

        if (
            typeof selector.section === 'string' &&
            /\r|\n/.test(selector.section)
        ) {
            throw new ConfigurationError(`${label}.section cannot contain line breaks`);
        }

        prepared.section = selector.section;
    }

    for (const field of [
        'key',
        'value',
        'raw',
        'rawStartsWith',
        'valueStartsWith',
    ]) {
        if (selector[field] !== undefined) {
            if (typeof selector[field] !== 'string') {
                throw new ConfigurationError(`${label}.${field} must be a string`);
            }

            if (/\r|\n/.test(selector[field])) {
                throw new ConfigurationError(
                    `${label}.${field} cannot contain line breaks`,
                );
            }

            prepared[field] = selector[field];
        }
    }

    if (prepared.key !== undefined && normalize(prepared.key) === '') {
        throw new ConfigurationError(`${label}.key cannot be empty`);
    }

    if (prepared.rawStartsWith === '') {
        throw new ConfigurationError(`${label}.rawStartsWith cannot be empty`);
    }

    if (prepared.valueStartsWith === '') {
        throw new ConfigurationError(`${label}.valueStartsWith cannot be empty`);
    }

    return prepared;
}

function nodeMatches(node, selector) {
    if (
        selector.lineType !== undefined &&
        node.lineType !== selector.lineType
    ) {
        return false;
    }

    if (selector.section !== undefined) {
        const expectedSection = selector.section ?? '';
        const actualSection = node.section ?? '';
        if (actualSection !== expectedSection) return false;
    }

    if (selector.key !== undefined) {
        if (node.lineType !== 'entry' || node.key !== selector.key) return false;
    }

    if (selector.value !== undefined) {
        if (node.lineType !== 'entry' || node.value !== selector.value) return false;
    }

    if (selector.raw !== undefined && serializeNode(node) !== selector.raw) {
        return false;
    }

    if (
        selector.rawStartsWith !== undefined &&
        !serializeNode(node).startsWith(selector.rawStartsWith)
    ) {
        return false;
    }

    if (selector.valueStartsWith !== undefined) {
        if (
            node.lineType !== 'entry' ||
            !node.value.startsWith(selector.valueStartsWith)
        ) {
            return false;
        }
    }

    return true;
}

function selectOccurrence(indexes, occurrence) {
    if (occurrence === 'all') return indexes;
    if (indexes.length === 0) return [];
    if (occurrence === 'first') return [indexes[0]];
    if (occurrence === 'last') return [indexes[indexes.length - 1]];

    const position = occurrence > 0 ? occurrence - 1 : indexes.length + occurrence;
    return position >= 0 && position < indexes.length ? [indexes[position]] : [];
}

function prepareOnMissing(value, defaultValue, label) {
    const action = value ?? defaultValue;

    if (action !== 'skip' && action !== 'error') {
        throw new ConfigurationError(`${label} must be skip or error`);
    }

    return action;
}

function prepareInsertedLines(lines, label) {
    if (!Array.isArray(lines) || lines.length === 0) {
        throw new ConfigurationError(`${label} must be a non-empty JSON array`);
    }

    return lines.map((line, index) => {
        if (typeof line !== 'string') {
            throw new ConfigurationError(`${label}[${index}] must be a string`);
        }

        if (/\r|\n/.test(line)) {
            throw new ConfigurationError(
                `${label}[${index}] must contain exactly one logical line`,
            );
        }

        return line;
    });
}

function prepareOperation(operation, index) {
    const label = `INI_OPERATIONS[${index}]`;

    if (!isPlainObject(operation)) {
        throw new ConfigurationError(`${label} must be a JSON object`);
    }

    if (operation.op === 'insert') {
        assertAllowedKeys(
            operation,
            ['op', 'position', 'anchor', 'lines', 'onMissing'],
            label,
        );

        const allowedPositions = [
            'before',
            'after',
            'document-start',
            'document-end',
        ];

        if (!allowedPositions.includes(operation.position)) {
            throw new ConfigurationError(
                `${label}.position must be one of: ${allowedPositions.join(', ')}`,
            );
        }

        const usesAnchor = operation.position === 'before' || operation.position === 'after';

        if (usesAnchor && operation.anchor === undefined) {
            throw new ConfigurationError(`${label}.anchor is required`);
        }

        if (!usesAnchor && operation.anchor !== undefined) {
            throw new ConfigurationError(
                `${label}.anchor is only valid for before/after insertion`,
            );
        }

        return {
            op: 'insert',
            position: operation.position,
            anchor: usesAnchor
                ? prepareSelector(operation.anchor, `${label}.anchor`, 'first')
                : null,
            lines: prepareInsertedLines(operation.lines, `${label}.lines`),
            onMissing: prepareOnMissing(
                operation.onMissing,
                'skip',
                `${label}.onMissing`,
            ),
        };
    }

    if (operation.op === 'delete') {
        assertAllowedKeys(operation, ['op', 'selector', 'onMissing'], label);

        return {
            op: 'delete',
            selector: prepareSelector(
                operation.selector,
                `${label}.selector`,
                'all',
            ),
            onMissing: prepareOnMissing(
                operation.onMissing,
                'skip',
                `${label}.onMissing`,
            ),
        };
    }

    throw new ConfigurationError(`${label}.op must be insert or delete`);
}

function prepareOperations(value) {
    const rawOperations = parseJsonBinding(value, 'INI_OPERATIONS', []);

    if (!Array.isArray(rawOperations)) {
        throw new ConfigurationError('INI_OPERATIONS must be a JSON array');
    }

    const operations = [];
    const warnings = [];

    for (let index = 0; index < rawOperations.length; index += 1) {
        try {
            operations.push(prepareOperation(rawOperations[index], index));
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            warnings.push(`Skipped invalid INI operation ${index + 1}: ${message}`);
        }
    }

    return { operations, warnings };
}

class IniDocument {
    constructor(text) {
        this.newline = chooseNewline(text);
        this.hadFinalNewline = /(?:\r\n|\n|\r)$/.test(text);
        this.changed = false;

        const normalized = text.replace(/\r\n?/g, '\n');
        const rawLines = normalized.split('\n');

        if (this.hadFinalNewline) rawLines.pop();
        this.nodes = this.parseLines(rawLines);
    }

    parseLines(rawLines, currentSection = null) {
        const nodes = [];

        for (const rawLine of rawLines) {
            const node = parseIniLine(rawLine, currentSection);
            nodes.push(node);

            if (node.lineType === 'section') currentSection = node.name;
        }

        return nodes;
    }

    refresh() {
        this.nodes = this.parseLines(this.nodes.map(serializeNode));
    }

    findIndexes(selector) {
        const occurrence = selector.occurrence;
        const forwardTarget = occurrence === 'first'
            ? 1
            : Number.isSafeInteger(occurrence) && occurrence > 0
                ? occurrence
                : null;

        if (forwardTarget !== null) {
            let matchCount = 0;

            for (let index = 0; index < this.nodes.length; index += 1) {
                if (!nodeMatches(this.nodes[index], selector)) continue;

                matchCount += 1;
                if (matchCount === forwardTarget) return [index];
            }

            return [];
        }

        if (occurrence === 'last' || occurrence === -1) {
            let lastIndex = -1;

            for (let index = 0; index < this.nodes.length; index += 1) {
                if (nodeMatches(this.nodes[index], selector)) lastIndex = index;
            }

            return lastIndex === -1 ? [] : [lastIndex];
        }

        const indexes = [];

        for (let index = 0; index < this.nodes.length; index += 1) {
            if (nodeMatches(this.nodes[index], selector)) indexes.push(index);
        }

        return selectOccurrence(indexes, occurrence);
    }

    insert(operation) {
        let index;

        if (operation.position === 'document-start') {
            index = 0;
        } else if (operation.position === 'document-end') {
            index = this.nodes.length;
        } else {
            const indexes = this.findIndexes(operation.anchor);

            if (indexes.length === 0) {
                throw new ConfigurationError('Insert anchor did not match any line');
            }

            if (indexes.length !== 1) {
                throw new ConfigurationError(
                    'Insert anchor must resolve to exactly one line',
                );
            }

            index = operation.position === 'before' ? indexes[0] : indexes[0] + 1;
        }

        const currentSection = index === 0 ? null : this.nodes[index - 1].section;
        const newNodes = this.parseLines(operation.lines, currentSection);
        const changesSectionFlow = newNodes.some(
            node => node.lineType === 'section',
        );

        this.nodes.splice(index, 0, ...newNodes);
        this.changed = true;

        if (changesSectionFlow) this.refresh();
    }

    delete(operation) {
        const indexes = this.findIndexes(operation.selector);

        if (indexes.length === 0) {
            throw new ConfigurationError('Delete selector did not match any line');
        }

        const changesSectionFlow = indexes.some(
            index => this.nodes[index].lineType === 'section',
        );

        for (const index of [...indexes].sort((left, right) => right - left)) {
            this.nodes.splice(index, 1);
        }

        this.changed = true;

        if (changesSectionFlow) this.refresh();
    }

    applyOperations(operations, warnings) {
        for (let index = 0; index < operations.length; index += 1) {
            try {
                if (operations[index].op === 'insert') {
                    this.insert(operations[index]);
                } else {
                    this.delete(operations[index]);
                }
            } catch (error) {
                if (!(error instanceof ConfigurationError)) throw error;

                const message = error instanceof Error ? error.message : String(error);

                if (operations[index].onMissing === 'error') {
                    throw new StrictTransformationError(
                        `INI operation ${index + 1} failed: ${message}`,
                    );
                }

                warnings.push(`INI operation ${index + 1} skipped: ${message}`);
            }
        }
    }

    toString() {
        const body = this.nodes.map(serializeNode).join(this.newline);
        return body + (this.hadFinalNewline ? this.newline : '');
    }
}

function prepareStringArray(value, label) {
    if (!Array.isArray(value)) {
        throw new ConfigurationError(`${label} must be a JSON array`);
    }

    return value.map((item, index) => {
        if (typeof item !== 'string') {
            throw new ConfigurationError(`${label}[${index}] must be a string`);
        }

        return item;
    });
}

function assertSingleLine(value, label) {
    if (/\r|\n/.test(value)) {
        throw new ConfigurationError(`${label} cannot contain line breaks`);
    }
}

function assertProxyComponent(value, delimiter, label) {
    assertSingleLine(value, label);

    if (value.includes(delimiter)) {
        throw new ConfigurationError(`${label} cannot contain delimiter ${delimiter}`);
    }
}

function prepareProxyGroupConfig(value) {
    const config = parseJsonBinding(value, 'PROXY_GROUP_CONFIG', null);

    if (config === null) return { config: null, warnings: [] };

    if (!isPlainObject(config)) {
        throw new ConfigurationError('PROXY_GROUP_CONFIG must be a JSON object');
    }

    assertAllowedKeys(
        config,
        ['section', 'key', 'delimiter', 'promote', 'overrides', 'onMissingOverride'],
        'PROXY_GROUP_CONFIG',
    );

    const section = config.section ?? 'custom';
    const key = config.key ?? 'custom_proxy_group';
    const delimiter = config.delimiter ?? '`';

    if (typeof section !== 'string' || normalize(section) === '') {
        throw new ConfigurationError('PROXY_GROUP_CONFIG.section must be a non-empty string');
    }

    if (typeof key !== 'string' || normalize(key) === '') {
        throw new ConfigurationError('PROXY_GROUP_CONFIG.key must be a non-empty string');
    }

    if (typeof delimiter !== 'string' || delimiter.length === 0) {
        throw new ConfigurationError('PROXY_GROUP_CONFIG.delimiter must be non-empty');
    }

    assertSingleLine(section, 'PROXY_GROUP_CONFIG.section');
    assertSingleLine(key, 'PROXY_GROUP_CONFIG.key');
    assertSingleLine(delimiter, 'PROXY_GROUP_CONFIG.delimiter');

    const warnings = [];
    let promote = null;

    if (config.promote !== undefined && config.promote !== null) {
        try {
            if (!isPlainObject(config.promote)) {
                throw new ConfigurationError(
                    'PROXY_GROUP_CONFIG.promote must be an object',
                );
            }

            assertAllowedKeys(
                config.promote,
                ['option', 'exceptGroups'],
                'PROXY_GROUP_CONFIG.promote',
            );

            if (typeof config.promote.option !== 'string') {
                throw new ConfigurationError(
                    'PROXY_GROUP_CONFIG.promote.option must be a string',
                );
            }

            assertSingleLine(
                config.promote.option,
                'PROXY_GROUP_CONFIG.promote.option',
            );
            const option = normalize(config.promote.option);

            if (!option) {
                throw new ConfigurationError(
                    'PROXY_GROUP_CONFIG.promote.option must be non-empty',
                );
            }

            assertProxyComponent(
                option,
                delimiter,
                'PROXY_GROUP_CONFIG.promote.option',
            );

            const rawExceptGroups = prepareStringArray(
                config.promote.exceptGroups ?? [],
                'PROXY_GROUP_CONFIG.promote.exceptGroups',
            );

            for (let index = 0; index < rawExceptGroups.length; index += 1) {
                assertProxyComponent(
                    rawExceptGroups[index],
                    delimiter,
                    `PROXY_GROUP_CONFIG.promote.exceptGroups[${index}]`,
                );
            }

            const exceptGroups = rawExceptGroups.map(normalize);

            if (exceptGroups.some(groupName => !groupName)) {
                throw new ConfigurationError(
                    'PROXY_GROUP_CONFIG.promote.exceptGroups cannot contain empty names',
                );
            }

            promote = { option, exceptGroups: new Set(exceptGroups) };
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            warnings.push(`Proxy-group promotion skipped: ${message}`);
        }
    }

    const rawOverrides = config.overrides ?? {};
    const overrides = new Map();

    if (!isPlainObject(rawOverrides)) {
        warnings.push('All proxy-group overrides skipped: overrides must be an object');
    } else {
        for (const [rawGroupName, specification] of Object.entries(rawOverrides)) {
            const label = `PROXY_GROUP_CONFIG.overrides.${rawGroupName}`;

            try {
                assertSingleLine(rawGroupName, `${label} name`);
                const groupName = normalize(rawGroupName);

                if (!groupName) {
                    throw new ConfigurationError('Override name cannot be empty');
                }

                assertProxyComponent(groupName, delimiter, `${label} name`);

                if (!isPlainObject(specification)) {
                    throw new ConfigurationError(`${label} must be an object`);
                }

                assertAllowedKeys(specification, ['mode', 'options'], label);

                if (typeof specification.mode !== 'string') {
                    throw new ConfigurationError(`${label}.mode must be a string`);
                }

                assertSingleLine(specification.mode, `${label}.mode`);
                const mode = normalize(specification.mode);

                if (!mode) {
                    throw new ConfigurationError(`${label}.mode must be non-empty`);
                }

                assertProxyComponent(mode, delimiter, `${label}.mode`);

                const options = prepareStringArray(
                    specification.options,
                    `${label}.options`,
                );

                for (let index = 0; index < options.length; index += 1) {
                    assertProxyComponent(
                        options[index],
                        delimiter,
                        `${label}.options[${index}]`,
                    );
                }

                overrides.set(groupName, { mode, options });
            } catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                warnings.push(`Proxy-group override skipped: ${message}`);
            }
        }
    }

    let onMissingOverride = 'skip';

    try {
        onMissingOverride = prepareOnMissing(
            config.onMissingOverride,
            'skip',
            'PROXY_GROUP_CONFIG.onMissingOverride',
        );
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        warnings.push(`Invalid onMissingOverride replaced with skip: ${message}`);
    }

    return {
        config: {
            section,
            key,
            delimiter,
            promote,
            overrides,
            onMissingOverride,
        },
        warnings,
    };
}

function parseProxyGroup(value, delimiter) {
    const parts = value.split(delimiter);

    if (parts.length < 2 || !normalize(parts[0]) || !normalize(parts[1])) {
        return null;
    }

    return {
        name: normalize(parts[0]),
        mode: parts[1],
        options: parts.slice(2),
    };
}

function stringifyProxyGroup(group, delimiter) {
    return [group.name, group.mode, ...group.options].join(delimiter);
}

function applyProxyGroupConfig(document, config, warnings) {
    if (config === null) return;
    if (!config.promote && config.overrides.size === 0) return;

    const groups = [];
    const groupsByName = new Map();

    for (const node of document.nodes) {
        if (
            node.lineType !== 'entry' ||
            node.section !== config.section ||
            node.key !== config.key
        ) {
            continue;
        }

        const group = parseProxyGroup(node.value, config.delimiter);

        if (!group) {
            const groupName = normalize(node.value.split(config.delimiter, 1)[0]);
            warnings.push(groupName
                ? `Skipped invalid proxy-group entry: group ${JSON.stringify(groupName)}`
                : 'Skipped invalid proxy-group entry: unnamed group');
            continue;
        }

        const item = { node, group };
        groups.push(item);

        const sameNameGroups = groupsByName.get(group.name);

        if (sameNameGroups) {
            sameNameGroups.push(item);
        } else {
            groupsByName.set(group.name, [item]);
        }
    }

    if (groups.length === 0) {
        warnings.push(
            `Proxy-group config skipped: no valid ${config.key} entries found in ` +
            `section [${config.section}]`,
        );
        return;
    }

    if (config.promote) {
        for (const item of groups) {
            if (config.promote.exceptGroups.has(item.group.name)) continue;

            let containsOption = false;
            const remainingOptions = [];

            for (const option of item.group.options) {
                if (normalize(option) === config.promote.option) {
                    containsOption = true;
                } else {
                    remainingOptions.push(option);
                }
            }

            if (!containsOption) continue;

            item.group.options = [
                config.promote.option,
                ...remainingOptions,
            ];

            if (
                setEntryValue(
                    item.node,
                    stringifyProxyGroup(item.group, config.delimiter),
                )
            ) {
                document.changed = true;
            }
        }
    }

    for (const [groupName, override] of config.overrides) {
        const targets = groupsByName.get(groupName) ?? [];

        if (targets.length === 0) {
            if (config.onMissingOverride === 'error') {
                throw new StrictTransformationError(
                    `Proxy group not found: ${groupName}`,
                );
            }

            warnings.push(`Proxy-group override skipped: group not found: ${groupName}`);
            continue;
        }

        const value = stringifyProxyGroup(
            { name: groupName, mode: override.mode, options: override.options },
            config.delimiter,
        );

        for (const target of targets) {
            if (setEntryValue(target.node, value)) document.changed = true;
        }
    }
}

export default {
    async fetch(request, env) {
        const requestUrl = new URL(request.url);
        const respond = (body, status = 200, extraHeaders = {}) => textResponse(
            request.method === 'HEAD' ? null : body,
            status,
            extraHeaders,
        );
        const rawAuthKey = env.AUTH_KEY;

        if (
            rawAuthKey !== undefined &&
            rawAuthKey !== null &&
            typeof rawAuthKey !== 'string'
        ) {
            return respond('Server configuration error', 500);
        }

        const authKey = normalize(rawAuthKey);

        if (!authKey) {
            let allowPublic;

            try {
                allowPublic = parseBoolean(env.ALLOW_PUBLIC, false);
            } catch {
                return respond('Server configuration error', 500);
            }

            if (!allowPublic) {
                return respond('Server configuration error', 500);
            }
        }

        if (authKey && !isAuthorized(requestUrl.pathname, authKey)) {
            return respond('Forbidden', 403);
        }

        if (request.method !== 'GET' && request.method !== 'HEAD') {
            return respond('Method Not Allowed', 405, { Allow: 'GET, HEAD' });
        }

        let targetUrls;

        try {
            targetUrls = parseTargetUrls(env.TARGET_URLS);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return respond(`Server configuration error: ${message}`, 500);
        }

        const configWarnings = [];
        let cacheTtl = DEFAULT_CACHE_TTL;

        try {
            cacheTtl = parseCacheTtl(env.CACHE_TTL);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            configWarnings.push(`CACHE_TTL replaced with default 60: ${message}`);
        }

        const transformWarnings = [];
        let operations = [];
        let proxyGroupConfig = null;

        try {
            const prepared = prepareOperations(env.INI_OPERATIONS);
            operations = prepared.operations;
            configWarnings.push(...prepared.warnings);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            configWarnings.push(`INI_OPERATIONS skipped: ${message}`);
        }

        try {
            const prepared = prepareProxyGroupConfig(env.PROXY_GROUP_CONFIG);
            proxyGroupConfig = prepared.config;
            configWarnings.push(...prepared.warnings);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            configWarnings.push(`PROXY_GROUP_CONFIG skipped: ${message}`);
        }

        let upstreamResult;

        try {
            upstreamResult = await fetchSource(targetUrls, cacheTtl);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return respond(`All configured upstream targets failed:\n${message}`, 502);
        }

        const sourceText = upstreamResult.sourceText;
        let output = sourceText;
        let transformStatus;
        const hasProxyGroupActions = proxyGroupConfig !== null && (
            proxyGroupConfig.promote !== null ||
            proxyGroupConfig.overrides.size > 0
        );
        const hasTransformations = operations.length > 0 || hasProxyGroupActions;

        try {
            if (hasTransformations) {
                const document = new IniDocument(sourceText);

                document.applyOperations(operations, transformWarnings);
                applyProxyGroupConfig(document, proxyGroupConfig, transformWarnings);
                if (document.changed) output = document.toString();
            }

            transformStatus = configWarnings.length + transformWarnings.length > 0
                ? 'partial'
                : 'ok';
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);

            if (error instanceof StrictTransformationError) {
                transformWarnings.push(message);

                if (configWarnings.length > 0) {
                    console.warn(`[sub-config] ${configWarnings.join(' | ')}`);
                }

                console.error(`[sub-config] ${transformWarnings.join(' | ')}`);

                return respond(`INI transformation failed: ${message}`, 500, {
                    'X-Upstream-Index': String(upstreamResult.targetIndex + 1),
                    'X-Upstream-Count': String(upstreamResult.targetCount),
                    'X-Config-Warnings': String(configWarnings.length),
                    'X-Transform-Status': 'error',
                    'X-Transform-Warnings': String(transformWarnings.length),
                });
            }

            transformWarnings.push(`All transformations bypassed: ${message}`);
            transformStatus = 'bypassed';
            output = sourceText;
        }

        if (transformWarnings.length > 0) {
            console.warn(`[sub-config] ${transformWarnings.join(' | ')}`);
        }

        if (configWarnings.length > 0) {
            console.warn(`[sub-config] ${configWarnings.join(' | ')}`);
        }

        return respond(
            output,
            200,
            {
                'X-Upstream-Index': String(upstreamResult.targetIndex + 1),
                'X-Upstream-Count': String(upstreamResult.targetCount),
                'X-Config-Warnings': String(configWarnings.length),
                'X-Transform-Status': transformStatus,
                'X-Transform-Warnings': String(transformWarnings.length),
            },
        );
    },
};
