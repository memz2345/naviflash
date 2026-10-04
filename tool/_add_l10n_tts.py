# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「AI 朗读（Qwen3-TTS）」相关文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_tts.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

# 注意：英文值里不能有撇号（'），会炸 Dart 单引号字符串。
PLAIN = [
    'ttsSection',
    'ttsModelLabel',
    'ttsDesc',
    'ttsNotInstalled',
    'ttsPartial',
    'ttsSizeCounting',
    'ttsDownload',
    'ttsResume',
    'ttsUninstall',
    'ttsUninstallTitle',
    'ttsUninstalled',
    'ttsInstallDone',
    'ttsUnsupported',
    'ttsSourceTitle',
    'ttsSourceDesc',
    'ttsSourceSaved',
    'ttsMirrorOfficial',
    'ttsMirrorChina',
    'ttsMirrorCustom',
    'ttsEngineIdle',
    'ttsEngineLoading',
    'ttsEngineReady',
    'ttsEngineUnload',
    'ttsEngineUnloaded',
    'ttsNeedInstall',
    'ttsRuntimePending',
    'ttsVoTitle',
    'ttsVoDesc',
    'ttsVoEmpty',
    'ttsVoPick',
    'ttsVoAdded',
    'ttsVoDeleteTitle',
    'ttsVoDeleted',
    'ttsVoDefault',
    'ttsVoUse',
    'ttsPickAudioTitle',
    'ttsVoUnsupportedFile',
]

# key -> placeholder 名（单个）或名字列表（多个）
ARGS = {
    'ttsInstalled': 'size',
    'ttsDownloading': 'percent',
    'ttsDownloadingFile': ['percent', 'name'],
    'ttsUninstallConfirm': 'size',
    'ttsFailed': 'error',
    'ttsVoPickFailed': 'error',
    'ttsVoDeleteConfirm': 'name',
    'ttsVoCount': 'count',
}

ZH_CN = {
    'ttsSection': 'AI 朗读引擎',
    'ttsModelLabel': 'Qwen3-TTS 0.6B',
    'ttsDesc': '用 AI 朗读专栏、动态和评论，支持声音克隆。模型不随安装包提供，首次使用需下载约 1.2GB。',
    'ttsNotInstalled': '未下载',
    'ttsPartial': '下载不完整，继续下载即可补全',
    'ttsSizeCounting': '计算中…',
    'ttsInstalled': '已下载 · {size}',
    'ttsDownload': '下载',
    'ttsResume': '继续下载',
    'ttsDownloading': '下载中 {percent}',
    'ttsDownloadingFile': '下载中 {percent} · {name}',
    'ttsUninstall': '删除',
    'ttsUninstallTitle': '删除 AI 朗读引擎？',
    'ttsUninstallConfirm': '将删除模型文件（{size}）。删除后 AI 朗读不可用，需要时可重新下载。',
    'ttsUninstalled': '已删除 AI 朗读引擎',
    'ttsInstallDone': '下载完成，AI 朗读已可用',
    'ttsFailed': '下载失败：{error}',
    'ttsUnsupported': '当前平台不支持 AI 朗读',
    'ttsSourceTitle': '下载源',
    'ttsSourceDesc': '访问不了 HuggingFace 时切换到镜像站，或填写自定义地址',
    'ttsSourceSaved': '下载源已更新',
    'ttsMirrorOfficial': 'HuggingFace 官方',
    'ttsMirrorChina': 'hf-mirror 镜像站（国内推荐）',
    'ttsMirrorCustom': '自定义地址',
    'ttsEngineIdle': '未加载，点击朗读时自动加载',
    'ttsEngineLoading': '正在加载朗读引擎…',
    'ttsEngineReady': '引擎已就绪',
    'ttsEngineUnload': '释放引擎',
    'ttsEngineUnloaded': '已释放引擎，下次朗读时重新加载',
    'ttsNeedInstall': '请先在「设置 → 存储」中下载 AI 朗读引擎',
    'ttsRuntimePending': '模型已就绪，推理运行时尚未接入',
    'ttsVoTitle': '音色（声音克隆）',
    'ttsVoDesc': '选一段 3-15 秒的清晰人声，朗读时会用它说话',
    'ttsVoEmpty': '未设置，使用默认音色',
    'ttsVoCount': '已保存 {count} 个音色',
    'ttsVoPick': '选择音频',
    'ttsVoPickFailed': '读取音频失败：{error}',
    'ttsVoAdded': '音色已添加',
    'ttsVoDeleteTitle': '删除音色？',
    'ttsVoDeleteConfirm': '将删除音色「{name}」。',
    'ttsVoDeleted': '音色已删除',
    'ttsVoDefault': '默认音色',
    'ttsVoUse': '使用',
    'ttsPickAudioTitle': '选择音色音频',
    'ttsVoUnsupportedFile': '请选择一个音频文件',
}

ZH_HK = {
    'ttsSection': 'AI 朗讀引擎',
    'ttsModelLabel': 'Qwen3-TTS 0.6B',
    'ttsDesc': '用 AI 朗讀專欄、動態和評論，支援聲音克隆。模型不隨安裝包提供，首次使用需下載約 1.2GB。',
    'ttsNotInstalled': '未下載',
    'ttsPartial': '下載不完整，繼續下載即可補全',
    'ttsSizeCounting': '計算中…',
    'ttsInstalled': '已下載 · {size}',
    'ttsDownload': '下載',
    'ttsResume': '繼續下載',
    'ttsDownloading': '下載中 {percent}',
    'ttsDownloadingFile': '下載中 {percent} · {name}',
    'ttsUninstall': '刪除',
    'ttsUninstallTitle': '刪除 AI 朗讀引擎？',
    'ttsUninstallConfirm': '將刪除模型檔案（{size}）。刪除後 AI 朗讀不可用，需要時可重新下載。',
    'ttsUninstalled': '已刪除 AI 朗讀引擎',
    'ttsInstallDone': '下載完成，AI 朗讀已可用',
    'ttsFailed': '下載失敗：{error}',
    'ttsUnsupported': '目前平台不支援 AI 朗讀',
    'ttsSourceTitle': '下載來源',
    'ttsSourceDesc': '連不上 HuggingFace 時切換到鏡像站，或填寫自訂位址',
    'ttsSourceSaved': '下載來源已更新',
    'ttsMirrorOfficial': 'HuggingFace 官方',
    'ttsMirrorChina': 'hf-mirror 鏡像站（推薦）',
    'ttsMirrorCustom': '自訂位址',
    'ttsEngineIdle': '未載入，點擊朗讀時自動載入',
    'ttsEngineLoading': '正在載入朗讀引擎…',
    'ttsEngineReady': '引擎已就緒',
    'ttsEngineUnload': '釋放引擎',
    'ttsEngineUnloaded': '已釋放引擎，下次朗讀時重新載入',
    'ttsNeedInstall': '請先在「設定 → 儲存」中下載 AI 朗讀引擎',
    'ttsRuntimePending': '模型已就緒，推論執行環境尚未接入',
    'ttsVoTitle': '音色（聲音克隆）',
    'ttsVoDesc': '選一段 3-15 秒的清晰人聲，朗讀時會用它說話',
    'ttsVoEmpty': '未設定，使用預設音色',
    'ttsVoCount': '已儲存 {count} 個音色',
    'ttsVoPick': '選擇音訊',
    'ttsVoPickFailed': '讀取音訊失敗：{error}',
    'ttsVoAdded': '音色已新增',
    'ttsVoDeleteTitle': '刪除音色？',
    'ttsVoDeleteConfirm': '將刪除音色「{name}」。',
    'ttsVoDeleted': '音色已刪除',
    'ttsVoDefault': '預設音色',
    'ttsVoUse': '使用',
    'ttsPickAudioTitle': '選擇音色音訊',
    'ttsVoUnsupportedFile': '請選擇一個音訊檔案',
}

ZH_TW = {
    'ttsSection': 'AI 朗讀引擎',
    'ttsModelLabel': 'Qwen3-TTS 0.6B',
    'ttsDesc': '用 AI 朗讀專欄、動態和評論，支援聲音複製。模型不隨安裝包提供，首次使用需下載約 1.2GB。',
    'ttsNotInstalled': '未下載',
    'ttsPartial': '下載不完整，繼續下載即可補齊',
    'ttsSizeCounting': '計算中…',
    'ttsInstalled': '已下載 · {size}',
    'ttsDownload': '下載',
    'ttsResume': '繼續下載',
    'ttsDownloading': '下載中 {percent}',
    'ttsDownloadingFile': '下載中 {percent} · {name}',
    'ttsUninstall': '刪除',
    'ttsUninstallTitle': '刪除 AI 朗讀引擎？',
    'ttsUninstallConfirm': '將刪除模型檔案（{size}）。刪除後 AI 朗讀不可用，需要時可重新下載。',
    'ttsUninstalled': '已刪除 AI 朗讀引擎',
    'ttsInstallDone': '下載完成，AI 朗讀已可用',
    'ttsFailed': '下載失敗：{error}',
    'ttsUnsupported': '目前平台不支援 AI 朗讀',
    'ttsSourceTitle': '下載來源',
    'ttsSourceDesc': '連不上 HuggingFace 時切換到鏡像站，或填寫自訂位址',
    'ttsSourceSaved': '下載來源已更新',
    'ttsMirrorOfficial': 'HuggingFace 官方',
    'ttsMirrorChina': 'hf-mirror 鏡像站（推薦）',
    'ttsMirrorCustom': '自訂位址',
    'ttsEngineIdle': '未載入，點擊朗讀時自動載入',
    'ttsEngineLoading': '正在載入朗讀引擎…',
    'ttsEngineReady': '引擎就緒',
    'ttsEngineUnload': '釋放引擎',
    'ttsEngineUnloaded': '已釋放引擎，下次朗讀時重新載入',
    'ttsNeedInstall': '請先在「設定 → 儲存空間」中下載 AI 朗讀引擎',
    'ttsRuntimePending': '模型已就緒，推論執行環境尚未接入',
    'ttsVoTitle': '音色（聲音複製）',
    'ttsVoDesc': '選一段 3-15 秒的清晰人聲，朗讀時會用它說話',
    'ttsVoEmpty': '未設定，使用預設音色',
    'ttsVoCount': '已儲存 {count} 個音色',
    'ttsVoPick': '選擇音訊',
    'ttsVoPickFailed': '讀取音訊失敗：{error}',
    'ttsVoAdded': '音色已新增',
    'ttsVoDeleteTitle': '刪除音色？',
    'ttsVoDeleteConfirm': '將刪除音色「{name}」。',
    'ttsVoDeleted': '音色已刪除',
    'ttsVoDefault': '預設音色',
    'ttsVoUse': '使用',
    'ttsPickAudioTitle': '選擇音色音訊',
    'ttsVoUnsupportedFile': '請選擇一個音訊檔案',
}

EN = {
    'ttsSection': 'AI read-aloud engine',
    'ttsModelLabel': 'Qwen3-TTS 0.6B',
    'ttsDesc': 'Read articles, posts and comments aloud with voice cloning. The model is not bundled with the app and needs a one-time 1.2 GB download.',
    'ttsNotInstalled': 'Not downloaded',
    'ttsPartial': 'Download is incomplete, resume to finish it',
    'ttsSizeCounting': 'Calculating...',
    'ttsInstalled': 'Downloaded · {size}',
    'ttsDownload': 'Download',
    'ttsResume': 'Resume',
    'ttsDownloading': 'Downloading {percent}',
    'ttsDownloadingFile': 'Downloading {percent} · {name}',
    'ttsUninstall': 'Delete',
    'ttsUninstallTitle': 'Delete the read-aloud engine?',
    'ttsUninstallConfirm': 'This deletes the model files ({size}). Read-aloud stops working until you download them again.',
    'ttsUninstalled': 'Read-aloud engine deleted',
    'ttsInstallDone': 'Download complete. Read-aloud is ready.',
    'ttsFailed': 'Download failed: {error}',
    'ttsUnsupported': 'Read-aloud is not supported on this platform',
    'ttsSourceTitle': 'Download source',
    'ttsSourceDesc': 'Switch to a mirror if HuggingFace is unreachable, or enter a custom address',
    'ttsSourceSaved': 'Download source updated',
    'ttsMirrorOfficial': 'HuggingFace official',
    'ttsMirrorChina': 'hf-mirror (recommended in China)',
    'ttsMirrorCustom': 'Custom address',
    'ttsEngineIdle': 'Not loaded, loads on first read-aloud',
    'ttsEngineLoading': 'Loading the read-aloud engine...',
    'ttsEngineReady': 'Engine ready',
    'ttsEngineUnload': 'Release engine',
    'ttsEngineUnloaded': 'Engine released, it reloads on the next read-aloud',
    'ttsNeedInstall': 'Download the read-aloud engine first: Settings, then Storage.',
    'ttsRuntimePending': 'Model is ready, the inference runtime is not wired up yet',
    'ttsVoTitle': 'Voice (cloning)',
    'ttsVoDesc': 'Pick 3 to 15 seconds of clear speech and read-aloud will use that voice',
    'ttsVoEmpty': 'Not set, using the default voice',
    'ttsVoCount': '{count} voices saved',
    'ttsVoPick': 'Pick audio',
    'ttsVoPickFailed': 'Could not read the audio: {error}',
    'ttsVoAdded': 'Voice added',
    'ttsVoDeleteTitle': 'Delete this voice?',
    'ttsVoDeleteConfirm': 'This deletes the voice: {name}.',
    'ttsVoDeleted': 'Voice deleted',
    'ttsVoDefault': 'Default voice',
    'ttsVoUse': 'Use',
    'ttsPickAudioTitle': 'Pick a voice sample',
    'ttsVoUnsupportedFile': 'Please pick an audio file',
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
    # 仓库里的 arb 是 CRLF，新增行保持同一风格，避免 git 整批报换行符变更
    def ln(text):
        return text + '\r\n'

    for k in ORDER:
        lines.append(ln('  "%s": "%s",' % (k, vals[k])))
        if k in ARGS:
            raw = ARGS[k]
            names = raw if isinstance(raw, list) else [raw]
            lines.append(ln('  "@%s": {' % k))
            lines.append(ln('    "placeholders": {'))
            for i, ph in enumerate(names):
                last = i == len(names) - 1
                lines.append(ln('      "%s": {' % ph))
                # JSON 对象最后一个属性后不能有逗号，逗号挂在收尾 } 之后
                lines.append(ln('        "type": "String"'))
                lines.append(ln('      }%s' % ('' if last else ',')))
            lines.append(ln('    }'))
            lines.append(ln('  },'))
    # 最后一项不能带尾逗号（它后面就是 arb 的收尾 }）
    last = lines[-1].rstrip('\r\n').rstrip(',')
    lines[-1] = last + '\r\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"ttsSection"' in ln for ln in lines):
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
    if not lines[prev].rstrip('\r\n').rstrip().endswith(','):
        lines[prev] = lines[prev].rstrip('\r\n') + ',\r\n'
    lines[idx:idx] = build(locale)
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)
    print('ok', locale)
