export default {
    async fetch(request, env) {
        // 从环境变量读取目标链接、添加和删除的行
        const TARGET_URL = env.TARGET_URL;
        const ADD_LINES = env.ADD_LINES ? env.ADD_LINES.split('\n') : [];
        const DELETE_LINES = env.DELETE_LINES ? env.DELETE_LINES.split('\n') : [];

        const response = await fetch(TARGET_URL);
        let configText = await response.text();

        // 按行分割
        let lines = configText.split('\n');

        // 删除自定义行
        lines = lines.filter(line => !DELETE_LINES.includes(line.trim()));

        // 添加自定义行
        lines.push(...ADD_LINES);

        // 调整custom_proxy_group
        lines = lines.map(line => {
            if (line.startsWith('custom_proxy_group=') && line.includes('[]🚀 手动选择')) {
                let parts = line.split('`');
                let header = parts.slice(0, 2);
                let options = parts.slice(2);

                // 移动“🚀 手动选择”到第一个
                options = options.filter(opt => opt !== '[]🚀 手动选择');
                options.unshift('[]🚀 手动选择');

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
