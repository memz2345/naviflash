# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「效率模式状态」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_efficiency_status.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'prefEfficiencyModeReading',
    'prefEfficiencyModeActive',
    'prefEfficiencyModeInactive',
]

ARGS = {
    'prefEfficiencyModeFailed': 'detail',
}

ZH_CN = {
    'prefEfficiencyModeReading': '读取中…',
    'prefEfficiencyModeActive': '已生效 · 进程按低功耗档调度',
    'prefEfficiencyModeInactive': '未生效',
    'prefEfficiencyModeFailed': '效率模式未能生效（{detail}）',
}

ZH_HK = {
    'prefEfficiencyModeReading': '讀取中…',
    'prefEfficiencyModeActive': '已生效 · 程序按低功耗檔調度',
    'prefEfficiencyModeInactive': '未生效',
    'prefEfficiencyModeFailed': '效率模式未能生效（{detail}）',
}

ZH_TW = {
    'prefEfficiencyModeReading': '讀取中…',
    'prefEfficiencyModeActive': '已生效 · 程式依低功耗檔調度',
    'prefEfficiencyModeInactive': '未生效',
    'prefEfficiencyModeFailed': '效率模式未能生效（{detail}）',
}

EN = {
    'prefEfficiencyModeReading': 'Reading…',
    'prefEfficiencyModeActive': 'Active · scheduled at the low power tier',
    'prefEfficiencyModeInactive': 'Not active',
    'prefEfficiencyModeFailed': 'Efficiency mode did not take effect ({detail})',
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
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"prefEfficiencyModeActive"' in ln for ln in lines):
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
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.writelines(lines)
    print('ok', locale)
