# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「智能防遮挡依赖」相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_onnx.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

# (key, 是否参数化, {locale: value})
# 注意：英文值里不能有撇号（'），会炸 Dart 单引号字符串。
PLAIN = [
    'onnxDepSection',
    'onnxDepDesc',
    'onnxDepNotInstalled',
    'onnxDepSizeCounting',
    'onnxDepDownload',
    'onnxDepUninstall',
    'onnxDepUninstallTitle',
    'onnxDepUninstalled',
    'onnxDepInstallDone',
    'onnxDepUnsupported',
    'onnxDepSourceTitle',
    'onnxDepSourceDesc',
    'onnxDepNeedInstall',
    'onnxDepSourceSaved',
]

# key -> (placeholder 名)
ARGS = {
    'onnxDepInstalled': 'size',
    'onnxDepDownloading': 'percent',
    'onnxDepUninstallConfirm': 'size',
    'onnxDepFailed': 'error',
}

ZH_CN = {
    'onnxDepSection': '智能防遮挡依赖',
    'onnxDepDesc': '弹幕智能防遮挡需要 ONNX Runtime 运行库与识别模型，两者默认不随安装包提供',
    'onnxDepNotInstalled': '未安装',
    'onnxDepSizeCounting': '计算中…',
    'onnxDepInstalled': '已安装 · {size}',
    'onnxDepDownload': '下载',
    'onnxDepDownloading': '下载中 {percent}',
    'onnxDepUninstall': '卸载',
    'onnxDepUninstallTitle': '卸载智能防遮挡依赖？',
    'onnxDepUninstallConfirm': '将删除运行库与识别模型（{size}）。之后智能防遮挡不可用，需要时可重新下载。',
    'onnxDepUninstalled': '已卸载智能防遮挡依赖',
    'onnxDepInstallDone': '安装完成，智能防遮挡已可用',
    'onnxDepFailed': '下载失败：{error}',
    'onnxDepUnsupported': '当前平台不支持智能防遮挡',
    'onnxDepSourceTitle': '下载源',
    'onnxDepSourceDesc': '自定义下载地址，留空使用内置默认源',
    'onnxDepNeedInstall': '请先在「设置 → 存储」中下载智能防遮挡依赖',
    'onnxDepSourceSaved': '下载源已更新',
}

ZH_HK = {
    'onnxDepSection': '智能防遮擋依賴',
    'onnxDepDesc': '彈幕智能防遮擋需要 ONNX Runtime 執行庫與識別模型，兩者預設不隨安裝包提供',
    'onnxDepNotInstalled': '未安裝',
    'onnxDepSizeCounting': '計算中…',
    'onnxDepInstalled': '已安裝 · {size}',
    'onnxDepDownload': '下載',
    'onnxDepDownloading': '下載中 {percent}',
    'onnxDepUninstall': '卸載',
    'onnxDepUninstallTitle': '卸載智能防遮擋依賴？',
    'onnxDepUninstallConfirm': '將刪除執行庫與識別模型（{size}）。之後智能防遮擋不可用，需要時可重新下載。',
    'onnxDepUninstalled': '已卸載智能防遮擋依賴',
    'onnxDepInstallDone': '安裝完成，智能防遮擋已可用',
    'onnxDepFailed': '下載失敗：{error}',
    'onnxDepUnsupported': '目前平台不支援智能防遮擋',
    'onnxDepSourceTitle': '下載來源',
    'onnxDepSourceDesc': '自訂下載位址，留空使用內建預設來源',
    'onnxDepNeedInstall': '請先在「設定 → 儲存」中下載智能防遮擋依賴',
    'onnxDepSourceSaved': '下載來源已更新',
}

ZH_TW = dict(ZH_HK)
ZH_TW['onnxDepUnsupported'] = '目前平台不支援智慧防遮擋'
ZH_TW['onnxDepSection'] = '智慧防遮擋依賴'
ZH_TW['onnxDepDesc'] = '彈幕智慧防遮擋需要 ONNX Runtime 執行庫與識別模型，兩者預設不隨安裝包提供'
ZH_TW['onnxDepUninstallTitle'] = '卸載智慧防遮擋依賴？'
ZH_TW['onnxDepUninstallConfirm'] = '將刪除執行庫與識別模型（{size}）。之後智慧防遮擋不可用，需要時可重新下載。'
ZH_TW['onnxDepUninstalled'] = '已卸載智慧防遮擋依賴'
ZH_TW['onnxDepInstallDone'] = '安裝完成，智慧防遮擋已可用'
ZH_TW['onnxDepNeedInstall'] = '請先在「設定 → 儲存」中下載智慧防遮擋依賴'

EN = {
    'onnxDepSection': 'Smart danmaku mask',
    'onnxDepDesc': 'Smart danmaku masking needs the ONNX Runtime library and a segmentation model. Neither is bundled with the installer.',
    'onnxDepNotInstalled': 'Not installed',
    'onnxDepSizeCounting': 'Calculating…',
    'onnxDepInstalled': 'Installed · {size}',
    'onnxDepDownload': 'Download',
    'onnxDepDownloading': 'Downloading {percent}',
    'onnxDepUninstall': 'Uninstall',
    'onnxDepUninstallTitle': 'Remove smart mask files?',
    'onnxDepUninstallConfirm': 'This deletes the runtime library and the model ({size}). Smart masking stops working until you download them again.',
    'onnxDepUninstalled': 'Smart mask files removed',
    'onnxDepInstallDone': 'Installed. Smart danmaku masking is ready.',
    'onnxDepFailed': 'Download failed: {error}',
    'onnxDepUnsupported': 'Smart danmaku masking is not supported on this platform',
    'onnxDepSourceTitle': 'Download source',
    'onnxDepSourceDesc': 'Custom download URL. Leave empty to use the built-in default.',
    'onnxDepNeedInstall': 'Download the smart mask files first: Settings, then Storage.',
    'onnxDepSourceSaved': 'Download source updated',
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
            lines.append('        "type": "String"\n')
            lines.append('      }\n')
            lines.append('    }\n')
            lines.append('  },\n')
    # 最后一项不能带尾逗号（它后面就是 arb 的收尾 }）
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"onnxDepSection"' in ln for ln in lines):
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
