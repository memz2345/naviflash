# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「播放列表倒序播放」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_playlist_reverse.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'playlistReversePlay',
    'playlistReversePlayOn',
    'playlistReversePlayOff',
]

ZH_CN = {
    'playlistReversePlay': '倒序播放',
    'playlistReversePlayOn': '已开启倒序播放',
    'playlistReversePlayOff': '已关闭倒序播放',
}

ZH_HK = {
    'playlistReversePlay': '倒序播放',
    'playlistReversePlayOn': '已開啟倒序播放',
    'playlistReversePlayOff': '已關閉倒序播放',
}

ZH_TW = {
    'playlistReversePlay': '倒序播放',
    'playlistReversePlayOn': '已開啟倒序播放',
    'playlistReversePlayOff': '已關閉倒序播放',
}

EN = {
    'playlistReversePlay': 'Reverse play',
    'playlistReversePlayOn': 'Reverse play on',
    'playlistReversePlayOff': 'Reverse play off',
}

LOCALES = {
    'zh_CN': ZH_CN,
    'zh': ZH_CN,
    'zh_HK': ZH_HK,
    'zh_TW': ZH_TW,
    'en': EN,
    'en_US': EN,
}

ORDER = list(PLAIN)


def build(locale):
    vals = LOCALES[locale]
    lines = []
    for k in ORDER:
        lines.append('  "%s": "%s",\n' % (k, vals[k]))
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"playlistReversePlay"' in ln for ln in lines):
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
