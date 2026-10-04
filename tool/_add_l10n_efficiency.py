# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「Windows 效率模式」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_efficiency.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'prefPerfSection',
    'prefEfficiencyMode',
    'prefEfficiencyModeSub',
    'prefEfficiencyModeUnsupported',
]

ZH_CN = {
    'prefPerfSection': '性能',
    'prefEfficiencyMode': '效率模式',
    'prefEfficiencyModeSub': '按系统低功耗档调度本应用（EcoQoS），后台挂机更省电，前台操作会略慢',
    'prefEfficiencyModeUnsupported': '当前系统不支持效率模式',
}

ZH_HK = {
    'prefPerfSection': '效能',
    'prefEfficiencyMode': '效率模式',
    'prefEfficiencyModeSub': '按系統低功耗檔調度本應用（EcoQoS），後台掛機更省電，前台操作會略慢',
    'prefEfficiencyModeUnsupported': '目前系統不支援效率模式',
}

ZH_TW = {
    'prefPerfSection': '效能',
    'prefEfficiencyMode': '效率模式',
    'prefEfficiencyModeSub': '依系統低功耗檔調度本應用（EcoQoS），背景掛機更省電，前景操作會略慢',
    'prefEfficiencyModeUnsupported': '目前系統不支援效率模式',
}

EN = {
    'prefPerfSection': 'Performance',
    'prefEfficiencyMode': 'Efficiency mode',
    'prefEfficiencyModeSub': 'Schedule this app at the low power tier (EcoQoS). Saves battery when idling in the background, foreground feels slightly slower.',
    'prefEfficiencyModeUnsupported': 'Efficiency mode is not supported on this system',
}

LOCALES = {
    'zh_CN': ZH_CN,
    'zh': ZH_CN,
    'zh_HK': ZH_HK,
    'zh_TW': ZH_TW,
    'en': EN,
    'en_US': EN,
}


def build(locale):
    vals = LOCALES[locale]
    lines = []
    for k in PLAIN:
        lines.append('  "%s": "%s",\n' % (k, vals[k]))
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"prefEfficiencyMode"' in ln for ln in lines):
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
