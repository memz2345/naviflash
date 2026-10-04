# 一次性脚本：给 6 份 arb 追加「文件关联」相关文案，插在文件末尾的 "}" 之前。
import io, os, sys

BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lib', 'l10n')

VALUES = {
    'app_zh.arb': (
        '文件关联', '设为默认打开方式', '双击视频文件时直接用 NaviFlash 播放'),
    'app_zh_CN.arb': (
        '文件关联', '设为默认打开方式', '双击视频文件时直接用 NaviFlash 播放'),
    'app_zh_HK.arb': (
        '檔案關聯', '設為預設開啟方式', '雙擊影片檔案時直接用 NaviFlash 播放'),
    'app_zh_TW.arb': (
        '檔案關聯', '設為預設開啟方式', '雙擊影片檔案時直接用 NaviFlash 播放'),
    'app_en.arb': (
        'File associations', 'Set as default app',
        'Open video files with NaviFlash on double-click'),
    'app_en_US.arb': (
        'File associations', 'Set as default app',
        'Open video files with NaviFlash on double-click'),
}

KEYS = ('prefFileAssocSection', 'prefFileAssocDefault', 'prefFileAssocDefaultSub')

for name, texts in VALUES.items():
    path = os.path.join(BASE, name)
    with io.open(path, encoding='utf-8') as f:
        content = f.read()
    if 'prefFileAssocSection' in content:
        print('skip (already present):', name)
        continue
    idx = content.rstrip().rfind('\n}')
    if idx < 0:
        print('ERROR: no trailing } in', name)
        sys.exit(1)
    head = content.rstrip()[:idx].rstrip()
    if not head.endswith('"'):
        print('ERROR: unexpected tail in', name, repr(head[-40:]))
        sys.exit(1)
    lines = [head + ',']
    for key, text in zip(KEYS, texts):
        lines.append('  "%s": "%s"%s' % (key, text, ',' if key != KEYS[-1] else ''))
    new = '\n'.join(lines) + '\n}\n'
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(new)
    print('updated:', name)
