# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「睡眠定时器（定时关闭）」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_sleep_timer.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'sleepTimer',
    'sleepTimerCustom',
    'sleepTimerStopAfterCurrent',
    'sleepTimerStopAfterCurrentShort',
    'sleepTimerCancel',
    'sleepTimerArmedToast',
    'sleepTimerCancelledToast',
    'sleepTimerStopAfterCurrentArmedToast',
    'sleepTimerCustomDialogTitle',
    'sleepTimerCustomHint',
    'sleepTimerCustomUnit',
    'sleepTimerInvalidNumber',
    'settingsSleepTimerExitApp',
    'settingsSleepTimerExitAppDesc',
]

ARGS = {
    'sleepTimerMinutes': 'min',
}

ZH_CN = {
    'sleepTimer': '定时关闭',
    'sleepTimerMinutes': '{min} 分钟',
    'sleepTimerCustom': '自定义…',
    'sleepTimerStopAfterCurrent': '播完本集后暂停',
    'sleepTimerStopAfterCurrentShort': '播完本集',
    'sleepTimerCancel': '取消定时关闭',
    'sleepTimerArmedToast': '定时关闭已启动',
    'sleepTimerCancelledToast': '已取消定时关闭',
    'sleepTimerStopAfterCurrentArmedToast': '本集播完后将暂停播放',
    'sleepTimerCustomDialogTitle': '自定义定时关闭',
    'sleepTimerCustomHint': '分钟数',
    'sleepTimerCustomUnit': '分钟',
    'sleepTimerInvalidNumber': '请输入有效的分钟数',
    'settingsSleepTimerExitApp': '定时结束后退出应用',
    'settingsSleepTimerExitAppDesc': '到点暂停播放后退出 NaviFlash（桌面端生效）',
}

ZH_HK = {
    'sleepTimer': '定時關閉',
    'sleepTimerMinutes': '{min} 分鐘',
    'sleepTimerCustom': '自訂…',
    'sleepTimerStopAfterCurrent': '播完本集後暫停',
    'sleepTimerStopAfterCurrentShort': '播完本集',
    'sleepTimerCancel': '取消定時關閉',
    'sleepTimerArmedToast': '定時關閉已啟動',
    'sleepTimerCancelledToast': '已取消定時關閉',
    'sleepTimerStopAfterCurrentArmedToast': '本集播完後將暫停播放',
    'sleepTimerCustomDialogTitle': '自訂定時關閉',
    'sleepTimerCustomHint': '分鐘數',
    'sleepTimerCustomUnit': '分鐘',
    'sleepTimerInvalidNumber': '請輸入有效的分鐘數',
    'settingsSleepTimerExitApp': '定時結束後退出應用',
    'settingsSleepTimerExitAppDesc': '到點暫停播放後退出 NaviFlash（桌面端生效）',
}

ZH_TW = {
    'sleepTimer': '定時關閉',
    'sleepTimerMinutes': '{min} 分鐘',
    'sleepTimerCustom': '自訂…',
    'sleepTimerStopAfterCurrent': '播完本集後暫停',
    'sleepTimerStopAfterCurrentShort': '播完本集',
    'sleepTimerCancel': '取消定時關閉',
    'sleepTimerArmedToast': '定時關閉已啟動',
    'sleepTimerCancelledToast': '已取消定時關閉',
    'sleepTimerStopAfterCurrentArmedToast': '本集播完後將暫停播放',
    'sleepTimerCustomDialogTitle': '自訂定時關閉',
    'sleepTimerCustomHint': '分鐘數',
    'sleepTimerCustomUnit': '分鐘',
    'sleepTimerInvalidNumber': '請輸入有效的分鐘數',
    'settingsSleepTimerExitApp': '定時結束後結束應用',
    'settingsSleepTimerExitAppDesc': '到點暫停播放後結束 NaviFlash（桌面端生效）',
}

EN = {
    'sleepTimer': 'Sleep timer',
    'sleepTimerMinutes': '{min} min',
    'sleepTimerCustom': 'Custom…',
    'sleepTimerStopAfterCurrent': 'Pause after this episode',
    'sleepTimerStopAfterCurrentShort': 'after this episode',
    'sleepTimerCancel': 'Cancel sleep timer',
    'sleepTimerArmedToast': 'Sleep timer started',
    'sleepTimerCancelledToast': 'Sleep timer cancelled',
    'sleepTimerStopAfterCurrentArmedToast': 'Playback will pause after this episode',
    'sleepTimerCustomDialogTitle': 'Custom sleep timer',
    'sleepTimerCustomHint': 'Minutes',
    'sleepTimerCustomUnit': 'min',
    'sleepTimerInvalidNumber': 'Enter a valid number of minutes',
    'settingsSleepTimerExitApp': 'Quit app when timer ends',
    'settingsSleepTimerExitAppDesc': 'Pause playback when the timer fires, then quit NaviFlash (desktop only)',
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
            lines.append('        "type": "int"\n')
            lines.append('      }\n')
            lines.append('    }\n')
            lines.append('  },\n')
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"sleepTimerMinutes"' in ln for ln in lines):
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
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.writelines(lines)
    print('ok', locale)
