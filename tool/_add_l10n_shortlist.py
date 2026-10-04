# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「短视频底栏 / 更多面板 / lite 空间 / 听视频」相关文案。

用法：python tool/_add_l10n_shortlist.py
"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n'
)

PLAIN = [
    'videoMorePanelTitle',
    'memberLiteTitle',
    'memberLiteViewFull',
    'memberLiteEmpty',
    'audioPageTitle',
    'audioPageSpeed',
    'audioPageRetry',
    'playerListenPage',
    'playerOnlyPlayAudioInline',
]

ARGS = {
    'memberLiteVideoCount': 'count',
}

ZH_CN = {
    'commonClose': '关闭',
    'videoMorePanelTitle': '更多',
    'memberLiteTitle': 'UP 主',
    'memberLiteVideoCount': '共 {count} 个视频',
    'memberLiteViewFull': '查看原版主页',
    'memberLiteEmpty': '暂无视频',
    'audioPageTitle': '听视频',
    'audioPageSpeed': '倍速',
    'audioPageRetry': '重新加载',
    'playerListenPage': '听视频',
    'playerOnlyPlayAudioInline': '仅播放音频（留在当前页）',
}

ZH_HK = {
    'commonClose': '關閉',
    'videoMorePanelTitle': '更多',
    'memberLiteTitle': 'UP 主',
    'memberLiteVideoCount': '共 {count} 個影片',
    'memberLiteViewFull': '查看原版主頁',
    'memberLiteEmpty': '暫無影片',
    'audioPageTitle': '聽影片',
    'audioPageSpeed': '倍速',
    'audioPageRetry': '重新載入',
    'playerListenPage': '聽影片',
    'playerOnlyPlayAudioInline': '僅播放音訊（留在目前頁面）',
}

ZH_TW = dict(ZH_HK)

EN = {
    'commonClose': 'Close',
    'videoMorePanelTitle': 'More',
    'memberLiteTitle': 'Uploader',
    'memberLiteVideoCount': '{count} videos',
    'memberLiteViewFull': 'Open full profile',
    'memberLiteEmpty': 'No videos yet',
    'audioPageTitle': 'Listen',
    'audioPageSpeed': 'Speed',
    'audioPageRetry': 'Retry',
    'playerListenPage': 'Listen to audio',
    'playerOnlyPlayAudioInline': 'Audio only (stay here)',
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
    if any('"memberLiteTitle"' in ln for ln in lines):
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
