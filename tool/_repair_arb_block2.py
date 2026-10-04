# tool/_repair_arb_block2.py
# 修复 _inject_l10n_block2.py 留下的坏 arb：注入块里每个条目缺尾逗号。
# 独立逗号行本身是合法 JSON 分隔符，不动；只给注入条目补尾逗号（末条除外）。
import io
import os
import re

ROOT = r'F:\f\naviflashv2\lib\l10n'

STANDALONE_COMMA = re.compile(r'^\s*,\s*$')
ENTRY = re.compile(r'^\s*"[^"]+":\s*"(?:[^"\\]|\\.)*"\s*$')
CLOSE = re.compile(r'^\s*}\s*$')

FILES = [
    'app_zh_CN.arb', 'app_zh.arb', 'app_zh_HK.arb', 'app_zh_TW.arb',
    'app_en.arb', 'app_en_US.arb',
]


def repair(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        raw = f.read()
    crlf = '\r\n' in raw
    eol = '\r\n' if crlf else '\n'
    lines = [ln.rstrip('\r') for ln in raw.split('\n')]

    j = None
    for i, ln in enumerate(lines):
        if STANDALONE_COMMA.match(ln):
            j = i
            break
    if j is None:
        print('skip (no broken block): ' + os.path.basename(path))
        return

    k = None
    for i in range(j + 1, len(lines)):
        if CLOSE.match(lines[i]):
            k = i
            break
    if k is None:
        print('ERROR no closing } after comma: ' + os.path.basename(path))
        return

    block = lines[j + 1:k]
    # 去掉可能的空行，只留条目
    entries = [ln for ln in block if ENTRY.match(ln)]
    if len(entries) != len([ln for ln in block if ln.strip() != '']):
        print('WARN blank/non-entry lines in block: ' + os.path.basename(path))
    new_entries = []
    for n, ln in enumerate(entries):
        comma = '' if n == len(entries) - 1 else ','
        new_entries.append(ln.rstrip() + comma)
    lines[j + 1:k] = new_entries

    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(eol.join(lines))
    print('repaired %d entries: %s' % (len(entries), os.path.basename(path)))


def main():
    for name in FILES:
        repair(os.path.join(ROOT, name))


if __name__ == '__main__':
    main()
