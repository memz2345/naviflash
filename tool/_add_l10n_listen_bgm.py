# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「听视频 / BGM 入口」相关文案。

用法：python tool/_add_l10n_listen_bgm.py
注意：英文值里不能有撇号（'），会炸 Dart 单引号字符串。
"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n'
)

PLAIN = [
    'playerOnlyPlayAudio',
    'playerOnlyPlayAudioDesc',
]

# key -> placeholder 名
ARGS = {
    'videoBgmUsedCount': 'count',
}

ZH_CN = {
    'playerOnlyPlayAudio': '听视频',
    'playerOnlyPlayAudioDesc': '只播放声音，关闭画面（进度与倍速不受影响）',
    'videoBgmUsedCount': '{count} 个稿件使用',
}

ZH_HK = {
    'playerOnlyPlayAudio': '聽影片',
    'playerOnlyPlayAudioDesc': '只播放聲音，關閉畫面（進度與倍速不受影響）',
    'videoBgmUsedCount': '{count} 個稿件使用',
}

ZH_TW = {
    'playerOnlyPlayAudio': '聽影片',
    'playerOnlyPlayAudioDesc': '只播放聲音，關閉畫面（進度與倍速不受影響）',
    'videoBgmUsedCount': '{count} 個稿件使用',
}

EN = {
    'playerOnlyPlayAudio': 'Listen only',
    'playerOnlyPlayAudioDesc': 'Play sound only and hide the picture. Progress and speed are unaffected.',
    'videoBgmUsedCount': 'Used by {count} videos',
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
    if any('"playerOnlyPlayAudio"' in ln for ln in lines):
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
