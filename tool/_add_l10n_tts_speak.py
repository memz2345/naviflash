# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「朗读入口」（专栏 / 评论）相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_tts_speak.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

# 注意：英文值里不能有撇号（'），会炸 Dart 单引号字符串。
PLAIN = [
    'ttsReadAloud',
    'ttsReadAloudStop',
    'ttsSynthesizing',
]

ARGS = {
    'ttsSpeakFailed': 'error',
}

ZH_CN = {
    'ttsReadAloud': '朗读',
    'ttsReadAloudStop': '停止朗读',
    'ttsSynthesizing': '正在合成语音…',
    'ttsSpeakFailed': '朗读失败：{error}',
}

ZH_HK = {
    'ttsReadAloud': '朗讀',
    'ttsReadAloudStop': '停止朗讀',
    'ttsSynthesizing': '正在合成語音…',
    'ttsSpeakFailed': '朗讀失敗：{error}',
}

ZH_TW = {
    'ttsReadAloud': '朗讀',
    'ttsReadAloudStop': '停止朗讀',
    'ttsSynthesizing': '正在合成語音…',
    'ttsSpeakFailed': '朗讀失敗：{error}',
}

EN = {
    'ttsReadAloud': 'Read aloud',
    'ttsReadAloudStop': 'Stop',
    'ttsSynthesizing': 'Synthesizing speech...',
    'ttsSpeakFailed': 'Read-aloud failed: {error}',
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

    def ln(text):
        return text + '\r\n'

    for k in ORDER:
        lines.append(ln('  "%s": "%s",' % (k, vals[k])))
        if k in ARGS:
            for ph in ([ARGS[k]] if isinstance(ARGS[k], str) else ARGS[k]):
                lines.append(ln('  "@%s": {' % k))
                lines.append(ln('    "placeholders": {'))
                lines.append(ln('      "%s": {' % ph))
                lines.append(ln('        "type": "String"'))
                lines.append(ln('      }'))
                lines.append(ln('    }'))
                lines.append(ln('  },'))
    last = lines[-1].rstrip('\r\n').rstrip(',')
    lines[-1] = last + '\r\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"ttsReadAloud"' in ln for ln in lines):
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
    if not lines[prev].rstrip('\r\n').rstrip().endswith(','):
        lines[prev] = lines[prev].rstrip('\r\n') + ',\r\n'
    lines[idx:idx] = build(locale)
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)
    print('ok', locale)
