# tool/add_msg_l10n.py
#
# 把「消息中心 / 私信」页面文案追加进 6 份 arb（app_zh_CN 为模板，含 @ 元数据）。
# 只在最后一个 "}" 之前插入，保持原有格式化风格。
# 用法：python tool/add_msg_l10n.py
import io
import os
import sys

ARB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib", "l10n")

# key: (zh_CN, zh_HK, zh_TW, en)   —— zh 与 zh_CN 同值
# placeholders: key -> [(name, type)]
ENTRIES = [
    ("msgCenterTitle", "消息中心", "訊息中心", "訊息中心", "Message center", None),
    ("msgCenterSubtitle", "回复我的 · @我的 · 收到的赞 · 私信", "回覆我的 · @我的 · 收到的讚 · 私訊",
     "回覆我的 · @我的 · 收到的讚 · 私訊", "Replies · Mentions · Likes · Messages", None),
    ("msgCenterLoginPrompt", "登录后可以查看消息中心", "登入後可以查看訊息中心", "登入後可以查看訊息中心",
     "Sign in to view the message center", None),
    ("msgReplyMe", "回复我的", "回覆我的", "回覆我的", "Replies", None),
    ("msgAtMe", "@我的", "@我的", "@我的", "Mentions", None),
    ("msgLikedMe", "收到的赞", "收到的讚", "收到的讚", "Likes", None),
    ("msgSysNotice", "系统通知", "系統通知", "系統通知", "Notifications", None),
    ("msgMyWhisper", "我的私信", "我的私訊", "我的私訊", "Messages", None),
    ("msgWhisperSubtitle", "与 UP 主的私信会话", "與 UP 主的私訊對話", "與 UP 主的私訊對話",
     "Your private chats with creators", None),
    ("msgUnreadCount", "{count} 条未读", "{count} 則未讀", "{count} 則未讀", "{count} unread",
     [("count", "int")]),
    ("msgTimeJustNow", "刚刚", "剛剛", "剛剛", "Just now", None),
    ("msgTimeMinutesAgo", "{count} 分钟前", "{count} 分鐘前", "{count} 分鐘前", "{count} min ago",
     [("count", "int")]),
    ("msgTimeYesterday", "昨天 {time}", "昨天 {time}", "昨天 {time}", "Yesterday {time}",
     [("time", "String")]),
    ("msgGoLogin", "去登录", "去登入", "去登入", "Sign in", None),
    ("msgDeleteNoticeConfirm", "确定删除该通知？", "確定刪除這則通知？", "確定刪除這則通知？",
     "Delete this notification?", None),
    ("msgDeleted", "已删除", "已刪除", "已刪除", "Deleted", None),
    ("msgLoginPromptFeature", "登录后可以查看{title}", "登入後可以查看{title}", "登入後可以查看{title}",
     "Sign in to view {title}", [("title", "String")]),
    ("msgNoMore", "没有更多了", "沒有更多了", "沒有更多了", "No more results", None),
    ("msgReplyEmpty", "还没有人回复你", "還沒有人回覆你", "還沒有人回覆你", "No replies yet", None),
    ("msgUserFallback", "用户{mid}", "用戶{mid}", "用戶{mid}", "User {mid}", [("mid", "String")]),
    ("msgEtAl", " 等人", " 等人", " 等人", " and others", None),
    ("msgReplyTitle", " 对我的{business}发布了{counts}条评论", " 對我的{business}發布了{counts}則評論",
     " 對我的{business}發布了{counts}則評論", " commented {counts} times on your {business}",
     [("business", "String"), ("counts", "int")]),
    ("msgAtEmpty", "还没有人 @ 你", "還沒有人 @ 你", "還沒有人 @ 你", "Nobody has mentioned you yet", None),
    ("msgAtTitle", " 在{business}里 @ 了你", " 在{business}裡 @ 了你", " 在{business}裡 @ 了你",
     " mentioned you in {business}", [("business", "String")]),
    ("msgDeleteNoticeTitle", "删除该通知？", "刪除這則通知？", "刪除這則通知？", "Delete this notification?", None),
    ("msgDeleteNoticeBody", "删除后，当有新点赞时会重新出现在列表。", "刪除後，當有新點讚時會重新出現在列表。",
     "刪除後，當有新點讚時會重新出現在列表。", "It reappears when you get new likes.", None),
    ("msgMuteNotice", "不再通知", "不再通知", "不再通知", "Mute", None),
    ("msgMuteNoticeBody", "这条内容的点赞将不再通知，但仍可在列表内查看。",
     "這則內容的點讚將不再通知，但仍可在列表內查看。", "這則內容的點讚將不再通知，但仍可在列表內查看。",
     "You will no longer be notified about likes on this item, but it stays in the list.", None),
    ("msgSettingSaved", "设置成功", "設定成功", "設定成功", "Saved", None),
    ("msgLoginPromptLikes", "登录后可以查看收到的赞", "登入後可以查看收到的讚", "登入後可以查看收到的讚",
     "Sign in to view likes you received", None),
    ("msgLikedEmpty", "还没有人赞过你", "還沒有人讚過你", "還沒有人讚過你", "No likes yet", None),
    ("msgLikedEmptySubtitle", "发布内容后会在这里看到点赞通知", "發布內容後會在這裡看到點讚通知",
     "發布內容後會在這裡看到點讚通知", "Likes on your posts will show up here", None),
    ("msgSectionLatest", "最新", "最新", "最新", "Latest", None),
    ("msgSectionTotal", "累计", "累計", "累計", "Total", None),
    ("msgSomeone", "有人", "有人", "有人", "Someone", None),
    ("msgEtAlCount", "{name} 等 {count} 人", "{name} 等 {count} 人", "{name} 等 {count} 人",
     "{name} and {count} others", [("name", "String"), ("count", "int")]),
    ("msgLikedYou", " 赞了你", " 讚了你", " 讚了你", " liked you", None),
    ("msgLikedYourBusiness", " 赞了你的{business}", " 讚了你的{business}", " 讚了你的{business}",
     " liked your {business}", [("business", "String")]),
    ("msgNoticeMuted", "已关闭通知", "已關閉通知", "已關閉通知", "Notifications off", None),
    ("msgUnmuteNotice", "接收通知", "接收通知", "接收通知", "Unmute", None),
    ("msgLikeDetailTitle", "点赞的人", "點讚的人", "點讚的人", "Likes", None),
    ("msgLikeDetailEmpty", "还没有人点赞", "還沒有人點讚", "還沒有人點讚", "No likes yet", None),
    ("msgSysEmpty", "还没有系统通知", "還沒有系統通知", "還沒有系統通知", "No notifications yet", None),
    ("msgDeleteSessionTitle", "删除会话？", "刪除對話？", "刪除對話？", "Delete chat?", None),
    ("msgDeleteSessionBody", "删除后聊天记录将从列表移除，对方再发消息会重新出现。",
     "刪除後聊天記錄將從列表移除，對方再發訊息會重新出現。",
     "刪除後聊天記錄將從列表移除，對方再發訊息會重新出現。",
     "The chat is removed from the list and reappears if they message you again.", None),
    ("msgUnpinned", "已取消置顶", "已取消置頂", "已取消置頂", "Unpinned", None),
    ("msgPinned", "已置顶", "已置頂", "已置頂", "Pinned", None),
    ("msgUnpin", "取消置顶", "取消置頂", "取消置頂", "Unpin", None),
    ("msgPin", "置顶会话", "置頂對話", "置頂對話", "Pin chat", None),
    ("msgDeleteSession", "删除会话", "刪除對話", "刪除對話", "Delete chat", None),
    ("msgLoginPromptWhisper", "登录后可以查看私信", "登入後可以查看私訊", "登入後可以查看私訊",
     "Sign in to view messages", None),
    ("msgWhisperEmpty", "还没有私信会话", "還沒有私訊對話", "還沒有私訊對話", "No chats yet", None),
    ("msgWhisperEmptySubtitle", "在 UP 主主页点「私信」就能开始聊天", "在 UP 主主頁點「私訊」就能開始聊天",
     "在 UP 主主頁點「私訊」就能開始聊天",
     "Tap “Message” on a creator’s profile to start chatting", None),
    ("msgNoMessage", "[暂无消息]", "[暫無訊息]", "[暫無訊息]", "[No messages]", None),
    ("msgWithdrawConfirm", "撤回这条消息？", "撤回這則訊息？", "撤回這則訊息？", "Withdraw this message?", None),
    ("msgWithdraw", "撤回", "撤回", "撤回", "Withdraw", None),
    ("msgWithdrawn", "已撤回", "已撤回", "已撤回", "Withdrawn", None),
    ("msgWithdrawnSelf", "你撤回了一条消息", "你撤回了一則訊息", "你撤回了一則訊息",
     "You withdrew a message", None),
    ("msgWithdrawnOther", "对方撤回了一条消息", "對方撤回了一則訊息", "對方撤回了一則訊息",
     "The other person withdrew a message", None),
    ("msgChatEmpty", "还没有聊天记录", "還沒有聊天記錄", "還沒有聊天記錄", "No messages yet", None),
    ("msgChatEmptySubtitle", "发条消息打个招呼吧", "發則訊息打個招呼吧", "發則訊息打個招呼吧", "Say hi", None),
    ("msgNoEarlier", "没有更早的消息了", "沒有更早的訊息了", "沒有更早的訊息了", "No earlier messages", None),
    ("msgInputHint", "发消息…", "發訊息…", "發訊息…", "Message…", None),
    ("msgPicture", "[图片]", "[圖片]", "[圖片]", "[Image]", None),
    ("msgPictureFailed", "[图片加载失败]", "[圖片載入失敗]", "[圖片載入失敗]", "[Image failed to load]", None),
    ("msgShare", "[分享内容]", "[分享內容]", "[分享內容]", "[Shared content]", None),
    ("msgUnsupportedType", "[暂不支持的消息类型 {type}]", "[暫不支援的訊息類型 {type}]",
     "[暫不支援的訊息類型 {type}]", "[Unsupported message type {type}]", [("type", "String")]),
    ("msgRefresh", "刷新", "重新整理", "重新整理", "Refresh", None),
    ("commonSend", "发送", "發送", "傳送", "Send", None),
    ("commonRetry", "重试", "重試", "重試", "Retry", None),
    ("msgInteractions", "社区互动", "社群互動", "社群互動", "Community", None),
    ("msgLoadMore", "加载更多", "載入更多", "載入更多", "Load more", None),
    ("dynamicsTitle", "动态", "動態", "動態", "Dynamics", None),
    ("dynamicsTabAll", "全部", "全部", "全部", "All", None),
    ("dynamicsTabVideo", "投稿", "投稿", "投稿", "Videos", None),
    ("dynamicsTabPgc", "番剧", "番劇", "番劇", "Anime", None),
    ("dynamicsTabArticle", "专栏", "專欄", "專欄", "Articles", None),
    ("dynamicsEmpty", "这里还没有动态", "這裡還沒有動態", "這裡還沒有動態", "No dynamics yet", None),
    ("dynamicsLoginPrompt", "登录后可以看关注动态", "登入後可以看關注動態", "登入後可以看關注動態",
     "Sign in to see dynamics from creators you follow", None),
]

LOCALE_INDEX = {"zh_CN": 1, "zh": 1, "zh_HK": 2, "zh_TW": 3, "en": 4, "en_US": 4}


def esc(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def build_block(locale, is_template):
    """返回「条目」字符串列表（每个条目内部自带换行），由调用方用 ",\n" 连接。"""
    entries = []
    for key, zh_cn, zh_hk, zh_tw, en, placeholders in ENTRIES:
        value = [zh_cn, zh_hk, zh_tw, en][LOCALE_INDEX[locale] - 1]
        entries.append('  "%s": "%s"' % (key, esc(value)))
        if is_template and placeholders:
            meta = ['  "@%s": {' % key, '    "placeholders": {']
            for i, (name, ptype) in enumerate(placeholders):
                comma = "," if i < len(placeholders) - 1 else ""
                meta.append('      "%s": {' % name)
                meta.append('        "type": "%s"' % ptype)
                meta.append('      }%s' % comma)
            meta.append("    }")
            meta.append("  }")
            entries.append("\n".join(meta))
    return entries


def patch(path, locale):
    with io.open(path, "r", encoding="utf-8") as f:
        text = f.read()
    is_template = locale == "zh_CN"
    missing = [
        key for key, *_ in ENTRIES
        if '"%s"' % key not in text
    ]
    if not missing:
        print("skip (already patched): %s" % os.path.basename(path))
        return 0
    idx = text.rfind("\n}")
    if idx < 0:
        raise SystemExit("no trailing brace in %s" % path)
    block = ",\n".join(build_block(locale, is_template))
    text = text[:idx] + ",\n" + block + text[idx:]
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("patched %s (+%d keys)" % (os.path.basename(path), len(missing)))
    return len(missing)


def main():
    total = 0
    for locale in ("zh_CN", "zh", "zh_HK", "zh_TW", "en", "en_US"):
        path = os.path.join(ARB_DIR, "app_%s.arb" % locale)
        if not os.path.exists(path):
            print("MISSING arb: %s" % path, file=sys.stderr)
            continue
        total += patch(path, locale)
    print("total inserted: %d" % total)


if __name__ == "__main__":
    main()
