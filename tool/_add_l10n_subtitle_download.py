# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「字幕下载」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_subtitle_download.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'subtitleDownloadAll',
    'subtitleDownloadPickDir',
    'subtitleDownloadNone',
    'subtitleDownloadAllFailed',
]

# key -> placeholder 名（按顺序）
ARGS = {
    'subtitleDownloadDone': ('count', 'dir'),
}

ZH_CN = {
    'subtitleDownloadAll': '下载全部字幕',
    'subtitleDownloadPickDir': '选择字幕保存目录',
    'subtitleDownloadDone': '已保存 {count} 条字幕到 {dir}',
    'subtitleDownloadNone': '当前视频没有可下载的字幕',
    'subtitleDownloadAllFailed': '字幕下载失败',
}

ZH_HK = {
    'subtitleDownloadAll': '下載全部字幕',
    'subtitleDownloadPickDir': '選擇字幕儲存目錄',
    'subtitleDownloadDone': '已儲存 {count} 條字幕到 {dir}',
    'subtitleDownloadNone': '目前影片沒有可下載的字幕',
    'subtitleDownloadAllFailed': '字幕下載失敗',
}

ZH_TW = dict(ZH_HK)
ZH_TW['subtitleDownloadPickDir'] = '選擇字幕儲存目錄'

EN = {
    'subtitleDownloadAll': 'Download all subtitles',
    'subtitleDownloadPickDir': 'Choose where to save subtitles',
    'subtitleDownloadDone': 'Saved {count} subtitle files to {dir}',
    'subtitleDownloadNone': 'No subtitles available for this video',
    'subtitleDownloadAllFailed': 'Subtitle download failed',
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
            lines.append('  "@%s": {\n' % k)
            lines.append('    "placeholders": {\n')
            for ph in ARGS[k]:
                lines.append('      "%s": {\n' % ph)
                lines.append('        "type": "String"\n')
                lines.append('      },\n')
            # 最后一个 placeholder 不能有尾逗号
            lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
            lines.append('    }\n')
            lines.append('  },\n')
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"subtitleDownloadAll"' in ln for ln in lines):
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
