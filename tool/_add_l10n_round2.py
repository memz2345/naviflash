# -*- coding: utf-8 -*-
"""第二轮：lite 空间「前往空间」+ PiliPlus 式评论排序（描述 / 短标签）。"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n'
)

PLAIN = [
    'memberLiteGoSpace',
    'commentSortLatestDesc',
    'commentSortHottestDesc',
    'commentSortLatestShort',
    'commentSortHottestShort',
    'memberLiteOrderPubdate',
    'memberLiteOrderClick',
]

ZH_CN = {
    'memberLiteGoSpace': '前往空间',
    'commentSortLatestDesc': '最新评论',
    'commentSortHottestDesc': '最热评论',
    'commentSortLatestShort': '最新',
    'commentSortHottestShort': '最热',
    'memberLiteOrderPubdate': '最新发布',
    'memberLiteOrderClick': '最多播放',
}

ZH_HK = {
    'memberLiteGoSpace': '前往空間',
    'commentSortLatestDesc': '最新評論',
    'commentSortHottestDesc': '最熱評論',
    'commentSortLatestShort': '最新',
    'commentSortHottestShort': '最熱',
    'memberLiteOrderPubdate': '最新發佈',
    'memberLiteOrderClick': '最多播放',
}

ZH_TW = dict(ZH_HK)
ZH_TW['memberLiteOrderPubdate'] = '最新發布'

EN = {
    'memberLiteGoSpace': 'Go to space',
    'commentSortLatestDesc': 'Newest comments',
    'commentSortHottestDesc': 'Top comments',
    'commentSortLatestShort': 'Newest',
    'commentSortHottestShort': 'Top',
    'memberLiteOrderPubdate': 'Latest',
    'memberLiteOrderClick': 'Most played',
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
    if any('"memberLiteGoSpace"' in ln for ln in lines):
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
