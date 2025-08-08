export default {
    async fetch(request, env) {
        const TARGET_URL = env.TARGET_URL || 'https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/cfg/Custom_Clash.ini';
        const ADD_LINES = (env.ADD_LINES || '').replace(/\r/g, '').split('\n').filter(Boolean);
        const DELETE_LINES_RAW = (env.DELETE_LINES || '').replace(/\r/g, '').split('\n').filter(Boolean);
        const WHITELIST_GROUPS_RAW = (env.WHITELIST_GROUPS || '').split('|').filter(s => s !== '');
        const MANUAL_SELECTION_RAW = env.MANUAL_SELECTION || '[]🚀 手动选择';

        // 统一标准化函数
        const norm = s => s.replace(/\r/g, '').trim();
        const MANUAL_SELECTION = norm(MANUAL_SELECTION_RAW);
        const WHITELIST_GROUPS = new Set(WHITELIST_GROUPS_RAW.map(norm));
        const DELETE_LINES = new Set(DELETE_LINES_RAW.map(norm));

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
            // 注意：比较前对被分片项做 norm()
            const parts = trimmedStart.split('`');
            if (parts.length < 3) return rawLine;

            const header0 = parts[0]; // "custom_proxy_group=GroupName"
            const header1 = parts[1]; // e.g., "select" / "url-test" / ...
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

        const modifiedConfig = lines.join('\n');

        return new Response(modifiedConfig, {
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
    },
};
