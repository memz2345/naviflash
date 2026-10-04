import glob

files = sorted(glob.glob('lib/l10n/*.arb'))

repl = {
    '"切换为单列"': '"单列"',
    '"切换到多列"': '"多列"',
    '"切換為單欄"': '"單欄"',
    '"切換到多欄"': '"多欄"',
    '"Switch to single column"': '"Single column"',
    '"Switch to multi-column grid"': '"Multi-column"',
}

for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        s = fh.read()
    orig = s
    for a, b in repl.items():
        s = s.replace(a, b)
    if s != orig:
        with open(f, 'w', encoding='utf-8') as fh:
            fh.write(s)
        print('patched', f)
    else:
        print('no-change', f)
