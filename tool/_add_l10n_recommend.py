# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「推荐流设置」与「打开受支持的链接」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_recommend.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

ANCHOR = '  "settingsLanguageSub":'

# key -> {locale: value}；locale 用 arb 文件名后缀
VALUES = {
    # ── 设置入口 ──
    'settingsRecommend': {
        'zh_CN': '推荐流设置', 'zh': '推荐流设置',
        'zh_TW': '推薦流設定', 'zh_HK': '推薦流設定',
        'en': 'Recommend feed', 'en_US': 'Recommend feed',
    },
    'settingsRecommendSub': {
        'zh_CN': '推荐源、过滤器与刷新行为', 'zh': '推荐源、过滤器与刷新行为',
        'zh_TW': '推薦來源、過濾器與重新整理行為', 'zh_HK': '推薦來源、過濾器與重新整理行為',
        'en': 'Source, filters and refresh behaviour',
        'en_US': 'Source, filters and refresh behaviour',
    },
    # ── 推荐源 ──
    'rcmdSectionSource': {
        'zh_CN': '推荐源', 'zh': '推荐源',
        'zh_TW': '推薦來源', 'zh_HK': '推薦來源',
        'en': 'Source', 'en_US': 'Source',
    },
    'rcmdUseAppSource': {
        'zh_CN': '首页使用 App 端推荐', 'zh': '首页使用 App 端推荐',
        'zh_TW': '首頁使用 App 端推薦', 'zh_HK': '首頁使用 App 端推薦',
        'en': 'Use app-side recommendations',
        'en_US': 'Use app-side recommendations',
    },
    'rcmdUseAppSourceSub': {
        'zh_CN': '若 Web 端推荐不符预期，可切换至 App 端推荐',
        'zh': '若 Web 端推荐不符预期，可切换至 App 端推荐',
        'zh_TW': '若 Web 端推薦不符預期，可切換至 App 端推薦',
        'zh_HK': '若 Web 端推薦不符預期，可切換至 App 端推薦',
        'en': 'Switch to the app feed when the web feed disappoints',
        'en_US': 'Switch to the app feed when the web feed disappoints',
    },
    # ── 刷新与保留 ──
    'rcmdSectionBehavior': {
        'zh_CN': '刷新与保留', 'zh': '刷新与保留',
        'zh_TW': '重新整理與保留', 'zh_HK': '重新整理與保留',
        'en': 'Refresh and keep', 'en_US': 'Refresh and keep',
    },
    'rcmdKeepLastData': {
        'zh_CN': '保留首页推荐刷新', 'zh': '保留首页推荐刷新',
        'zh_TW': '保留首頁推薦重新整理', 'zh_HK': '保留首頁推薦重新整理',
        'en': 'Keep previous feed on refresh',
        'en_US': 'Keep previous feed on refresh',
    },
    'rcmdKeepLastDataSub': {
        'zh_CN': '下拉刷新时保留上次内容', 'zh': '下拉刷新时保留上次内容',
        'zh_TW': '下拉重新整理時保留上次內容', 'zh_HK': '下拉重新整理時保留上次內容',
        'en': 'Pull to refresh keeps the previous items',
        'en_US': 'Pull to refresh keeps the previous items',
    },
    'rcmdSavedPositionTip': {
        'zh_CN': '显示上次看到位置提示', 'zh': '显示上次看到位置提示',
        'zh_TW': '顯示上次看到位置提示', 'zh_HK': '顯示上次看到位置提示',
        'en': 'Show last-seen position tip',
        'en_US': 'Show last-seen position tip',
    },
    'rcmdSavedPositionTipSub': {
        'zh_CN': '保留上次内容时，在上次刷新位置显示提示',
        'zh': '保留上次内容时，在上次刷新位置显示提示',
        'zh_TW': '保留上次內容時，在上次重新整理位置顯示提示',
        'zh_HK': '保留上次內容時，在上次重新整理位置顯示提示',
        'en': 'Insert a tip where the previous items start',
        'en_US': 'Insert a tip where the previous items start',
    },
    'rcmdSavedPositionTipText': {
        'zh_CN': '上次看到这里', 'zh': '上次看到这里',
        'zh_TW': '上次看到這裡', 'zh_HK': '上次看到這裡',
        'en': 'You stopped here', 'en_US': 'You stopped here',
    },
    # ── 过滤器 ──
    'rcmdSectionFilter': {
        'zh_CN': '过滤器', 'zh': '过滤器',
        'zh_TW': '過濾器', 'zh_HK': '過濾器',
        'en': 'Filters', 'en_US': 'Filters',
    },
    'rcmdNoFilter': {
        'zh_CN': '不过滤', 'zh': '不过滤',
        'zh_TW': '不過濾', 'zh_HK': '不過濾',
        'en': 'No filter', 'en_US': 'No filter',
    },
    'rcmdMinLikeRatio': {
        'zh_CN': '点赞率', 'zh': '点赞率',
        'zh_TW': '點讚率', 'zh_HK': '點讚率',
        'en': 'Like ratio', 'en_US': 'Like ratio',
    },
    'rcmdMinLikeRatioSub': {
        'zh_CN': '低于该点赞率的视频不显示', 'zh': '低于该点赞率的视频不显示',
        'zh_TW': '低於該點讚率的影片不顯示', 'zh_HK': '低於該點讚率的影片不顯示',
        'en': 'Hide videos below this like ratio',
        'en_US': 'Hide videos below this like ratio',
    },
    'rcmdMinDuration': {
        'zh_CN': '视频时长', 'zh': '视频时长',
        'zh_TW': '影片時長', 'zh_HK': '影片時長',
        'en': 'Duration', 'en_US': 'Duration',
    },
    'rcmdMinDurationSub': {
        'zh_CN': '短于该时长的视频不显示', 'zh': '短于该时长的视频不显示',
        'zh_TW': '短於該時長的影片不顯示', 'zh_HK': '短於該時長的影片不顯示',
        'en': 'Hide videos shorter than this',
        'en_US': 'Hide videos shorter than this',
    },
    'rcmdMinPlay': {
        'zh_CN': '播放量', 'zh': '播放量',
        'zh_TW': '播放量', 'zh_HK': '播放量',
        'en': 'Views', 'en_US': 'Views',
    },
    'rcmdMinPlaySub': {
        'zh_CN': '低于该播放量的视频不显示', 'zh': '低于该播放量的视频不显示',
        'zh_TW': '低於該播放量的影片不顯示', 'zh_HK': '低於該播放量的影片不顯示',
        'en': 'Hide videos below this view count',
        'en_US': 'Hide videos below this view count',
    },
    'rcmdBanWord': {
        'zh_CN': '标题关键词过滤', 'zh': '标题关键词过滤',
        'zh_TW': '標題關鍵詞過濾', 'zh_HK': '標題關鍵詞過濾',
        'en': 'Title keyword filter', 'en_US': 'Title keyword filter',
    },
    'rcmdBanWordSub': {
        'zh_CN': '正则表达式，命中标题的视频不显示',
        'zh': '正则表达式，命中标题的视频不显示',
        'zh_TW': '正規表達式，命中標題的影片不顯示',
        'zh_HK': '正規表達式，命中標題的影片不顯示',
        'en': 'Regular expression; matching titles are hidden',
        'en_US': 'Regular expression; matching titles are hidden',
    },
    'rcmdBanWordHint': {
        'zh_CN': '未设置', 'zh': '未设置',
        'zh_TW': '未設定', 'zh_HK': '未設定',
        'en': 'Not set', 'en_US': 'Not set',
    },
    'rcmdBanZone': {
        'zh_CN': '分区关键词过滤', 'zh': '分区关键词过滤',
        'zh_TW': '分區關鍵詞過濾', 'zh_HK': '分區關鍵詞過濾',
        'en': 'Zone keyword filter', 'en_US': 'Zone keyword filter',
    },
    'rcmdBanZoneSub': {
        'zh_CN': '只作用于 App 端推荐 / 热门 / 排行榜',
        'zh': '只作用于 App 端推荐 / 热门 / 排行榜',
        'zh_TW': '只作用於 App 端推薦 / 熱門 / 排行榜',
        'zh_HK': '只作用於 App 端推薦 / 熱門 / 排行榜',
        'en': 'Applies to the app feed, popular and ranking only',
        'en_US': 'Applies to the app feed, popular and ranking only',
    },
    'rcmdBanZoneHint': {
        'zh_CN': '未设置', 'zh': '未设置',
        'zh_TW': '未設定', 'zh_HK': '未設定',
        'en': 'Not set', 'en_US': 'Not set',
    },
    'rcmdExemptFollowed': {
        'zh_CN': '已关注 UP 豁免推荐过滤', 'zh': '已关注 UP 豁免推荐过滤',
        'zh_TW': '已關注 UP 豁免推薦過濾', 'zh_HK': '已關注 UP 豁免推薦過濾',
        'en': 'Exempt followed uploaders',
        'en_US': 'Exempt followed uploaders',
    },
    'rcmdExemptFollowedSub': {
        'zh_CN': '推荐中已关注用户发布的内容不会被过滤',
        'zh': '推荐中已关注用户发布的内容不会被过滤',
        'zh_TW': '推薦中已關注使用者發佈的內容不會被過濾',
        'zh_HK': '推薦中已關注使用者發佈的內容不會被過濾',
        'en': 'Content from followed uploaders is kept',
        'en_US': 'Content from followed uploaders is kept',
    },
    'rcmdFilterRelated': {
        'zh_CN': '过滤器也应用于详情页相关视频',
        'zh': '过滤器也应用于详情页相关视频',
        'zh_TW': '過濾器也套用於詳情頁相關影片',
        'zh_HK': '過濾器也套用於詳情頁相關影片',
        'en': 'Apply filters to related videos',
        'en_US': 'Apply filters to related videos',
    },
    'rcmdFilterRelatedSub': {
        'zh_CN': '热门视频、搜索等其它入口不受影响',
        'zh': '热门视频、搜索等其它入口不受影响',
        'zh_TW': '熱門影片、搜尋等其它入口不受影響',
        'zh_HK': '熱門影片、搜尋等其它入口不受影響',
        'en': 'Popular, search and other entries are unaffected',
        'en_US': 'Popular, search and other entries are unaffected',
    },
    'rcmdFilterHint': {
        'zh_CN': '过滤器在下次拉取推荐时生效；关键词按正则表达式匹配，留空表示不过滤。',
        'zh': '过滤器在下次拉取推荐时生效；关键词按正则表达式匹配，留空表示不过滤。',
        'zh_TW': '過濾器在下次拉取推薦時生效；關鍵詞按正規表達式匹配，留空表示不過濾。',
        'zh_HK': '過濾器在下次拉取推薦時生效；關鍵詞按正規表達式匹配，留空表示不過濾。',
        'en': 'Filters apply on the next fetch. Keywords are regular expressions; leave empty to disable.',
        'en_US': 'Filters apply on the next fetch. Keywords are regular expressions; leave empty to disable.',
    },
    'rcmdFilterSaved': {
        'zh_CN': '已保存，下次拉取推荐时生效', 'zh': '已保存，下次拉取推荐时生效',
        'zh_TW': '已儲存，下次拉取推薦時生效', 'zh_HK': '已儲存，下次拉取推薦時生效',
        'en': 'Saved; applies on the next fetch',
        'en_US': 'Saved; applies on the next fetch',
    },
    # ── 打开受支持的链接 ──
    'prefLinkSection': {
        'zh_CN': '链接打开方式', 'zh': '链接打开方式',
        'zh_TW': '連結開啟方式', 'zh_HK': '連結開啟方式',
        'en': 'Link handling', 'en_US': 'Link handling',
    },
    'prefOpenSupportedLinks': {
        'zh_CN': '打开受支持的链接', 'zh': '打开受支持的链接',
        'zh_TW': '開啟支援的連結', 'zh_HK': '開啟支援的連結',
        'en': 'Open supported links', 'en_US': 'Open supported links',
    },
    'prefOpenSupportedLinksSub': {
        'zh_CN': '到系统设置里把本应用设为 bilibili / memz2345.top 链接的默认打开方式',
        'zh': '到系统设置里把本应用设为 bilibili / memz2345.top 链接的默认打开方式',
        'zh_TW': '到系統設定裡把本應用設為 bilibili / memz2345.top 連結的預設開啟方式',
        'zh_HK': '到系統設定裡把本應用設為 bilibili / memz2345.top 連結的預設開啟方式',
        'en': 'Set this app as the default handler for bilibili / memz2345.top links',
        'en_US': 'Set this app as the default handler for bilibili / memz2345.top links',
    },
    'linkSettingsUnavailable': {
        'zh_CN': '未能打开系统设置页，请在系统设置里手动查找「默认打开」',
        'zh': '未能打开系统设置页，请在系统设置里手动查找「默认打开」',
        'zh_TW': '未能開啟系統設定頁，請在系統設定裡手動尋找「預設開啟」',
        'zh_HK': '未能開啟系統設定頁，請在系統設定裡手動尋找「預設開啟」',
        'en': 'Could not open system settings; look for the default-handler entry manually',
        'en_US': 'Could not open system settings; look for the default-handler entry manually',
    },
}


def patch(locale: str) -> None:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8', newline='') as f:
        raw = f.read()
    eol = '\r\n' if '\r\n' in raw else '\n'

    # 幂等：已经存在的 key 跳过（方便后续追加新文案时重复执行）
    lines = []
    skipped = 0
    for key, table in VALUES.items():
        if '"%s"' % key in raw:
            skipped += 1
            continue
        value = table[locale]
        assert "'" not in value, 'arb 值不能含撇号: %s' % value
        assert '"' not in value, 'arb 值不能含双引号: %s' % value
        lines.append('  "%s": "%s",' % (key, value))

    if not lines:
        print('-- %s (nothing to add)' % os.path.basename(path))
        return

    assert raw.count(ANCHOR) == 1, '锚点不唯一: %s' % path

    idx = raw.index(ANCHOR)
    line_end = raw.index(eol, idx)
    insert_at = line_end + len(eol)
    out = raw[:insert_at] + eol.join(lines) + eol + raw[insert_at:]

    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(out)
    print('OK %s (+%d keys, skipped %d)' % (os.path.basename(path), len(lines), skipped))


if __name__ == '__main__':
    for loc in ('zh_CN', 'zh', 'zh_TW', 'zh_HK', 'en', 'en_US'):
        patch(loc)
