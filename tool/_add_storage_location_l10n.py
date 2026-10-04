# 一次性脚本：给 6 个 arb 插入「存储位置」区块文案 + TTS 实时通知标题。
# 锚点：storageAllCleared 行之后插入；每个文件断言锚点唯一。
import io
import os
import sys

ROOT = r"F:\f\naviflashv2\lib\l10n"

def ph(name):
    return '"@%s": { "placeholders": { "%s": { "type": "String" } } }' % (name, name)

def block(kv, meta):
    lines = []
    for k, v in kv:
        lines.append('  "%s": %s,' % (k, v))
        if k in meta:
            lines.append('  %s,' % ph(k))
    return "\n".join(lines)

COMMON_META = {"storageLocationCurrent", "storageLocationSetDone", "storageLocationFree"}

ZH_CN = [
    ("storageLocationSection", '"存储位置"'),
    ("storageLocationAutoCache", '"自动缓存位置"'),
    ("storageLocationAutoCacheDesc", '"播放缓存 / 图片 / 弹幕 / 专栏等自动缓存的落盘位置"'),
    ("storageLocationVideo", '"视频下载位置"'),
    ("storageLocationVideoDesc", '"主动「缓存」的离线视频落盘位置"'),
    ("storageLocationModels", '"AI 模型位置"'),
    ("storageLocationModelsDesc", '"AI 朗读模型与智能防遮挡依赖"'),
    ("storageLocationDefault", '"跟随系统默认"'),
    ("storageLocationUnsupported", '"当前平台不支持自定义"'),
    ("storageLocationChoose", '"更改"'),
    ("storageLocationPick", '"选择目录"'),
    ("storageLocationNewFolder", '"新建子文件夹"'),
    ("storageLocationFolderName", '"文件夹名称"'),
    ("storageLocationCreateFailed", '"创建失败，换一个名字试试"'),
    ("storageLocationReset", '"恢复默认"'),
    ("storageLocationResetDone", '"已恢复默认位置"'),
    ("storageLocationCurrent", '"当前：{path}"'),
    ("storageLocationSetDone", '"已设置为 {path}"'),
    ("storageLocationFree", '"可用 {size}"'),
    ("storageLocationNotWritable", '"该目录不可写，已回退默认位置"'),
    ("storageLocationAndroidHint", '"安卓只能在系统给定的标准目录（电影 / 下载 / 文档等，含外置 SD 卡）与应用私有目录中选择，可在其下新建子文件夹"'),
    ("storageLocationKeepOld", '"切换后旧位置的文件保留、仍可读取，新下载写入新位置"'),
    ("ttsLiveDownloadTitle", '"AI 朗读模型下载"'),
]

EN = [
    ("storageLocationSection", '"Storage locations"'),
    ("storageLocationAutoCache", '"Auto cache location"'),
    ("storageLocationAutoCacheDesc", '"Where playback cache, images, danmaku and articles are stored"'),
    ("storageLocationVideo", '"Video download location"'),
    ("storageLocationVideoDesc", '"Where videos you cache manually are saved"'),
    ("storageLocationModels", '"AI models location"'),
    ("storageLocationModelsDesc", '"AI narration models and the anti-occlusion dependency"'),
    ("storageLocationDefault", '"System default"'),
    ("storageLocationUnsupported", '"Not customizable on this platform"'),
    ("storageLocationChoose", '"Change"'),
    ("storageLocationPick", '"Choose folder"'),
    ("storageLocationNewFolder", '"New subfolder"'),
    ("storageLocationFolderName", '"Folder name"'),
    ("storageLocationCreateFailed", '"Could not create it, try another name"'),
    ("storageLocationReset", '"Reset to default"'),
    ("storageLocationResetDone", '"Reset to the default location"'),
    ("storageLocationCurrent", '"Current: {path}"'),
    ("storageLocationSetDone", '"Set to {path}"'),
    ("storageLocationFree", '"{size} available"'),
    ("storageLocationNotWritable", '"Not writable, fell back to the default location"'),
    ("storageLocationAndroidHint", '"On Android you can only pick the system standard folders (Movies, Download, Documents, also on the SD card) or the app private folder, and create subfolders inside them"'),
    ("storageLocationKeepOld", '"Files in the old location are kept and still readable; new downloads go to the new one"'),
    ("ttsLiveDownloadTitle", '"AI narration model download"'),
]

ZH_TW = [
    ("storageLocationSection", '"儲存位置"'),
    ("storageLocationAutoCache", '"自動快取位置"'),
    ("storageLocationAutoCacheDesc", '"播放快取 / 圖片 / 彈幕 / 專欄等自動快取的落盤位置"'),
    ("storageLocationVideo", '"影片下載位置"'),
    ("storageLocationVideoDesc", '"主動「快取」的離線影片落盤位置"'),
    ("storageLocationModels", '"AI 模型位置"'),
    ("storageLocationModelsDesc", '"AI 朗讀模型與智慧防遮擋依賴"'),
    ("storageLocationDefault", '"跟隨系統預設"'),
    ("storageLocationUnsupported", '"目前平台不支援自訂"'),
    ("storageLocationChoose", '"變更"'),
    ("storageLocationPick", '"選擇資料夾"'),
    ("storageLocationNewFolder", '"新增子資料夾"'),
    ("storageLocationFolderName", '"資料夾名稱"'),
    ("storageLocationCreateFailed", '"建立失敗，換個名稱試試"'),
    ("storageLocationReset", '"恢復預設"'),
    ("storageLocationResetDone", '"已恢復預設位置"'),
    ("storageLocationCurrent", '"目前：{path}"'),
    ("storageLocationSetDone", '"已設為 {path}"'),
    ("storageLocationFree", '"可用 {size}"'),
    ("storageLocationNotWritable", '"此目錄無法寫入，已退回預設位置"'),
    ("storageLocationAndroidHint", '"安卓只能在系統提供的標準目錄（電影 / 下載 / 文件等，含外接 SD 卡）與 App 私有目錄中選擇，並可在其中新增子資料夾"'),
    ("storageLocationKeepOld", '"切換後舊位置的檔案會保留、仍可讀取，新下載寫入新位置"'),
    ("ttsLiveDownloadTitle", '"AI 朗讀模型下載"'),
]

ZH_HK = [
    ("storageLocationSection", '"儲存位置"'),
    ("storageLocationAutoCache", '"自動緩存位置"'),
    ("storageLocationAutoCacheDesc", '"播放緩存 / 圖片 / 彈幕 / 專欄等自動緩存的落盤位置"'),
    ("storageLocationVideo", '"影片下載位置"'),
    ("storageLocationVideoDesc", '"主動「緩存」的離線影片落盤位置"'),
    ("storageLocationModels", '"AI 模型位置"'),
    ("storageLocationModelsDesc", '"AI 朗讀模型與智能防遮擋依賴"'),
    ("storageLocationDefault", '"跟隨系統預設"'),
    ("storageLocationUnsupported", '"目前平台不支援自訂"'),
    ("storageLocationChoose", '"變更"'),
    ("storageLocationPick", '"選擇資料夾"'),
    ("storageLocationNewFolder", '"新增子資料夾"'),
    ("storageLocationFolderName", '"資料夾名稱"'),
    ("storageLocationCreateFailed", '"建立失敗，換個名稱試試"'),
    ("storageLocationReset", '"恢復預設"'),
    ("storageLocationResetDone", '"已恢復預設位置"'),
    ("storageLocationCurrent", '"目前：{path}"'),
    ("storageLocationSetDone", '"已設為 {path}"'),
    ("storageLocationFree", '"可用 {size}"'),
    ("storageLocationNotWritable", '"此目錄無法寫入，已退回預設位置"'),
    ("storageLocationAndroidHint", '"安卓只能在系統提供的標準目錄（電影 / 下載 / 文件等，含外接 SD 卡）與 App 私有目錄中選擇，並可在其中新增子資料夾"'),
    ("storageLocationKeepOld", '"切換後舊位置的檔案會保留、仍可讀取，新下載寫入新位置"'),
    ("ttsLiveDownloadTitle", '"AI 朗讀模型下載"'),
]

TARGETS = [
    ("app_zh_CN.arb", ZH_CN),
    ("app_zh.arb", ZH_CN),
    ("app_zh_TW.arb", ZH_TW),
    ("app_zh_HK.arb", ZH_HK),
    ("app_en.arb", EN),
    ("app_en_US.arb", EN),
]

for name, kv in TARGETS:
    path = os.path.join(ROOT, name)
    with io.open(path, "r", encoding="utf-8") as f:
        text = f.read()
    anchor = '"storageAllCleared":'
    assert text.count(anchor) == 1, "anchor not unique in %s" % name
    for k, _ in kv:
        assert ('"%s":' % k) not in text, "%s already has %s" % (name, k)
    out = []
    for line in text.split("\n"):
        out.append(line)
        if anchor in line:
            out.append(block(kv, COMMON_META))
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    print("patched", name)
