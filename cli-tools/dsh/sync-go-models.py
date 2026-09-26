#!/usr/bin/env python3
"""补齐 dsh 安装目录中的 OpenCode Go catalog；重启 dsh 后生效。"""
import argparse
import copy
import json
from pathlib import Path
import shutil
import subprocess

LIVE_URL = 'https://opencode.ai/zen/go/v1/models'
METADATA_URL = 'https://models.dev/api.json'
# 新模型沿用同系列在 pi-ai 中的协议及兼容处理；未知系列拒绝自动猜测。
TEMPLATES = {
    'deepseek-flash': 'deepseek-v4-flash-vision-exp',
    'deepseek-v4.1-flash': 'deepseek-v4-flash-vision-exp',
    'glm-5': 'glm-5.1',
    'gpt-6-luna': 'gpt-5.6-luna',
    'grok-4.5': 'grok-4.6',
    'grok-4.7': 'grok-4.6',
    'hy3-preview': 'hy3',
    'kimi-k2.5': 'kimi-k2.6',
    'longcat-2.5-preview-free': 'longcat-2.0',
    'mimo-v2-omni': 'mimo-v2.5',
    'mimo-v2-pro': 'mimo-v2.5-pro',
    'mimo-v2.6-flash': 'mimo-v2.5',
    'mimo-v2.6-pro': 'mimo-v2.5-pro',
    'minimax-m2.5': 'minimax-m3',
    'qwen3.5-plus': 'qwen3.6-plus',
    'space-bunny-free': 'omen-alpha',
}
ALIASES = {'deepseek-flash': 'deepseek-v4.1-flash', 'hy3-preview': 'hy3'}
LEVELS = ['off', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max']


def fetch(url):
    return json.loads(subprocess.check_output(
        ['curl', '--fail', '--silent', '--show-error', '--max-time', '30', url], text=True))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='写入目录（默认仅预览）')
    args = parser.parse_args()
    executable = shutil.which('dsh')
    if not executable:
        raise SystemExit('找不到 dsh')
    root = Path(executable).resolve().parent.parent
    catalog = root / 'node_modules/@earendil-works/pi-ai/dist/providers/data/opencode-go.json'
    original = catalog.read_bytes()
    data = json.loads(original)
    installed = {id: model for group in data.values() for id, model in group.items()}
    live = [item['id'] for item in fetch(LIVE_URL)['data']]
    if not live or len(live) != len(set(live)):
        raise SystemExit('实时接口返回空列表或重复模型，未修改')
    metadata = fetch(METADATA_URL)['opencode-go']['models']
    missing = sorted(set(live) - set(installed))
    for id in missing:
        template = TEMPLATES.get(id)
        if template not in installed:
            raise SystemExit(f'{id}: 缺少已审查的协议模板，未修改')
        source = metadata.get(ALIASES.get(id, id))
        if not source:
            raise SystemExit(f'{id}: 缺少能力元数据，未修改')
        model = copy.deepcopy(installed[template])
        model.update(id=id, name=source['name'], reasoning=source['reasoning'],
                     input=[m for m in source['modalities']['input'] if m in ['text', 'image']],
                     contextWindow=source['limit']['context'], maxTokens=source['limit']['output'])
        if id == 'hy3-preview':
            model['name'] = 'Hy3 Preview'
        if 'image' not in model['input']:
            model.pop('inputLimits', None)
        cost = source['cost']
        model['cost'] = {dest: cost.get(src, 0) for src, dest in
                         [('input', 'input'), ('output', 'output'),
                          ('cache_read', 'cacheRead'), ('cache_write', 'cacheWrite')]}
        efforts = next((o['values'] for o in source.get('reasoning_options', [])
                        if o['type'] == 'effort'), None)
        if efforts:
            model['thinkingLevelMap'] = {level: level if level in efforts else None for level in LEVELS}
        data.setdefault(model['api'], {})[id] = model
    print(f'实时接口 {len(live)} 个；本地 {len(installed)} 个；新增 {len(missing)} 个：')
    print(', '.join(missing) or '无需新增')
    if args.apply and missing:
        backup = catalog.with_suffix('.json.before-go-sync')
        if not backup.exists():
            backup.write_bytes(original)
        temporary = catalog.with_suffix('.json.tmp')
        temporary.write_text(json.dumps(data, ensure_ascii=False) + '\n')
        temporary.replace(catalog)
        print(f'已更新 {catalog}；备份：{backup}。请重启 dsh 服务。')


if __name__ == '__main__':
    main()
