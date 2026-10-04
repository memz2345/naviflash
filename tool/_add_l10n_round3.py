# -*- coding: utf-8 -*-
"""第三轮：视频页「更多」菜单扩充（PiliPlus 菜单里本项目已实现的能力）。"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n'
)

PLAIN = [
    'videoMenuWatchLater',
    'videoMenuReload',
    'playerMenuStats',
    'playerMenuScreenshot',
    'playerMenuAudioNorm',
    'playerMenuAudioDevice',
    'playerMenuSource',
    'playerMenuEndBehavior',
]

ZH_CN = {
    'videoMenuWatchLater': '稍后再看',
    'videoMenuReload': '重新加载',
    'playerMenuStats': '播放信息',
    'playerMenuScreenshot': '截图',
    'playerMenuAudioNorm': '音量均衡',
    'playerMenuAudioDevice': '音频输出设备',
    'playerMenuSource': '换源',
    'playerMenuEndBehavior': '播放顺序',
}

ZH_HK = {
    'videoMenuWatchLater': '稍後再看',
    'videoMenuReload': '重新載入',
    'playerMenuStats': '播放資訊',
    'playerMenuScreenshot': '截圖',
    'playerMenuAudioNorm': '音量均衡',
    'playerMenuAudioDevice': '音訊輸出裝置',
    'playerMenuSource': '換源',
    'playerMenuEndBehavior': '播放順序',
}

ZH_TW = dict(ZH_HK)
ZH_TW['playerMenuAudioDevice'] = '音訊輸出裝置'
ZH_TW['videoMenuWatchLater'] = '稍後再看'

EN = {
    'videoMenuWatchLater': 'Watch later',
    'videoMenuReload': 'Reload',
    'playerMenuStats': 'Playback info',
    'playerMenuScreenshot': 'Screenshot',
    'playerMenuAudioNorm': 'Volume normalization',
    'playerMenuAudioDevice': 'Audio output device',
    'playerMenuSource': 'Switch CDN',
    'playerMenuEndBehavior': 'Play order',
}

LOCALES = {
    'zh_CN': ZH_CN,
    'zh': ZH_CN,
    'zh_HK': ZH_HK,
    'zh_TW': ZH_TW,
    'en': EN,
    'en_US': EN,
}


def build(locale):
    vals = LOCALES[locale]
    lines = ['  "%s": "%s",\n' % (k, vals[k]) for k in PLAIN]
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"videoMenuWatchLater"' in ln for ln in lines):
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
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)
    print('ok', locale)
