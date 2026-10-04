# -*- coding: utf-8 -*-
"""第七轮：截图对话框（复制到剪贴板）文案。"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n'
)

PLAIN = [
    'screenshotCopy',
    'screenshotCopied',
    'screenshotCopyUnsupported',
]

ZH_CN = {
    'screenshotCopy': '复制到剪贴板',
    'screenshotCopied': '已复制到剪贴板',
    'screenshotCopyUnsupported': '当前平台不支持复制图片到剪贴板',
}

ZH_HK = {
    'screenshotCopy': '複製到剪貼簿',
    'screenshotCopied': '已複製到剪貼簿',
    'screenshotCopyUnsupported': '目前平台不支援複製圖片到剪貼簿',
}

ZH_TW = dict(ZH_HK)
ZH_TW['screenshotCopyUnsupported'] = '目前平台不支援複製圖片到剪貼簿'

EN = {
    'screenshotCopy': 'Copy to clipboard',
    'screenshotCopied': 'Copied to clipboard',
    'screenshotCopyUnsupported':
        'Copying images to the clipboard is not supported on this platform',
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
    lines = ['  "%s": "%s",\n' % (k, vals[k]) for k in PLAIN]
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"screenshotCopy"' in ln for ln in lines):
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
