# -*- coding: utf-8 -*-
"""从 6 个 arb 里删掉许可页改版后失去引用的文案键，随后跑 flutter gen-l10n。

被删的键（连同各自的 @ 占位符块）：
  ossSummary / ossAppSection / ossGroupCount / ossThanks

用法：python tool/_prune_l10n_oss.py
"""
import io
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')
DEAD = ('ossSummary', 'ossAppSection', 'ossGroupCount', 'ossThanks')
LOCALES = ('zh_CN', 'zh', 'zh_HK', 'zh_TW', 'en', 'en_US')

KEY_RE = re.compile(r'^  "(@?)([A-Za-z0-9_]+)":')


def prune(lines):
    out = []
    i = 0
    removed = []
    while i < len(lines):
        m = KEY_RE.match(lines[i])
        if m and m.group(2) in DEAD:
            key, is_meta = m.group(2), m.group(1) == '@'
            removed.append(key)
            i += 1
            # 值行后面常跟着 "@key": {...} 占位符块，整块一起吃掉
            if not is_meta and i < len(lines):
                nxt = KEY_RE.match(lines[i])
                if nxt and nxt.group(1) == '@' and nxt.group(2) == key:
                    while i < len(lines) and lines[i].rstrip('\n').rstrip() != '  },':
                        i += 1
                    i += 1  # 跳过 '  },'
            continue
        out.append(lines[i])
        i += 1
    return out, removed


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if not any(KEY_RE.match(ln) and KEY_RE.match(ln).group(2) in DEAD for ln in lines):
        print('skip', locale)
        continue
    pruned, removed = prune(lines)
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(pruned)
    print('ok', locale, '-> removed', sorted(set(removed)))
