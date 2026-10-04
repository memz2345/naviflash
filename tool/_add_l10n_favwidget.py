# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「小组件收藏夹选择」相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_favwidget.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'favWidgetPickTitle',
    'favWidgetPickHint',
    'favWidgetNeedLogin',
]

# key -> placeholder 名
ARGS = {
    'favWidgetFolderSwitched': 'name',
}

ZH_CN = {
    'favWidgetPickTitle': '选择收藏夹',
    'favWidgetPickHint': '小组件会显示该收藏夹里最新收藏的内容',
    'favWidgetNeedLogin': '请先登录后再选择收藏夹',
    'favWidgetFolderSwitched': '已切换为「{name}」',
}

ZH_HK = {
    'favWidgetPickTitle': '選擇收藏夾',
    'favWidgetPickHint': '小工具會顯示該收藏夾裡最新收藏的內容',
    'favWidgetNeedLogin': '請先登入後再選擇收藏夾',
    'favWidgetFolderSwitched': '已切換為「{name}」',
}

ZH_TW = dict(ZH_HK)

EN = {
    'favWidgetPickTitle': 'Choose a folder',
    'favWidgetPickHint': 'The widget shows the newest saved items from this folder.',
    'favWidgetNeedLogin': 'Sign in first to choose a folder.',
    'favWidgetFolderSwitched': 'Now showing {name}',
}

LOCALES = {
    'zh_CN': ZH_CN,
    'zh': ZH_CN,
    'zh_HK': ZH_HK,
    'zh_TW': ZH_TW,
    'en': EN,
    'en_US': EN,
}

ORDER = PLAIN + list(ARGS.keys())


def build(locale):
    vals = LOCALES[locale]
    lines = []
    for k in ORDER:
        lines.append('  "%s": "%s",\n' % (k, vals[k]))
        if k in ARGS:
            ph = ARGS[k]
            lines.append('  "@%s": {\n' % k)
            lines.append('    "placeholders": {\n')
            lines.append('      "%s": {\n' % ph)
            lines.append('        "type": "String"\n')
            lines.append('      }\n')
            lines.append('    }\n')
            lines.append('  },\n')
    # 最后一项不能带尾逗号（后面就是 arb 的收尾 }）
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"favWidgetPickTitle"' in ln for ln in lines):
        print('skip', locale)
        continue
    idx = None
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '}':
            idx = i
            break
    assert idx is not None, locale
    prev = idx - 1
    while prev >= 0 and not lines[prev].strip():
        prev -= 1
    if not lines[prev].rstrip('\n').rstrip().endswith(','):
        lines[prev] = lines[prev].rstrip('\n') + ',\n'
    lines[idx:idx] = build(locale)
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)
    print('ok', locale)
