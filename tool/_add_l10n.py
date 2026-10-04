import io, os

BASE = r'F:\f\nv_tmp'
ROOT = r'F:\f\naviflashv2\lib\l10n'

KEYS = [
    'bottomNavSettingsTitle',
    'bottomNavSettingsSubtitle',
    'bottomNavItemHome',
    'bottomNavItemDynamics',
    'bottomNavItemLive',
    'bottomNavSettingsReset',
    'bottomNavSettingsKeepOne',
]

VALUES = {
    'zh_CN': [
        '底栏导航',
        '拖动调整顺序（第一个为启动时的默认页），取消勾选可隐藏',
        '首页',
        '动态',
        '直播',
        '重置',
        '至少保留一个导航项',
    ],
    'zh': [
        '底栏导航',
        '拖动调整顺序（第一个为启动时的默认页），取消勾选可隐藏',
        '首页',
        '动态',
        '直播',
        '重置',
        '至少保留一个导航项',
    ],
    'zh_HK': [
        '底欄導航',
        '拖動調整順序（第一個為啟動時的預設頁），取消勾選可隱藏',
        '首頁',
        '動態',
        '直播',
        '重設',
        '至少保留一個導航項',
    ],
    'zh_TW': [
        '底欄導航',
        '拖動調整順序（第一個為啟動時的預設頁），取消勾選可隱藏',
        '首頁',
        '動態',
        '直播',
        '重設',
        '至少保留一個導航項',
    ],
    'en': [
        'Bottom navigation',
        'Drag to reorder (the first item opens on launch), uncheck to hide',
        'Home',
        'Dynamics',
        'Live',
        'Reset',
        'Keep at least one item',
    ],
    'en_US': [
        'Bottom navigation',
        'Drag to reorder (the first item opens on launch), uncheck to hide',
        'Home',
        'Dynamics',
        'Live',
        'Reset',
        'Keep at least one item',
    ],
}

# ---- 1. arb 文件 ----
for locale, vals in VALUES.items():
    path = os.path.join(ROOT, f'app_{locale}.arb')
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any(f'"{KEYS[0]}"' in ln for ln in lines):
        print('skip arb', locale)
        continue
    out = []
    done = False
    for ln in lines:
        out.append(ln)
        if not done and '"searchHistoryEmpty"' in ln:
            if not ln.rstrip('\n').rstrip().endswith(','):
                out[-1] = ln.rstrip('\n') + ',\n'
            for k, v in zip(KEYS, vals):
                out.append(f'  "{k}": "{v}",\n')
            done = True
    assert done, locale
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(out)
    print('arb ok', locale)

# ---- 2. abstract 声明 ----
path = os.path.join(ROOT, 'app_localizations.dart')
with io.open(path, encoding='utf-8') as f:
    lines = f.readlines()
if not any(f'String get {KEYS[0]};' in ln for ln in lines):
    out = []
    done = False
    for ln in lines:
        out.append(ln)
        if not done and 'String get searchHistoryEmpty;' in ln:
            for k in KEYS:
                out.append(f'  /// No description provided for @{k}.\n')
                out.append(f'  String get {k};\n')
            done = True
    assert done
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(out)
    print('abstract ok')

# ---- 3. 实现类 ----
IMPL = [
    ('app_localizations_zh.dart', [
        ('zh', VALUES['zh']),
        ('zh_CN', VALUES['zh_CN']),
        ('zh_HK', VALUES['zh_HK']),
        ('zh_TW', VALUES['zh_TW']),
    ]),
    ('app_localizations_en.dart', [
        ('en', VALUES['en']),
        ('en_US', VALUES['en_US']),
    ]),
]

for fname, locales in IMPL:
    path = os.path.join(ROOT, fname)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any(f'String get {KEYS[0]} =>' in ln for ln in lines):
        print('skip impl', fname)
        continue
    # 按顺序为每个 locale 类插入（文件里类顺序与 locales 顺序一致）
    out = []
    idx = 0
    for ln in lines:
        out.append(ln)
        if idx < len(locales) and 'String get searchHistoryEmpty =>' in ln:
            for k, v in zip(KEYS, locales[idx][1]):
                out.append(f"  String get {k} => '{v}';\n")
            idx += 1
    assert idx == len(locales), (fname, idx)
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(out)
    print('impl ok', fname)
