export default {
    async fetch(request, env) {
        // —— 鉴权开始：仅当配置了 AUTH_KEY 时才校验路径 ——
        const AUTH_KEY = (env.AUTH_KEY ?? '').trim(); // 未配置或空字符串则视为未启用鉴权
        const url = new URL(request.url);
        // 取路径核心文本：去掉首尾斜杠
        const pathToken = url.pathname.replace(/^\/+|\/+$/g, '');

        if (AUTH_KEY) {
            // 启用鉴权：只有当路径文本与 AUTH_KEY 完全一致时才通过
            if (pathToken !== AUTH_KEY) {
                return new Response('Forbidden', { status: 403 });
            }
        }
        // 未配置 AUTH_KEY 时不做校验，直接放行
        // —— 鉴权结束 ——

        const TARGET_URL = env.TARGET_URL || 'https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/cfg/Custom_Clash.ini';
        const ADD_LINES = (env.ADD_LINES || '').replace(/\r/g, '').split('\n').filter(Boolean);
        const DELETE_LINES_RAW = (env.DELETE_LINES || '').replace(/\r/g, '').split('\n').filter(Boolean);
        const WHITELIST_GROUPS_RAW = (env.WHITELIST_GROUPS || '').split('|').filter(s => s !== '');
        const MANUAL_SELECTION_RAW = env.MANUAL_SELECTION || '[]🚀 手动选择';
        const GROUP_OVERRIDES_RAW = (env.GROUP_OVERRIDES || '').replace(/\r/g, '').split('\n').map(s => s.trim()).filter(Boolean);

        // 统一标准化函数
        const norm = s => s.replace(/\r/g, '').trim();
        const MANUAL_SELECTION = norm(MANUAL_SELECTION_RAW);
        const WHITELIST_GROUPS = new Set(WHITELIST_GROUPS_RAW.map(norm));
        const DELETE_LINES = new Set(DELETE_LINES_RAW.map(norm));

        // 解析 GROUP_OVERRIDES 为 Map<groupName, overrideLineAfterEqual>
        const GROUP_OVERRIDES = new Map();
        for (const line of GROUP_OVERRIDES_RAW) {
            const i = line.indexOf('`');
            if (i <= 0) continue; // 必须含组名与模式
            const gname = norm(line.slice(0, i));
            GROUP_OVERRIDES.set(gname, line); // 覆盖内容就是整行（等号后的全部）
        }

        // 尝试从远程获取配置文件
        let configText = '';
        try {
            const resp = await fetch(TARGET_URL, { cf: { cacheTtl: 60 } });
            if (!resp.ok) {
                return new Response(`Upstream fetch failed: ${resp.status} ${resp.statusText}`, { status: 502 });
            }
            configText = await resp.text();
        } catch (e) {
            return new Response(`Fetch error: ${e instanceof Error ? e.message : String(e)}`, { status: 502 });
        }

        // 统一换行符为 \n
        configText = configText.replace(/\r/g, '');
        let lines = configText.split('\n');

        // 插入行：position 使用 1-based；-1 表示末尾
        let offset = 0;
        for (const addLine of ADD_LINES) {
            const idx = addLine.indexOf(':');
            if (idx <= 0) continue; // 无效或没有位置
            const positionStr = addLine.slice(0, idx);
            const lineContent = addLine.slice(idx + 1); // 保留冒号后的所有内容
            const position = Number.parseInt(positionStr, 10);

            if (Number.isNaN(position)) continue;

            if (position === -1) {
                lines.push(lineContent);
                continue;
            }

            // 1-based 边界：插到第 k 行之前，允许 k = lines.length + 1（等价于末尾追加）
            const target = position + offset;
            if (target >= 1 && target <= lines.length + 1) {
                lines.splice(target - 1, 0, lineContent);
                offset += 1;
            }
        }

        // 删除行：两侧都规范化后比对
        lines = lines.filter(line => !DELETE_LINES.has(norm(line)));

        // 调整 custom_proxy_group：把 MANUAL_SELECTION 提到首位（白名单除外）
        lines = lines.map(rawLine => {
            const line = rawLine.replace(/\r/g, '');
            const trimmedStart = line.trimStart();

            // 跳过注释行
            if (trimmedStart.startsWith(';') || trimmedStart.startsWith('#')) return rawLine;

            if (!trimmedStart.startsWith('custom_proxy_group=')) return rawLine;

            // 仅在包含 MANUAL_SELECTION（规范化后）时处理
            const parts = trimmedStart.split('`');
            if (parts.length < 3) return rawLine;

            const header0 = parts[0]; // "custom_proxy_group=GroupName"
            const header1 = parts[1]; // 模式：select/url-test/...
            const options = parts.slice(2);

            const groupName = norm(header0.replace('custom_proxy_group=', ''));

            // 如果选项规范化后没有 MANUAL_SELECTION，就不处理
            const hasManual = options.some(opt => norm(opt) === MANUAL_SELECTION);
            if (!hasManual) return rawLine;

            if (!WHITELIST_GROUPS.has(groupName)) {
                // 去重：移除所有变体后再放到最前
                const filtered = options.filter(opt => norm(opt) !== MANUAL_SELECTION);
                const newOptions = [MANUAL_SELECTION, ...filtered];
                return `${header0}\`${header1}\`${newOptions.join('`')}`;
            }

            // 白名单保持原样
            return rawLine;
        });

        // 根据 GROUP_OVERRIDES 覆盖指定组的“模式与可选项”
        lines = lines.map(rawLine => {
            const noCR = rawLine.replace(/\r/g, '');
            const trimmedStart = noCR.trimStart();

            if (trimmedStart.startsWith(';') || trimmedStart.startsWith('#')) return rawLine;
            if (!trimmedStart.startsWith('custom_proxy_group=')) return rawLine;

            // 取原行缩进以保持格式
            const indent = (noCR.match(/^\s*/) || [''])[0];

            // 解析组名
            const afterEq = trimmedStart.slice('custom_proxy_group='.length);
            const groupName = norm(afterEq.split('`')[0] || '');
            const overrideBody = GROUP_OVERRIDES.get(groupName);

            if (!overrideBody) return rawLine;

            // 直接替换等号后的全部内容为环境变量提供的行
            return `${indent}custom_proxy_group=${overrideBody}`;
        });

        const modifiedConfig = lines.join('\n');

        return new Response(modifiedConfig, {
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
    },
};
