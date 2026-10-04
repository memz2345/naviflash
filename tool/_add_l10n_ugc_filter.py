# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「UGC 过滤设置」文案（含带占位符的条目），随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_ugc_filter.py

幂等：已经存在的 key 跳过（方便追加新文案时重复执行）。
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

ANCHOR = '  "settingsLanguageSub":'

# key -> (zh_CN, zh, zh_TW, zh_HK, en, en_US)
PLAIN = {
    # ── TTS 下载：后台 / 断点 ──
    'ttsDownloadCancel': ('取消下载', '取消下载', '取消下載', '取消下載',
                          'Cancel download', 'Cancel download'),
    'ttsDownloadDoneTitle': ('AI 朗读模型下载完成', 'AI 朗读模型下载完成',
                             'AI 朗讀模型下載完成', 'AI 朗讀模型下載完成',
                             'TTS model downloaded', 'TTS model downloaded'),
    'ttsDownloadDoneBody': ('现在可以在评论和专栏里点朗读了（下载支持断点与后台，中途退出不用重来）。',
                            '现在可以在评论和专栏里点朗读了（下载支持断点与后台，中途退出不用重来）。',
                            '現在可以在評論和專欄裡點朗讀了（下載支援斷點與背景，中途退出不用重來）。',
                            '現在可以在評論和專欄裡點朗讀了（下載支援斷點與背景，中途退出不用重來）。',
                            'You can now use read-aloud in comments and articles. Downloads resume and keep running in the background.',
                            'You can now use read-aloud in comments and articles. Downloads resume and keep running in the background.'),
    # ── TTS 未安装：原生任务对话框 + 下载页 ──
    'ttsNoInstallTitle': ('AI 朗读', 'AI 朗读', 'AI 朗讀', 'AI 朗讀',
                          'Read aloud', 'Read aloud'),
    'ttsNoInstallHeading': ('还没有安装TTS，您希望怎么做？', '还没有安装TTS，您希望怎么做？',
                            '還沒有安裝 TTS，您希望怎麼做？', '還沒有安裝 TTS，您希望怎麼做？',
                            'TTS is not installed yet. What would you like to do?',
                            'TTS is not installed yet. What would you like to do?'),
    'ttsNoInstallDownload': ('下载TTS', '下载TTS', '下載 TTS', '下載 TTS',
                             'Download TTS', 'Download TTS'),
    'ttsNoInstallDownloadSub': ('从 Hugging Face 拉取模型', '从 Hugging Face 拉取模型',
                                '從 Hugging Face 拉取模型', '從 Hugging Face 拉取模型',
                                'Pull the model from Hugging Face',
                                'Pull the model from Hugging Face'),
    'ttsNoInstallLater': ('算了吧', '算了吧', '算了吧', '算了吧',
                          'Never mind', 'Never mind'),
    'ttsNoInstallLaterSub': ('下次再说!', '下次再说!', '下次再說！', '下次再說！',
                             'Maybe later', 'Maybe later'),
    'ttsInstallPageTitle': ('下载 AI 朗读模型', '下载 AI 朗读模型', '下載 AI 朗讀模型',
                            '下載 AI 朗讀模型', 'Download the TTS model',
                            'Download the TTS model'),
    'ugcFilterWindowTitle': ('查找和替换', '查找和替换', '尋找與取代', '尋找與取代',
                             'Find and Replace', 'Find and Replace'),
    'ugcFilterResultPrefix': ('搜索结果：', '搜索结果：', '搜尋結果：', '搜尋結果：',
                              'Results: ', 'Results: '),
    'ugcFilterDeleteMatchesPlain': ('删除匹配项', '删除匹配项', '刪除匹配項',
                                    '刪除匹配項', 'Delete matches',
                                    'Delete matches'),
    'ugcFilterTitle': ('过滤设置', '过滤设置', '過濾設定', '過濾設定',
                       'Filter settings', 'Filter settings'),
    'ugcFilterSectionScopes': ('UGC 关键词过滤', 'UGC 关键词过滤',
                               'UGC 關鍵詞過濾', 'UGC 關鍵詞過濾',
                               'UGC keyword filters', 'UGC keyword filters'),
    'ugcFilterScopeRecommend': ('首页推荐', '首页推荐', '首頁推薦', '首頁推薦',
                                'Home feed', 'Home feed'),
    'ugcFilterScopeRecommendSub': ('命中标题的视频不显示', '命中标题的视频不显示',
                                   '命中標題的影片不顯示', '命中標題的影片不顯示',
                                   'Hide videos whose title matches',
                                   'Hide videos whose title matches'),
    'ugcFilterScopeZone': ('视频分区', '视频分区', '影片分區', '影片分區',
                           'Zones', 'Zones'),
    'ugcFilterScopeZoneSub': ('只作用于 App 端推荐 / 热门 / 排行榜',
                              '只作用于 App 端推荐 / 热门 / 排行榜',
                              '只作用於 App 端推薦 / 熱門 / 排行榜',
                              '只作用於 App 端推薦 / 熱門 / 排行榜',
                              'Applies to the app feed, popular and ranking only',
                              'Applies to the app feed, popular and ranking only'),
    'ugcFilterScopeReply': ('评论', '评论', '評論', '評論', 'Comments', 'Comments'),
    'ugcFilterScopeReplySub': ('命中正文的评论不显示', '命中正文的评论不显示',
                               '命中正文的評論不顯示', '命中正文的評論不顯示',
                               'Hide comments whose content matches',
                               'Hide comments whose content matches'),
    'ugcFilterScopeDyn': ('动态', '动态', '動態', '動態', 'Dynamics', 'Dynamics'),
    'ugcFilterScopeDynSub': ('命中正文的动态不显示', '命中正文的动态不显示',
                             '命中正文的動態不顯示', '命中正文的動態不顯示',
                             'Hide dynamics whose content matches',
                             'Hide dynamics whose content matches'),
    'ugcFilterEmpty': ('还没有关键词，在上面输入后点「添加」',
                       '还没有关键词，在上面输入后点「添加」',
                       '還沒有關鍵詞，在上方輸入後點「新增」',
                       '還沒有關鍵詞，在上方輸入後點「新增」',
                       'No keywords yet; type above and tap Add',
                       'No keywords yet; type above and tap Add'),
    'ugcFilterAddHint': ('关键词或正则', '关键词或正则', '關鍵詞或正規表達式',
                         '關鍵詞或正規表達式', 'Keyword or regex', 'Keyword or regex'),
    'ugcFilterAdd': ('添加', '添加', '新增', '新增', 'Add', 'Add'),
    'ugcFilterEdit': ('编辑关键词', '编辑关键词', '編輯關鍵詞', '編輯關鍵詞',
                      'Edit keyword', 'Edit keyword'),
    'ugcFilterDelete': ('删除', '删除', '刪除', '刪除', 'Delete', 'Delete'),
    'ugcFilterClear': ('清空全部', '清空全部', '清空全部', '清空全部',
                       'Clear all', 'Clear all'),
    'ugcFilterDup': ('已存在，跳过', '已存在，跳过', '已存在，跳過', '已存在，跳過',
                     'Already exists, skipped', 'Already exists, skipped'),
    'ugcFilterInvalid': ('不是合法正则表达式', '不是合法正则表达式',
                         '不是合法的正規表達式', '不是合法的正規表達式',
                         'Not a valid regular expression',
                         'Not a valid regular expression'),
    'ugcFilterDeleted': ('已删除', '已删除', '已刪除', '已刪除', 'Deleted', 'Deleted'),
    'ugcFilterCleared': ('已清空', '已清空', '已清空', '已清空', 'Cleared', 'Cleared'),
    'ugcFilterNoResult': ('没有匹配项', '没有匹配项', '沒有匹配項', '沒有匹配項',
                          'No match', 'No match'),
    'ugcFilterMenuMore': ('更多', '更多', '更多', '更多', 'More', 'More'),
    'ugcFilterMenuClipboard': ('从剪贴板导入', '从剪贴板导入', '從剪貼簿匯入',
                               '從剪貼簿匯入', 'Import from clipboard',
                               'Import from clipboard'),
    'ugcFilterMenuFile': ('从文件导入', '从文件导入', '從檔案匯入', '從檔案匯入',
                          'Import from file', 'Import from file'),
    'ugcFilterMenuExport': ('导出', '导出', '匯出', '匯出', 'Export', 'Export'),
    'ugcFilterMenuWebdav': ('导出到 WebDAV', '导出到 WebDAV', '匯出到 WebDAV',
                            '匯出到 WebDAV', 'Export to WebDAV', 'Export to WebDAV'),
    'ugcFilterImportEmpty': ('剪贴板里没有文本', '剪贴板里没有文本',
                             '剪貼簿裡沒有文字', '剪貼簿裡沒有文字',
                             'Clipboard has no text', 'Clipboard has no text'),
    'ugcFilterExportEmpty': ('没有可导出的关键词', '没有可导出的关键词',
                             '沒有可匯出的關鍵詞', '沒有可匯出的關鍵詞',
                             'Nothing to export', 'Nothing to export'),
    'ugcFilterFindReplace': ('查找替换', '查找替换', '尋找取代', '尋找取代',
                             'Find and replace', 'Find and replace'),
    'ugcFilterFind': ('查找', '查找', '尋找', '尋找', 'Find', 'Find'),
    'ugcFilterReplace': ('替换', '替换', '取代', '取代', 'Replace', 'Replace'),
    'ugcFilterPrev': ('上个', '上个', '上一個', '上一個', 'Previous', 'Previous'),
    'ugcFilterNext': ('下个', '下个', '下一個', '下一個', 'Next', 'Next'),
    'ugcFilterReplaceOne': ('替换', '替换', '取代', '取代', 'Replace', 'Replace'),
    'ugcFilterReplaceAll': ('全部', '全部', '全部', '全部', 'All', 'All'),
    'ugcFilterHistory': ('历史记录', '历史记录', '歷史紀錄', '歷史紀錄',
                         'History', 'History'),
    'ugcFilterClearHistory': ('清空查找历史', '清空查找历史', '清空尋找歷史',
                              '清空尋找歷史', 'Clear find history',
                              'Clear find history'),
    'ugcFilterCaseSensitive': ('区分大小写', '区分大小写', '區分大小寫', '區分大小寫',
                               'Case sensitive', 'Case sensitive'),
    'ugcFilterWholeWord': ('全词匹配（整条关键词一致）', '全词匹配（整条关键词一致）',
                           '全詞匹配（整條關鍵詞一致）', '全詞匹配（整條關鍵詞一致）',
                           'Whole keyword must match', 'Whole keyword must match'),
    'ugcFilterRegex': ('正则表达式', '正则表达式', '正規表達式', '正規表達式',
                       'Regular expression', 'Regular expression'),
    'ugcFilterTip': (
        '每条关键词都是一段正则表达式（忽略大小写）。Cc = 区分大小写，'
        'W = 整条关键词一致才算命中，.* = 查找框按正则处理。'
        '导入是合并去重（不会覆盖已有），导出是纯文本、每行一条。',
        '每条关键词都是一段正则表达式（忽略大小写）。Cc = 区分大小写，'
        'W = 整条关键词一致才算命中，.* = 查找框按正则处理。'
        '导入是合并去重（不会覆盖已有），导出是纯文本、每行一条。',
        '每條關鍵詞都是一段正規表達式（忽略大小寫）。Cc = 區分大小寫，'
        'W = 整條關鍵詞一致才算命中，.* = 尋找框按正規表達式處理。'
        '匯入是合併去重（不會覆蓋既有），匯出是純文字、每行一條。',
        '每條關鍵詞都是一段正規表達式（忽略大小寫）。Cc = 區分大小寫，'
        'W = 整條關鍵詞一致才算命中，.* = 尋找框按正規表達式處理。'
        '匯入是合併去重（不會覆蓋既有），匯出是純文字、每行一條。',
        'Every keyword is a regular expression (case-insensitive). '
        'Cc = case sensitive, W = the whole keyword must match, '
        '.* = treat the find field as a regex. Import merges and dedupes '
        '(nothing is overwritten); export is plain text, one per line.',
        'Every keyword is a regular expression (case-insensitive). '
        'Cc = case sensitive, W = the whole keyword must match, '
        '.* = treat the find field as a regex. Import merges and dedupes '
        '(nothing is overwritten); export is plain text, one per line.',
    ),
}

# key -> (placeholders: [(name, type)], values tuple)
PARAM = {
    'ugcFilterRulesCount': (
        [('count', 'int')],
        ('{count} 条', '{count} 条', '{count} 條', '{count} 條',
         '{count} rules', '{count} rules'),
    ),
    'ugcFilterAdded': (
        [('count', 'int')],
        ('已添加 {count} 条', '已添加 {count} 条', '已新增 {count} 條',
         '已新增 {count} 條', 'Added {count}', 'Added {count}'),
    ),
    'ugcFilterResultCount': (
        [('count', 'int')],
        ('搜索结果：{count}', '搜索结果：{count}', '搜尋結果：{count}',
         '搜尋結果：{count}', 'Results: {count}', 'Results: {count}'),
    ),
    'ugcFilterReplaced': (
        [('count', 'int')],
        ('已替换 {count} 条', '已替换 {count} 条', '已取代 {count} 條',
         '已取代 {count} 條', 'Replaced {count}', 'Replaced {count}'),
    ),
    'ugcFilterDeletedMatches': (
        [('count', 'int')],
        ('删除匹配项（{count}）', '删除匹配项（{count}）', '刪除匹配項（{count}）',
         '刪除匹配項（{count}）', 'Delete matches ({count})',
         'Delete matches ({count})'),
    ),
    'ugcFilterImported': (
        [('added', 'int'), ('skipped', 'int')],
        ('导入 {added} 条，重复 {skipped} 条', '导入 {added} 条，重复 {skipped} 条',
         '匯入 {added} 條，重複 {skipped} 條', '匯入 {added} 條，重複 {skipped} 條',
         'Imported {added}, skipped {skipped} duplicates',
         'Imported {added}, skipped {skipped} duplicates'),
    ),
    'ugcFilterImportFailed': (
        [('error', 'String')],
        ('导入失败：{error}', '导入失败：{error}', '匯入失敗：{error}',
         '匯入失敗：{error}', 'Import failed: {error}', 'Import failed: {error}'),
    ),
    'ugcFilterExportFailed': (
        [('error', 'String')],
        ('导出失败：{error}', '导出失败：{error}', '匯出失敗：{error}',
         '匯出失敗：{error}', 'Export failed: {error}', 'Export failed: {error}'),
    ),
    'ugcFilterWebdavOk': (
        [('name', 'String')],
        ('已上传到 WebDAV：{name}', '已上传到 WebDAV：{name}',
         '已上傳到 WebDAV：{name}', '已上傳到 WebDAV：{name}',
         'Uploaded to WebDAV: {name}', 'Uploaded to WebDAV: {name}'),
    ),
    'ugcFilterWebdavFail': (
        [('error', 'String')],
        ('上传失败：{error}', '上传失败：{error}', '上傳失敗：{error}',
         '上傳失敗：{error}', 'Upload failed: {error}', 'Upload failed: {error}'),
    ),
}

LOCALES = ('zh_CN', 'zh', 'zh_TW', 'zh_HK', 'en', 'en_US')


def patch(locale: str) -> None:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8', newline='') as f:
        raw = f.read()
    eol = '\r\n' if '\r\n' in raw else '\n'
    idx = LOCALES.index(locale)

    lines = []
    for key, values in PLAIN.items():
        value = values[idx]
        assert "'" not in value, 'arb 值不能含撇号: %s' % value
        assert '"' not in value, 'arb 值不能含双引号: %s' % value
        if '"%s"' % key in raw:
            continue
        lines.append('  "%s": "%s",' % (key, value))

    for key, (placeholders, values) in PARAM.items():
        value = values[idx]
        assert "'" not in value, 'arb 值不能含撇号: %s' % value
        assert '"' not in value, 'arb 值不能含双引号: %s' % value
        if '"%s"' % key in raw:
            continue
        lines.append('  "%s": "%s",' % (key, value))
        lines.append('  "@%s": {' % key)
        lines.append('    "placeholders": {')
        for i, (name, typ) in enumerate(placeholders):
            comma = ',' if i < len(placeholders) - 1 else ''
            lines.append('      "%s": {' % name)
            lines.append('        "type": "%s"' % typ)
            lines.append('      }%s' % comma)
        lines.append('    }')
        lines.append('  },')

    if not lines:
        print('-- %s (nothing to add)' % os.path.basename(path))
        return

    assert raw.count(ANCHOR) == 1, '锚点不唯一: %s' % path
    pos = raw.index(ANCHOR)
    line_end = raw.index(eol, pos)
    insert_at = line_end + len(eol)
    out = raw[:insert_at] + eol.join(lines) + eol + raw[insert_at:]

    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(out)
    print('OK %s (+%d lines)' % (os.path.basename(path), len(lines)))


if __name__ == '__main__':
    for loc in LOCALES:
        patch(loc)
