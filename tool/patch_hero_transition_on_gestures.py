# -*- coding: utf-8 -*-
"""给 lib/ 下所有 Hero 补上 transitionOnUserGestures: true。

背景：Hero.transitionOnUserGestures 默认为 false —— 用户手势驱动的返回
（Android 预测式返回 / iOS 侧滑）默认**不会**触发 Hero 飞行，只有程序化的
push/pop 才飞。要让「视频打开/关闭动画」跟手，配对的 Hero 两端都必须显式
打开（见 flutter//widgets/heroes.dart 的 _allHeroesFor 与官方文档）。

用法：python tool/patch_hero_transition_on_gestures.py
"""
import io
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib')
CONSTRUCTOR = re.compile(r'(?<![\w.])Hero\(')
INSERTED = 'transitionOnUserGestures: true,'


def _line_is_commented(text, idx):
    line_start = text.rfind('\n', 0, idx) + 1
    return text[line_start:idx].lstrip().startswith('//')


def patch(text):
    i = 0
    changed = 0
    while True:
        m = CONSTRUCTOR.search(text, i)
        if m is None:
            break
        open_idx = m.end() - 1
        if _line_is_commented(text, m.start()):
            i = m.end()
            continue
        # 括号配平找参数列表结尾
        depth = 1
        j = open_idx + 1
        while j < len(text) and depth > 0:
            ch = text[j]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            j += 1
        args = text[open_idx + 1:j - 1]
        if 'transitionOnUserGestures' in args:
            i = j
            continue
        rest = text[open_idx + 1:]
        if rest.startswith('\n'):
            indent = re.match(r'\n([ \t]*)', rest).group(1) + '  '
            insert = '\n' + indent + INSERTED
        else:
            insert = INSERTED + ' '
        text = text[:open_idx + 1] + insert + text[open_idx + 1:]
        changed += 1
        i = open_idx + 1 + len(insert)
    return text, changed


total = 0
for dirpath, _dirnames, filenames in os.walk(ROOT):
    for name in filenames:
        if not name.endswith('.dart'):
            continue
        path = os.path.join(dirpath, name)
        with io.open(path, encoding='utf-8') as f:
            src = f.read()
        if 'Hero(' not in src:
            continue
        out, n = patch(src)
        if n == 0:
            continue
        with io.open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(out)
        total += n
        print('%3d  %s' % (n, os.path.relpath(path, os.path.join(ROOT, '..'))))
print('total:', total)
