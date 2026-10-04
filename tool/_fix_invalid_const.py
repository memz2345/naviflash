# -*- coding: utf-8 -*-
"""迭代修掉 `Invalid constant value`：把真正包住该表达式的最近的 `const ` 去掉。

用法：python tool/_fix_invalid_const.py <analyze输出文件>
分析器每次只报一层，所以要反复跑，直到没有 invalid_constant。
"""
import io
import re
import sys
import collections

path = sys.argv[1]
text = io.open(path, encoding='utf-8', errors='replace').read()
errors = collections.defaultdict(set)
for ln in text.split('\n'):
    m = re.search(
        r'error - Invalid constant value - (.+?):(\d+):(\d+) - invalid_constant',
        ln,
    )
    if m:
        errors[m.group(1).replace('\\', '/')].add(
            (int(m.group(2)), int(m.group(3)))
        )


def line_starts(src):
    r = [0]
    for i, ch in enumerate(src):
        if ch == '\n':
            r.append(i + 1)
    return r


total = 0
for f, spots in errors.items():
    src = io.open(f, encoding='utf-8').read()
    removed = 0
    # 从文件底部往上处理，这样上面的位置不受已删字符影响
    for line, col in sorted(spots, reverse=True):
        ls = line_starts(src)
        if line - 1 >= len(ls):
            continue
        pos = ls[line - 1] + (col - 1)
        if pos > len(src):
            continue
        # 只考虑「同一行内、后面不是换行」的 const，避免删掉换行导致行号漂移
        cands = list(re.finditer(r'\bconst[ \t]+', src[:pos]))
        for m in reversed(cands):
            depth = 0
            i = m.end()
            while i < pos:
                c = src[i]
                if c in '([{':
                    depth += 1
                elif c in ')]}':
                    depth -= 1
                i += 1
            if depth > 0:
                src = src[: m.start()] + src[m.end() :]
                removed += 1
                break
    io.open(f, 'w', encoding='utf-8', newline='').write(src)
    print('%-60s removed %d const' % (f, removed))
    total += removed
print('total removed', total)
