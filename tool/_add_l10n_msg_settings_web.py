# -*- coding: utf-8 -*-
"""给 6 个 arb 追加「消息设置（web 接口版）」文案，随后跑 flutter gen-l10n。

用法：python tool/_add_l10n_msg_settings_web.py
"""
import io
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'l10n')

PLAIN = [
    'msgSettingsNotifSection',
    'msgSettingsReplyNotify',
    'msgSettingsReplyNotifyDesc',
    'msgSettingsAtNotify',
    'msgSettingsAtNotifyDesc',
    'msgSettingsLikeNotify',
    'msgSettingsLikeNotifyDesc',
    'msgSettingsNotifyEveryone',
    'msgSettingsNotifyFollowing',
    'msgSettingsNotifyNone',
    'msgSettingsReceiveSection',
    'msgSettingsReceiveUnfollow',
    'msgSettingsReceiveUnfollowDesc',
    'msgSettingsUnfollowFold',
    'msgSettingsUnfollowFoldDesc',
    'msgSettingsGroupReceive',
    'msgSettingsGroupFold',
    'msgSettingsSmartIntercept',
    'msgSettingsSmartInterceptDesc',
    'msgSettingsAntiHarassmentSection',
    'msgSettingsAntiHarassment',
    'msgSettingsScopeSelect',
]

ARGS = {
    'msgSettingsValidUntil': 'time',
}

ZH_CN = {
    'msgSettingsNotifSection': '通知提醒',
    'msgSettingsReplyNotify': '回复我的消息提醒',
    'msgSettingsReplyNotifyDesc': '（接收谁的评论消息提醒）',
    'msgSettingsAtNotify': '@我的消息提醒',
    'msgSettingsAtNotifyDesc': '（接收谁的@消息提醒）',
    'msgSettingsLikeNotify': '收到的赞提醒',
    'msgSettingsLikeNotifyDesc': '（接收谁的赞消息提醒）',
    'msgSettingsNotifyEveryone': '所有人',
    'msgSettingsNotifyFollowing': '关注的人',
    'msgSettingsNotifyNone': '不接收任何消息提醒',
    'msgSettingsReceiveSection': '私信接收',
    'msgSettingsReceiveUnfollow': '接收未关注人消息',
    'msgSettingsReceiveUnfollowDesc': '（若关闭此开关，你将不再收到未关注人的私信，但通知类消息不受影响）',
    'msgSettingsUnfollowFold': '未关注人消息折叠',
    'msgSettingsUnfollowFoldDesc': '（未关注人消息将被折叠起来）',
    'msgSettingsGroupReceive': '接收应援团消息',
    'msgSettingsGroupFold': '应援团消息折叠',
    'msgSettingsSmartIntercept': '私信智能拦截',
    'msgSettingsSmartInterceptDesc': '（开启后，7日内仅会接收到指定用户的私信、弹幕、评论，并不再接收@消息）',
    'msgSettingsAntiHarassmentSection': '防骚扰',
    'msgSettingsAntiHarassment': '防骚扰设置',
    'msgSettingsScopeSelect': '接收私信的用户范围',
    'msgSettingsValidUntil': '（该设置有效期至 {time}）',
}

ZH_HK = {
    'msgSettingsNotifSection': '通知提醒',
    'msgSettingsReplyNotify': '回覆我的訊息提醒',
    'msgSettingsReplyNotifyDesc': '（接收誰的評論訊息提醒）',
    'msgSettingsAtNotify': '@我的訊息提醒',
    'msgSettingsAtNotifyDesc': '（接收誰的@訊息提醒）',
    'msgSettingsLikeNotify': '收到的讚提醒',
    'msgSettingsLikeNotifyDesc': '（接收誰的讚訊息提醒）',
    'msgSettingsNotifyEveryone': '所有人',
    'msgSettingsNotifyFollowing': '關注的人',
    'msgSettingsNotifyNone': '不接收任何訊息提醒',
    'msgSettingsReceiveSection': '私信接收',
    'msgSettingsReceiveUnfollow': '接收未關注人訊息',
    'msgSettingsReceiveUnfollowDesc': '（若關閉此開關，你將不再收到未關注人的私信，但通知類訊息不受影響）',
    'msgSettingsUnfollowFold': '未關注人訊息摺疊',
    'msgSettingsUnfollowFoldDesc': '（未關注人訊息將被摺疊起來）',
    'msgSettingsGroupReceive': '接收應援團訊息',
    'msgSettingsGroupFold': '應援團訊息摺疊',
    'msgSettingsSmartIntercept': '私信智能攔截',
    'msgSettingsSmartInterceptDesc': '（開啟後，7日內僅會接收到指定用戶的私信、彈幕、評論，並不再接收@訊息）',
    'msgSettingsAntiHarassmentSection': '防騷擾',
    'msgSettingsAntiHarassment': '防騷擾設定',
    'msgSettingsScopeSelect': '接收私信的用戶範圍',
    'msgSettingsValidUntil': '（該設定有效期至 {time}）',
}

ZH_TW = {
    'msgSettingsNotifSection': '通知提醒',
    'msgSettingsReplyNotify': '回覆我的訊息提醒',
    'msgSettingsReplyNotifyDesc': '（接收誰的評論訊息提醒）',
    'msgSettingsAtNotify': '@我的訊息提醒',
    'msgSettingsAtNotifyDesc': '（接收誰的@訊息提醒）',
    'msgSettingsLikeNotify': '收到的讚提醒',
    'msgSettingsLikeNotifyDesc': '（接收誰的讚訊息提醒）',
    'msgSettingsNotifyEveryone': '所有人',
    'msgSettingsNotifyFollowing': '關注的人',
    'msgSettingsNotifyNone': '不接收任何訊息提醒',
    'msgSettingsReceiveSection': '私信接收',
    'msgSettingsReceiveUnfollow': '接收未關注人訊息',
    'msgSettingsReceiveUnfollowDesc': '（若關閉此開關，你將不再收到未關注人的私信，但通知類訊息不受影響）',
    'msgSettingsUnfollowFold': '未關注人訊息摺疊',
    'msgSettingsUnfollowFoldDesc': '（未關注人訊息將被摺疊起來）',
    'msgSettingsGroupReceive': '接收應援團訊息',
    'msgSettingsGroupFold': '應援團訊息摺疊',
    'msgSettingsSmartIntercept': '私信智慧攔截',
    'msgSettingsSmartInterceptDesc': '（開啟後，7日內僅會接收到指定用戶的私信、彈幕、評論，並不再接收@訊息）',
    'msgSettingsAntiHarassmentSection': '防騷擾',
    'msgSettingsAntiHarassment': '防騷擾設定',
    'msgSettingsScopeSelect': '接收私信的用戶範圍',
    'msgSettingsValidUntil': '（該設定有效期至 {time}）',
}

EN = {
    'msgSettingsNotifSection': 'Notifications',
    'msgSettingsReplyNotify': 'Reply notifications',
    'msgSettingsReplyNotifyDesc': '(Who can trigger reply notifications)',
    'msgSettingsAtNotify': 'Mention notifications',
    'msgSettingsAtNotifyDesc': '(Who can trigger @-notifications)',
    'msgSettingsLikeNotify': 'Like notifications',
    'msgSettingsLikeNotifyDesc': '(Who can trigger like notifications)',
    'msgSettingsNotifyEveryone': 'Everyone',
    'msgSettingsNotifyFollowing': 'People I follow',
    'msgSettingsNotifyNone': 'Do not notify',
    'msgSettingsReceiveSection': 'Message receiving',
    'msgSettingsReceiveUnfollow': 'DMs from non-followed users',
    'msgSettingsReceiveUnfollowDesc': '(If turned off, you will no longer receive DMs from non-followed users; notification messages are unaffected)',
    'msgSettingsUnfollowFold': 'Fold DMs from non-followed users',
    'msgSettingsUnfollowFoldDesc': '(DMs from non-followed users will be folded)',
    'msgSettingsGroupReceive': 'Receive fan-club messages',
    'msgSettingsGroupFold': 'Fold fan-club messages',
    'msgSettingsSmartIntercept': 'Smart DM filtering',
    'msgSettingsSmartInterceptDesc': '(When on, only DMs / comments / danmaku from specified users reach you for 7 days, and @-notifications are stopped)',
    'msgSettingsAntiHarassmentSection': 'Anti-harassment',
    'msgSettingsAntiHarassment': 'Anti-harassment settings',
    'msgSettingsScopeSelect': 'Who can send you DMs',
    'msgSettingsValidUntil': '(Valid until {time})',
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
    lines[-1] = lines[-1].rstrip('\n').rstrip(',') + '\n'
    return lines


for locale in LOCALES:
    path = os.path.join(ROOT, 'app_%s.arb' % locale)
    with io.open(path, encoding='utf-8') as f:
        lines = f.readlines()
    if any('"msgSettingsScopeSelect"' in ln for ln in lines):
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
