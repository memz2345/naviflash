# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「转场圆角自动适配屏幕」相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_device_corner.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

ANCHOR = '  "displayIosPushTransitionCorner":'

# key -> {locale: value}；locale 用 arb 文件名后缀
VALUES = {
    'displayIosPushTransitionCornerAuto': {
        'zh_CN': '自动适配屏幕圆角',
        'zh': '自动适配屏幕圆角',
        'zh_TW': '自動適配螢幕圓角',
        'zh_HK': '自動適配螢幕圓角',
        'en': 'Match screen corners',
        'en_US': 'Match screen corners',
    },
    'displayIosPushTransitionCornerUnsupported': {
        'zh_CN': '当前设备未提供屏幕圆角信息，使用下方手动值',
        'zh': '当前设备未提供屏幕圆角信息，使用下方手动值',
        'zh_TW': '目前裝置未提供螢幕圓角資訊，使用下方手動值',
        'zh_HK': '目前裝置未提供螢幕圓角資訊，使用下方手動值',
        'en': 'Screen corner radius unavailable, using the manual value below',
        'en_US': 'Screen corner radius unavailable, using the manual value below',
    },
}


def patch(locale: str) -> None:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8', newline='') as f:
        raw = f.read()
    eol = '\r\n' if '\r\n' in raw else '\n'

    lines = []
    for key, table in VALUES.items():
        value = table[locale]
        assert "'" not in value, 'arb 值不能含撇号: %s' % value
        lines.append('  "%s": "%s",' % (key, value))

    # 锚点必须在文件里唯一，且新 key 不能已存在
    assert raw.count(ANCHOR) == 1, '锚点不唯一: %s' % path
    for key in VALUES:
        assert '"%s"' % key not in raw, '%s 已存在 %s' % (path, key)

    idx = raw.index(ANCHOR)
    line_end = raw.index(eol, idx)
    insert_at = line_end + len(eol)
    out = raw[:insert_at] + eol.join(lines) + eol + raw[insert_at:]

    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(out)
    print('✅ %s' % os.path.basename(path))


if __name__ == '__main__':
    for loc in ('zh_CN', 'zh', 'zh_TW', 'zh_HK', 'en', 'en_US'):
        patch(loc)
