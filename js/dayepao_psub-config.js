export default {
    async fetch(request, env) {
        // 从环境变量读取目标链接、添加和删除的行
        const TARGET_URL = env.TARGET_URL || 'https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/cfg/Custom_Clash.ini';
        const ADD_LINES = env.ADD_LINES ? env.ADD_LINES.split('\n') : [];
        const DELETE_LINES = env.DELETE_LINES ? env.DELETE_LINES.split('\n') : [];
        const WHITELIST_GROUPS = env.WHITELIST_GROUPS ? env.WHITELIST_GROUPS.split('|') : [];
        const MANUAL_SELECTION = env.MANUAL_SELECTION || '[]🚀 手动选择';

        const response = await fetch(TARGET_URL);
        let configText = await response.text();

        // 按行分割
        let lines = configText.split('\n');

        // 删除自定义行
        lines = lines.filter(line => !DELETE_LINES.includes(line.trim()));

        // 添加自定义行
        lines.push(...ADD_LINES);

        // 调整custom_proxy_group，白名单内规则组保持原顺序
        lines = lines.map(line => {
            if (line.startsWith('custom_proxy_group=') && line.includes(MANUAL_SELECTION)) {
                let parts = line.split('`');
                let header = parts.slice(0, 2);
                let options = parts.slice(2);

                const groupName = header[0].replace('custom_proxy_group=', '').trim();

                if (!WHITELIST_GROUPS.includes(groupName)) {
                    // 移动“手动选择”到第一个
                    options = options.filter(opt => opt !== MANUAL_SELECTION);
                    options.unshift(MANUAL_SELECTION);
                }

                return [...header, ...options].join('`');
            }
            return line;
        });

        const modifiedConfig = lines.join('\n');

        return new Response(modifiedConfig, {
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
    },
};
