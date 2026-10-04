# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「开源许可页」相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_oss.py
注意：英文值里不能有撇号（'），会炸 Dart 单引号字符串。
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'ossSearchHint',
    'ossClearSearch',
    'ossDepsSection',
    'ossLoading',
    'ossLoadFailed',
    'ossEmptySearch',
    'ossRetry',
    'ossAppSection',
]

# key -> [(placeholder, type), ...]
ARGS = {
    'ossLicensesCount': [('count', 'int')],
    'ossLicenseIndex': [('index', 'int'), ('total', 'int')],
    'ossPackagesCount': [('total', 'int'), ('licenses', 'int')],
}

ZH_CN = {
    'ossSearchHint': '搜索包名或许可证',
    'ossClearSearch': '清除',
    'ossDepsSection': '第三方依赖',
    'ossLoading': '正在收集许可信息…',
    'ossLoadFailed': '未能读取许可清单，请稍后重试',
    'ossEmptySearch': '没有匹配的开源项目',
    'ossRetry': '重试',
    'ossAppSection': '本应用',
    'ossLicensesCount': '{count} 份许可',
    'ossLicenseIndex': '许可 {index} / {total}',
    'ossPackagesCount': '共 {total} 个开源包 · {licenses} 份许可文本',
}

ZH_HK = {
    'ossSearchHint': '搜尋套件名稱或授權條款',
    'ossClearSearch': '清除',
    'ossDepsSection': '第三方依賴',
    'ossLoading': '正在收集授權資訊…',
    'ossLoadFailed': '未能讀取授權清單，請稍後重試',
    'ossEmptySearch': '沒有符合的開放原始碼套件',
    'ossRetry': '重試',
    'ossAppSection': '本應用程式',
    'ossLicensesCount': '{count} 份授權',
    'ossLicenseIndex': '授權 {index} / {total}',
    'ossPackagesCount': '共 {total} 個開放原始碼套件 · {licenses} 份授權文字',
}

ZH_TW = dict(ZH_HK)
ZH_TW['ossEmptySearch'] = '沒有符合的開放原始碼專案'
ZH_TW['ossPackagesCount'] = '共 {total} 個開放原始碼專案 · {licenses} 份授權文字'

EN = {
    'ossSearchHint': 'Search packages',
    'ossClearSearch': 'Clear',
    'ossDepsSection': 'Third-party dependencies',
    'ossLoading': 'Collecting license information…',
    'ossLoadFailed': 'Could not read the license registry. Try again later.',
    'ossEmptySearch': 'No matching packages',
    'ossRetry': 'Retry',
    'ossAppSection': 'This app',
    'ossLicensesCount': '{count} licenses',
    'ossLicenseIndex': 'License {index} of {total}',
    'ossPackagesCount': '{total} packages · {licenses} license texts',
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
            phs = ARGS[k]
            for i, (ph, ty) in enumerate(phs):
                lines.append('      "%s": {\n' % ph)
                lines.append('        "type": "%s"\n' % ty)
                lines.append('      }%s\n' % (',' if i < len(phs) - 1 else ''))
            lines.append('    }\n')
            lines.append('  },\n')
    # 最后一项不能带尾逗号（它后面就是 arb 的收尾 }）
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"ossSearchHint"' in ln for ln in lines):
        print('skip', locale)
        continue
    # 最后一个 } 前插入，并给前一行的值补逗号
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
