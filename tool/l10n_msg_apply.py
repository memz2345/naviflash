# tool/l10n_msg_apply.py
#
# 把「消息中心 / 私信」页面里硬编码的中文替换成 AppLocalizations 取词。
# 显式 UTF-8 读写，逐条精确替换，未命中的条目会打印出来。
# 用法：python tool/l10n_msg_apply.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IMPORT = "import 'package:naviflash/l10n/app_localizations.dart';\n"
IMPORT_HELPER = "import 'package:naviflash/l10n/l10n_helper.dart';\n"

# (相对路径, [(旧文本, 新文本), ...])
REPLACEMENTS = {
    "lib/widgets/msg_feed_common.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT + IMPORT_HELPER),
        ("  if (diff.inMinutes < 1 && diff.inSeconds >= 0) return '刚刚';",
         "  if (diff.inMinutes < 1 && diff.inSeconds >= 0) {\n    return L10n.current.msgTimeJustNow;\n  }"),
        ("  if (diff.inHours < 1 && diff.inMinutes >= 0) return '${diff.inMinutes} 分钟前';",
         "  if (diff.inHours < 1 && diff.inMinutes >= 0) {\n    return L10n.current.msgTimeMinutesAgo(diff.inMinutes);\n  }"),
        ("  if (isYesterday) return '昨天 ${two(dt.hour)}:${two(dt.minute)}';",
         "  if (isYesterday) {\n    return L10n.current.msgTimeYesterday('${two(dt.hour)}:${two(dt.minute)}');\n  }"),
        ("            child: const Text('去登录'),",
         "            child: Text(AppLocalizations.of(context).msgGoLogin),"),
    ],
    "lib/screens/msg_feed_list_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("    this.deleteConfirmText = '确定删除该通知？',",
         "    this.deleteConfirmText = '',"),
        ("        title: Text(\n          widget.deleteConfirmText,\n          style: const TextStyle(fontSize: 16),\n        ),",
         "        title: Text(\n          widget.deleteConfirmText.isEmpty\n              ? AppLocalizations.of(context).msgDeleteNoticeConfirm\n              : widget.deleteConfirmText,\n          style: const TextStyle(fontSize: 16),\n        ),"),
        ("            child: const Text('取消'),",
         "            child: Text(AppLocalizations.of(context).commonCancel),"),
        ("            child: const Text('删除'),",
         "            child: Text(AppLocalizations.of(context).commonDelete),"),
        ("      showAppToast(context, '已删除');",
         "      showAppToast(context, AppLocalizations.of(context).msgDeleted);"),
        ("      return MsgLoginPrompt(icon: widget.emptyIcon, title: '登录后可以查看${widget.title}');",
         "      return MsgLoginPrompt(\n        icon: widget.emptyIcon,\n        title: AppLocalizations.of(context).msgLoginPromptFeature(widget.title),\n      );"),
    ],
    "lib/screens/msg_reply_me_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      title: '回复我的',", "      title: AppLocalizations.of(context).msgReplyMe,"),
        ("      emptyText: '还没有人回复你',", "      emptyText: AppLocalizations.of(context).msgReplyEmpty,"),
        ("              text: user.nickname.isEmpty ? '用户${user.mid}' : user.nickname,",
         "              text: user.nickname.isEmpty\n                  ? AppLocalizations.of(context).msgUserFallback('${user.mid}')\n                  : user.nickname,"),
        ("                text: ' 等人',", "                text: AppLocalizations.of(context).msgEtAl,"),
        ("              text: ' 对我的${content.business}发布了${item.counts}条评论',",
         "              text: AppLocalizations.of(\n                context,\n              ).msgReplyTitle(content.business, item.counts),"),
    ],
    "lib/screens/msg_at_me_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      title: '@我的',", "      title: AppLocalizations.of(context).msgAtMe,"),
        ("      emptyText: '还没有人 @ 你',", "      emptyText: AppLocalizations.of(context).msgAtEmpty,"),
        ("              text: user.nickname.isEmpty ? '用户${user.mid}' : user.nickname,",
         "              text: user.nickname.isEmpty\n                  ? AppLocalizations.of(context).msgUserFallback('${user.mid}')\n                  : user.nickname,"),
        ("              text: ' 在${content.business}里 @ 了你',",
         "              text: AppLocalizations.of(\n                context,\n              ).msgAtTitle(content.business),"),
    ],
    "lib/screens/msg_sys_msg_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      title: '系统通知',", "      title: AppLocalizations.of(context).msgSysNotice,"),
        ("      emptyText: '还没有系统通知',", "      emptyText: AppLocalizations.of(context).msgSysEmpty,"),
        ("        item.title.isEmpty ? '系统通知' : item.title,",
         "        item.title.isEmpty\n            ? AppLocalizations.of(context).msgSysNotice\n            : item.title,"),
    ],
    "lib/screens/msg_like_me_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      appBar: AppBar(title: const Text('收到的赞')),",
         "      appBar: AppBar(title: Text(AppLocalizations.of(context).msgLikedMe)),"),
        ("        title: const Text('删除该通知？', style: TextStyle(fontSize: 16)),",
         "        title: Text(\n          AppLocalizations.of(context).msgDeleteNoticeTitle,\n          style: const TextStyle(fontSize: 16),\n        ),"),
        ("        content: const Text(\n          '删除后，当有新点赞时会重新出现在列表。',\n          style: TextStyle(fontSize: 13),\n        ),",
         "        content: Text(\n          AppLocalizations.of(context).msgDeleteNoticeBody,\n          style: const TextStyle(fontSize: 13),\n        ),"),
        ("            child: const Text('取消'),",
         "            child: Text(AppLocalizations.of(context).commonCancel),"),
        ("            child: const Text('删除'),",
         "            child: Text(AppLocalizations.of(context).commonDelete),"),
        ("      showAppToast(context, '已删除');",
         "      showAppToast(context, AppLocalizations.of(context).msgDeleted);"),
        ("          title: const Text('不再通知', style: TextStyle(fontSize: 16)),",
         "          title: Text(\n            AppLocalizations.of(context).msgMuteNotice,\n            style: const TextStyle(fontSize: 16),\n          ),"),
        ("          content: const Text(\n            '这条内容的点赞将不再通知，但仍可在列表内查看。',\n            style: TextStyle(fontSize: 13),\n          ),",
         "          content: Text(\n            AppLocalizations.of(context).msgMuteNoticeBody,\n            style: const TextStyle(fontSize: 13),\n          ),"),
        ("            child: const Text('确定'),",
         "            child: Text(AppLocalizations.of(context).commonOk),"),
        ("      showAppToast(context, '设置成功');",
         "      showAppToast(context, AppLocalizations.of(context).msgSettingSaved);"),
        ("        title: '登录后可以查看收到的赞',",
         "        title: AppLocalizations.of(context).msgLoginPromptLikes,"),
        ("        title: '还没有人赞过你',", "        title: AppLocalizations.of(context).msgLikedEmpty,"),
        ("        subtitle: '发布内容后会在这里看到点赞通知',",
         "        subtitle: AppLocalizations.of(context).msgLikedEmptySubtitle,"),
        ("            _header(cs, '最新'),", "            _header(cs, AppLocalizations.of(context).msgSectionLatest),"),
        ("            _header(cs, '累计'),", "            _header(cs, AppLocalizations.of(context).msgSectionTotal),"),
        ("                        '没有更多了',", "                        AppLocalizations.of(context).msgNoMore,"),
        ("              title: const Text('删除'),",
         "              title: Text(AppLocalizations.of(context).commonDelete),"),
        ("              title: Text(noticeOn ? '不再通知' : '接收通知'),",
         "              title: Text(\n                noticeOn\n                    ? AppLocalizations.of(context).msgMuteNotice\n                    : AppLocalizations.of(context).msgUnmuteNotice,\n              ),"),
        ("    final firstText = first.nickname.isEmpty\n        ? '用户${first.mid}'\n        : first.nickname;",
         "    final firstText = first.nickname.isEmpty\n        ? AppLocalizations.of(context).msgUserFallback('${first.mid}')\n        : first.nickname;"),
        ("    final names = users.isEmpty\n        ? '有人'\n        : users.length == 1\n        ? firstText\n        : '$firstText 等 ${item.counts} 人';",
         "    final names = users.isEmpty\n        ? AppLocalizations.of(context).msgSomeone\n        : users.length == 1\n        ? firstText\n        : AppLocalizations.of(context).msgEtAlCount(firstText, item.counts);"),
        ("              text: item.business.isEmpty ? ' 赞了你' : ' 赞了你的${item.business}',",
         "              text: item.business.isEmpty\n                  ? AppLocalizations.of(context).msgLikedYou\n                  : AppLocalizations.of(\n                      context,\n                    ).msgLikedYourBusiness(item.business),"),
        ("                text: '  · 已关闭通知',",
         "                text:\n                    '  · ${AppLocalizations.of(context).msgNoticeMuted}',"),
    ],
    "lib/screens/msg_like_detail_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      appBar: AppBar(title: const Text('点赞的人')),",
         "      appBar: AppBar(title: Text(AppLocalizations.of(context).msgLikeDetailTitle)),"),
        ("        title: '还没有人点赞',", "        title: AppLocalizations.of(context).msgLikeDetailEmpty,"),
        ("                        '没有更多了',", "                        AppLocalizations.of(context).msgNoMore,"),
    ],
    "lib/screens/message_center_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      appBar: AppBar(title: const Text('消息中心')),",
         "      appBar: AppBar(title: Text(AppLocalizations.of(context).msgCenterTitle)),"),
        ("          ? const MsgLoginPrompt(\n              icon: Icons.forum_outlined,\n              title: '登录后可以查看消息中心',\n            )",
         "          ? MsgLoginPrompt(\n              icon: Icons.forum_outlined,\n              title: AppLocalizations.of(context).msgCenterLoginPrompt,\n            )"),
        ("        label: '回复我的',", "        label: AppLocalizations.of(context).msgReplyMe,"),
        ("        label: '@我的',", "        label: AppLocalizations.of(context).msgAtMe,"),
        ("        label: '收到的赞',", "        label: AppLocalizations.of(context).msgLikedMe,"),
        ("        label: '系统通知',", "        label: AppLocalizations.of(context).msgSysNotice,"),
        ("        title: const Text(\n          '我的私信',\n          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),\n        ),",
         "        title: Text(\n          AppLocalizations.of(context).msgMyWhisper,\n          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),\n        ),"),
        ("          _whisperUnread > 0 ? '$_whisperUnread 条未读' : '与 UP 主的私信会话',",
         "          _whisperUnread > 0\n              ? AppLocalizations.of(context).msgUnreadCount(_whisperUnread)\n              : AppLocalizations.of(context).msgWhisperSubtitle,"),
    ],
    "lib/screens/whisper_list_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("      appBar: AppBar(title: const Text('我的私信')),",
         "      appBar: AppBar(title: Text(AppLocalizations.of(context).msgMyWhisper)),"),
        ("      showAppToast(context, pinned ? '已取消置顶' : '已置顶');",
         "      showAppToast(\n        context,\n        pinned\n            ? AppLocalizations.of(context).msgUnpinned\n            : AppLocalizations.of(context).msgPinned,\n      );"),
        ("        title: const Text('删除会话？', style: TextStyle(fontSize: 16)),",
         "        title: Text(\n          AppLocalizations.of(context).msgDeleteSessionTitle,\n          style: const TextStyle(fontSize: 16),\n        ),"),
        ("        content: const Text(\n          '删除后聊天记录将从列表移除，对方再发消息会重新出现。',\n          style: TextStyle(fontSize: 13),\n        ),",
         "        content: Text(\n          AppLocalizations.of(context).msgDeleteSessionBody,\n          style: const TextStyle(fontSize: 13),\n        ),"),
        ("            child: const Text('取消'),",
         "            child: Text(AppLocalizations.of(context).commonCancel),"),
        ("            child: const Text('删除'),",
         "            child: Text(AppLocalizations.of(context).commonDelete),"),
        ("      showAppToast(context, '已删除');",
         "      showAppToast(context, AppLocalizations.of(context).msgDeleted);"),
        ("              title: Text(session.isPinned ? '取消置顶' : '置顶会话'),",
         "              title: Text(\n                session.isPinned\n                    ? AppLocalizations.of(context).msgUnpin\n                    : AppLocalizations.of(context).msgPin,\n              ),"),
        ("              title: const Text('删除会话'),",
         "              title: Text(AppLocalizations.of(context).msgDeleteSession),"),
        ("      return const MsgLoginPrompt(\n        icon: Icons.mail_outline,\n        title: '登录后可以查看私信',\n      );",
         "      return MsgLoginPrompt(\n        icon: Icons.mail_outline,\n        title: AppLocalizations.of(context).msgLoginPromptWhisper,\n      );"),
        ("      return const MsgEmptyView(\n        icon: Icons.mail_outline,\n        title: '还没有私信会话',\n        subtitle: '在 UP 主主页点「私信」就能开始聊天',\n      );",
         "      return MsgEmptyView(\n        icon: Icons.mail_outline,\n        title: AppLocalizations.of(context).msgWhisperEmpty,\n        subtitle: AppLocalizations.of(context).msgWhisperEmptySubtitle,\n      );"),
        ("              title.isEmpty ? '用户$mid' : title,",
         "              title.isEmpty\n                  ? AppLocalizations.of(context).msgUserFallback('$mid')\n                  : title,"),
        ("                summary.isEmpty ? '[暂无消息]' : summary,",
         "                summary.isEmpty\n                    ? AppLocalizations.of(context).msgNoMessage\n                    : summary,"),
    ],
    "lib/screens/whisper_chat_page.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("        title: const Text('撤回这条消息？', style: TextStyle(fontSize: 16)),",
         "        title: Text(\n          AppLocalizations.of(context).msgWithdrawConfirm,\n          style: const TextStyle(fontSize: 16),\n        ),"),
        ("            child: const Text('取消'),",
         "            child: Text(AppLocalizations.of(context).commonCancel),"),
        ("            child: const Text('撤回'),",
         "            child: Text(AppLocalizations.of(context).msgWithdraw),"),
        ("      showAppToast(context, '已撤回');",
         "      showAppToast(context, AppLocalizations.of(context).msgWithdrawn);"),
        ("                  widget.name.isEmpty ? '私信' : widget.name,",
         "                  widget.name.isEmpty\n                      ? AppLocalizations.of(context).msgMyWhisper\n                      : widget.name,"),
        ("            tooltip: '刷新',", "            tooltip: AppLocalizations.of(context).msgRefresh,"),
        ("      return const MsgEmptyView(\n        icon: Icons.chat_bubble_outline,\n        title: '还没有聊天记录',\n        subtitle: '发条消息打个招呼吧',\n      );",
         "      return MsgEmptyView(\n        icon: Icons.chat_bubble_outline,\n        title: AppLocalizations.of(context).msgChatEmpty,\n        subtitle: AppLocalizations.of(context).msgChatEmptySubtitle,\n      );"),
        ("                child: const Text('重试'),",
         "                child: Text(AppLocalizations.of(context).commonRetry),"),
        ("                      '没有更早的消息了',",
         "                      AppLocalizations.of(context).msgNoEarlier,"),
        ("                  hintText: '发消息…',",
         "                  hintText: AppLocalizations.of(context).msgInputHint,"),
        ("              tooltip: '发送',", "              tooltip: AppLocalizations.of(context).commonSend,"),
        ("            child = url.isEmpty\n            ? Text('[图片]', style: TextStyle(color: textColor))",
         "            child = url.isEmpty\n            ? Text(\n                AppLocalizations.of(context).msgPicture,\n                style: TextStyle(color: textColor),\n              )"),
        ("                  errorBuilder: (_, __, ___) =>\n                      Text('[图片加载失败]', style: TextStyle(color: textColor)),",
         "                  errorBuilder: (_, __, ___) => Text(\n                    AppLocalizations.of(context).msgPictureFailed,\n                    style: TextStyle(color: textColor),\n                  ),"),
        ("              isOwner ? '你撤回了一条消息' : '对方撤回了一条消息',",
         "              isOwner\n                  ? AppLocalizations.of(context).msgWithdrawnSelf\n                  : AppLocalizations.of(context).msgWithdrawnOther,"),
        ("          title.isEmpty ? '[分享内容]' : title,",
         "          title.isEmpty ? AppLocalizations.of(context).msgShare : title,"),
        ("        child = Text(\n          text.isEmpty ? '[暂不支持的消息类型 $type]' : text,\n          style: TextStyle(fontSize: 14, color: textColor),\n        );",
         "        child = Text(\n          text.isEmpty\n              ? AppLocalizations.of(context).msgUnsupportedType('$type')\n              : text,\n          style: TextStyle(fontSize: 14, color: textColor),\n        );"),
    ],
    "lib/widgets/message_center_entry.dart": [
        ("import 'package:flutter/material.dart';\n",
         "import 'package:flutter/material.dart';\n\n" + IMPORT),
        ("        title: const Text('消息中心'),", "        title: Text(AppLocalizations.of(context).msgCenterTitle),"),
        ("      title: const Text('消息中心'),", "      title: Text(AppLocalizations.of(context).msgCenterTitle),"),
        ("      subtitle: _unread > 0\n          ? Text('$_unread 条未读')\n          : const Text('回复我的 · @我的 · 收到的赞 · 私信'),",
         "      subtitle: _unread > 0\n          ? Text(AppLocalizations.of(context).msgUnreadCount(_unread))\n          : Text(AppLocalizations.of(context).msgCenterSubtitle),"),
    ],
    "lib/widgets/app_drawer.dart": [
        ("                  title: '消息中心',",
         "                  title: AppLocalizations.of(context).msgCenterTitle,"),
    ],
}


def apply(path, pairs):
    full = os.path.join(ROOT, path)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in pairs:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:70])
            continue
        text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return missing


def main():
    total_missing = 0
    for path, pairs in REPLACEMENTS.items():
        missing = apply(path, pairs)
        if missing:
            total_missing += len(missing)
            print("MISS %s:" % path)
            for m in missing:
                print("   - %s" % m)
        else:
            print("ok   %s" % path)
    print("missing total: %d" % total_missing)
    return 1 if total_missing else 0


if __name__ == "__main__":
    sys.exit(main())
