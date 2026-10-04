# -*- coding: utf-8 -*-
"""恢复被误回滚的 7 个 l10n key（userPicker* × 5 + shorts* × 2）。

背景：为了修 _add_l10n_tts.py 的 JSON 逗号 bug 执行过 `git checkout -- *.arb`，
把上一轮会话**未提交**的 arb 改动一起回滚了。简体原文已用 cat -A 的字节流
还原，繁体/英文按同义重建（可能与原文有个别用词差异）。

用法：python tool/_restore_l10n_lost.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

KEYS = [
    'userPickerTitle',
    'userPickerSearchHint',
    'userPickerEmpty',
    'userPickerLoadFailed',
    'userPickerDone',
    'shortsTitle',
    'shortsEmpty',
]

ZH_CN = {
    'userPickerTitle': '选择用户',
    'userPickerSearchHint': '搜索我的关注',
    'userPickerEmpty': '没有找到用户',
    'userPickerLoadFailed': '加载失败',
    'userPickerDone': '完成',
    'shortsTitle': '短视频',
    'shortsEmpty': '暂时没有内容',
}

ZH_HK = {
    'userPickerTitle': '選擇用戶',
    'userPickerSearchHint': '搜尋我的關注',
    'userPickerEmpty': '找不到用戶',
    'userPickerLoadFailed': '載入失敗',
    'userPickerDone': '完成',
    'shortsTitle': '短影片',
    'shortsEmpty': '暫時沒有內容',
}

ZH_TW = {
    'userPickerTitle': '選擇使用者',
    'userPickerSearchHint': '搜尋我的關注',
    'userPickerEmpty': '找不到使用者',
    'userPickerLoadFailed': '載入失敗',
    'userPickerDone': '完成',
    'shortsTitle': '短影片',
    'shortsEmpty': '暫時沒有內容',
}

EN = {
    'userPickerTitle': 'Select users',
    'userPickerSearchHint': 'Search my follows',
    'userPickerEmpty': 'No users found',
    'userPickerLoadFailed': 'Failed to load',
    'userPickerDone': 'Done',
    'shortsTitle': 'Shorts',
    'shortsEmpty': 'Nothing here yet',
}

LOCALES = {
    'zh_CN': ZH_CN,
    'zh': ZH_CN,
    'zh_HK': ZH_HK,
    'zh_TW': ZH_TW,
    'en': EN,
    'en_US': EN,
}

for locale, vals in LOCALES.items():
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"shortsTitle"' in ln for ln in lines):
        print('skip', locale)
        continue

    block = ['  "%s": "%s",\r\n' % (k, vals[k]) for k in KEYS]

    # 插到 tts 区块之前，尽量贴近原来的 key 顺序
    pos = None
    for i, ln in enumerate(lines):
        if '"ttsSection"' in ln:
            pos = i
            break
    if pos is None:
        # 没有 tts 块就插到文件末尾的 } 之前
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip() == '}':
                pos = i
                break
        prev = pos - 1
        while prev >= 0 and not lines[prev].strip():
            prev -= 1
        if not lines[prev].rstrip('\r\n').rstrip().endswith(','):
            lines[prev] = lines[prev].rstrip('\r\n') + ',\r\n'
    lines[pos:pos] = block
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)
    print('ok', locale)
