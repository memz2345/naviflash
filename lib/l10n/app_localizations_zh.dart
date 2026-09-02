// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String metroDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get metroSunday => '星期日';

  @override
  String get metroMonday => '星期一';

  @override
  String get metroTuesday => '星期二';

  @override
  String get metroWednesday => '星期三';

  @override
  String get metroThursday => '星期四';

  @override
  String get metroFriday => '星期五';

  @override
  String get metroSaturday => '星期六';

  @override
  String get metroLogin => '登录';

  @override
  String get metroWelcome => '欢迎';

  @override
  String get imageViewerNoFile => '未找到图片文件';

  @override
  String get syncPassphraseEmpty => '同步口令不能为空';

  @override
  String get imageBytesRequired => 'imageUrl 或 imageBytes 必须提供其一';

  @override
  String get webdavConnectSuccess => '✅ 连接成功！';

  @override
  String get webdavConfigSaved => '配置已保存';

  @override
  String get webdavConfigureFirst => '请先配置并测试 WebDAV 连接';

  @override
  String get webdavSelectContactsFirst => '请先在下方选择要备份的联系人';

  @override
  String get webdavNoFiles => '选中的联系人没有可备份的文件';

  @override
  String get webdavConfirmBackup => '确认备份';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return '将备份 $contacts 位联系人的 $files 个文件到 WebDAV 服务器。\n远程路径：$path/chats/<昵称>/';
  }

  @override
  String get webdavStartBackup => '开始备份';

  @override
  String get webdavBackingUpTitle => '正在备份';

  @override
  String get webdavBackupDoneTitle => '备份完成';

  @override
  String webdavTotalFiles(int count) {
    return '总计：$count 个文件';
  }

  @override
  String webdavSuccessCount(int count) {
    return '成功：$count';
  }

  @override
  String webdavFailCount(int count) {
    return '失败：$count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...还有 $count 个错误';
  }

  @override
  String get webdavBackupFab => '备份';

  @override
  String get webdavShowInfo => '显示我的信息';

  @override
  String get webdavHideInfo => '隐藏我的信息';

  @override
  String get webdavScanToFill => '扫码填入服务器地址';

  @override
  String get webdavScanFilled => '已通过扫码填入地址';

  @override
  String get webdavServerConfig => '服务器配置';

  @override
  String get webdavServerUrlLabel => '服务器地址';

  @override
  String get webdavUsernameLabel => '用户名';

  @override
  String get webdavPasswordLabel => '密码';

  @override
  String get webdavRemotePathLabel => '远程备份路径';

  @override
  String get webdavTesting => '测试中...';

  @override
  String get webdavSaveAndTest => '保存并测试连接';

  @override
  String get webdavSaveOnly => '仅保存';

  @override
  String get webdavConnectVerified => '连接验证通过';

  @override
  String get webdavAutoBackup => '自动备份';

  @override
  String get webdavAutoBackupOnReceive => '接收文件时自动备份';

  @override
  String get webdavAutoBackupSubtitle => '仅对下方选中的联系人生效';

  @override
  String get webdavMediaSync => '媒体同步';

  @override
  String get webdavSyncPlaylists => '同步播放列表';

  @override
  String get webdavSyncDanmaku => '同步弹幕';

  @override
  String get webdavPassphraseEncrypted => '同步密码（AES-256 加密）';

  @override
  String get webdavPassphrasePlain => '同步密码（留空 = 明文上传）';

  @override
  String get webdavPassphraseHint => '填写密码后播放列表将加密上传';

  @override
  String get webdavGeneratePassphrase => '生成随机密码';

  @override
  String get webdavMediaSyncHint =>
      '播放列表（含背景图）与弹幕保存到云端的独立目录（playlists/、danmaku/），不会与聊天备份混在一起。多个设备共用同一远程路径即可互相合并；播放列表可在播放列表页手动同步或从云端恢复。';

  @override
  String get webdavEncryptionOn =>
      '已启用加密：播放列表将以 AES-256-GCM 加密后上传（含内嵌的 WebDAV 鉴权信息），服务器无法读取内容。多台设备需填写相同密码才能解密。';

  @override
  String get webdavEncryptionOff =>
      '未加密：播放列表（含内嵌的 WebDAV 鉴权信息）将明文上传，任何能读取服务器文件的人都能看到，不推荐。';

  @override
  String get webdavBackupContacts => '备份联系人';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '已选 $selected / $total 位联系人';
  }

  @override
  String get webdavSearchContacts => '搜索联系人或 IP...';

  @override
  String get webdavDeselectAll => '取消全选';

  @override
  String webdavFileCount(int count) {
    return '$count 个文件';
  }

  @override
  String get webdavNoContacts => '暂无联系人';

  @override
  String get webdavNoMatch => '无匹配结果';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count 个文件';
  }

  @override
  String get webdavManage => '管理';

  @override
  String get webdavLastSync => '上次同步';

  @override
  String get webdavLastError => '最近错误';

  @override
  String get webdavClearConfig => '清除 WebDAV 配置';

  @override
  String get webdavClearConfigSubtitle => '删除所有服务器信息和凭据';

  @override
  String get webdavUserLabel => '用户';

  @override
  String webdavStatusActive(String name) {
    return '$name已激活';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name已配置';
  }

  @override
  String get webdavStatusNotConfigured => '未配置';

  @override
  String get webdavNotSynced => '尚未同步';

  @override
  String get webdavJustNow => '上次同步：刚刚';

  @override
  String webdavMinutesAgo(int minutes) {
    return '上次同步：$minutes 分钟前';
  }

  @override
  String webdavHoursAgo(int hours) {
    return '上次同步：$hours 小时前';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return '上次同步：$month月$day日 $time';
  }

  @override
  String get webdavPassphraseGenerated => '已生成同步密码并复制到剪贴板，请在其他设备上填入相同密码';

  @override
  String get webdavConfirmClear => '确认清除';

  @override
  String get webdavClearConfirmText =>
      '将删除所有 WebDAV 配置（服务器、凭据、联系人选择）。\n已上传的文件不受影响。';

  @override
  String get profileEditProfile => '编辑资料';

  @override
  String get profileAccountSection => '账户管理';

  @override
  String get profileWebdavBackup => 'WebDAV 备份';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username 已登录';
  }

  @override
  String get profileNotLoggedIn => '未登录';

  @override
  String get profileAvatarSection => '头像';

  @override
  String get profileChangeAvatar => '更换头像';

  @override
  String get profileRemoveAvatar => '移除头像';

  @override
  String get profilePickFromGallery => '从相册选择图片';

  @override
  String get profileRestoreDefaultAvatar => '恢复默认头像';

  @override
  String get profileSetBackground => '设置背景';

  @override
  String get profileBgSubtitle => '为侧边栏选择一张背景图';

  @override
  String get profileRestoreDefault => '恢复默认';

  @override
  String get profileBgRemoveSubtitle => '移除自定义背景，使用主题色渐变';

  @override
  String get profileInfoSection => '个人信息';

  @override
  String get profileNicknameLabel => '昵称';

  @override
  String get profileNotSet => '未设置';

  @override
  String get profileBgTitle => '个人资料背景';

  @override
  String get profileAvatarUpdated => '✅ 头像已更新';

  @override
  String profileAvatarFailed(String error) {
    return '❌ 选择头像失败: $error';
  }

  @override
  String get profileRemoveAvatarConfirm => '确定要删除当前头像吗？此操作无法撤销。';

  @override
  String get profileAvatarRemoved => '头像已移除';

  @override
  String get profileSetNickname => '设置昵称';

  @override
  String get profileNicknameHint => '输入昵称';

  @override
  String get profileNicknameEmpty => '昵称不能为空';

  @override
  String get profileNicknameUpdated => '✅ 昵称已更新';

  @override
  String get colorDefaultGreen => '默认绿';

  @override
  String get colorPink => '粉红色';

  @override
  String get colorRed => '红色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorYellow => '黄色';

  @override
  String get colorLime => '酸橙色';

  @override
  String get colorLightGreen => '浅绿色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '蓝绿色';

  @override
  String get colorLightBlue => '浅蓝色';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorIndigo => '靛蓝色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorBlueGrey => '蓝灰色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorGrey => '灰色';

  @override
  String get themeColorExtracted => '已从图片提取主题色';

  @override
  String themeColorFailed(String error) {
    return '取色失败: $error';
  }

  @override
  String get themeImageOnly => '仅支持图片格式';

  @override
  String get themeTitle => '主题';

  @override
  String themeColorCopied(String hex) {
    return '已复制色号: $hex';
  }

  @override
  String get themeAppearance => '外观';

  @override
  String get themeDarkBlackened => '深色模式（已黑化）';

  @override
  String get themeOff => '已关闭';

  @override
  String get themeEnabled => '已启用';

  @override
  String get themeColorsSection => '配色';

  @override
  String get themePaletteStyle => '调色板风格';

  @override
  String get themeFollowSystem => '跟随系统配色';

  @override
  String get themePickColor => '选择颜色';

  @override
  String get themeDropHint => '松开以从图片提取主题色';

  @override
  String get themeNewTheme => '新建主题';

  @override
  String themeSwitched(String name) {
    return '已切换至 $name 主题';
  }

  @override
  String get themeDeleteTitle => '删除主题';

  @override
  String themeDeleteConfirm(String name) {
    return '确定要删除自定义主题 \"$name\" 吗？';
  }

  @override
  String themeDeleted(String name) {
    return '已删除 \"$name\"';
  }

  @override
  String get themeCreateTitle => '创建自定义主题';

  @override
  String get themeNameLabel => '主题名称';

  @override
  String get themeNameHint => '请输入文本';

  @override
  String get themeHexLabel => '十六进制/RGB';

  @override
  String get themeHexHint => '例如 #FF0000 或 255,0,0';

  @override
  String themeCreated(String name) {
    return '主题 \"$name\" 已创建并保存';
  }

  @override
  String get themeCopyColor => '复制色号';

  @override
  String get themePickFromImage => '从图片取色';

  @override
  String get searchBack => '返回设置';

  @override
  String get searchHint => '搜索设置项…';

  @override
  String get searchPrompt => '输入关键词搜索设置项';

  @override
  String get searchExamples => '例如: 刷新率 / 解码 / UA / 弹幕';

  @override
  String searchNoResults(String query) {
    return '没有找到「$query」相关设置';
  }

  @override
  String get searchThemeMode => '主题模式';

  @override
  String get searchPureBlack => '纯黑深色模式';

  @override
  String get searchThemeColor => '主题配色';

  @override
  String get searchFontWeight => '文字粗细';

  @override
  String get searchDisplayScale => '显示缩放';

  @override
  String get searchDisplayMode => '显示模式 / 屏幕刷新率';

  @override
  String get searchStatusBar => '状态栏';

  @override
  String get searchKeepWindowRatio => '等比例拉伸窗口';

  @override
  String get searchLongPressSpeed => '长按键加速';

  @override
  String get searchScreenshot => '截图功能';

  @override
  String get searchScreenshotDanmaku => '截图时显示弹幕';

  @override
  String get searchPlayProgress => '播放进度';

  @override
  String get searchHwdec => '硬件解码';

  @override
  String get searchVideoSync => '视频同步';

  @override
  String get searchImmersiveLongPress => '沉浸模式长按加速';

  @override
  String get searchMpvLog => '记录 mpv 日志';

  @override
  String get searchMpvLogLevel => 'mpv 日志细度';

  @override
  String get searchNetworkMode => '网络模式';

  @override
  String get searchInsecureCert => '允许不安全证书';

  @override
  String get searchChatIpv6 => '聊天 IPv6';

  @override
  String get searchConnectivityTest => '连通性测试';

  @override
  String get searchHostOverrides => 'Host 映射';

  @override
  String get searchDohQuery => 'DoH 查询';

  @override
  String get searchReferer => '请求头 Referer';

  @override
  String get searchUserAgent => '请求头 User-Agent';

  @override
  String get searchSystemSettings => '系统设置';

  @override
  String get searchUserSettings => '用户设置';

  @override
  String get settingsDisplaySub => '主题、字体、布局';

  @override
  String get settingsSystem => '系统';

  @override
  String get settingsSystemSub => '语言、存储、权限';

  @override
  String get settingsStorage => '存储';

  @override
  String get settingsStorageSub => '图片缓存、弹幕缓存';

  @override
  String get settingsNetwork => '网络';

  @override
  String get settingsNetworkSub => 'Wi-Fi、代理、同步';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSub => '应用语言、B 站翻译（AI 翻译）';

  @override
  String get appLangSection => '应用语言';

  @override
  String get appLangFollowSystem => '跟随系统';

  @override
  String get biliLangSection => '翻译目标语言';

  @override
  String get biliAiSection => 'AI 翻译';

  @override
  String get biliAiTranslateEnable => '启用 AI 翻译';

  @override
  String get biliAiTranslateOnDesc => '已开启：B 站请求将携带翻译头，返回该语言内容';

  @override
  String get biliAiTranslateOffDesc => '关闭：按原始语言返回内容';

  @override
  String get langZhCn => '简体中文';

  @override
  String get langZhHk => '繁體中文（香港）';

  @override
  String get langZhTw => '繁體中文（台灣）';

  @override
  String get langEnUs => 'English（英語）';

  @override
  String get langJaJp => '日本語';

  @override
  String get langKoKr => '한국어';

  @override
  String get settingsPlayer => '播放器';

  @override
  String get settingsPlayerSub => '状态栏、加速、截图';

  @override
  String get settingsStartScreenSub => '开始屏幕、Charm';

  @override
  String get settingsLogs => '日志';

  @override
  String get settingsLogsSub => '错误日志、mpv 日志';

  @override
  String get settingsAccounts => '账号';

  @override
  String get settingsAccountsSub => 'B 站、WebDAV';

  @override
  String get settingsUser => '用户';

  @override
  String get settingsUserSub => '账户、隐私、安全';

  @override
  String get settingsAboutSub => '版本、许可证';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get settingsLicensesSub => '本项目引用的开源项目';

  @override
  String get settingsSearch => '搜索设置';

  @override
  String get openSidebar => '打开侧边栏';

  @override
  String get settingsPlaceholderEasterEgg => '唔,有什么问题为什么不问问神奇的芙莉莲呢';

  @override
  String storageClearTitle(String label) {
    return '清理$label';
  }

  @override
  String storageClearConfirm(String label) {
    return '确定要清理$label吗？清理后重新浏览图片会再次下载。';
  }

  @override
  String get storageClear => '清理';

  @override
  String storageCleared(String label) {
    return '$label已清理';
  }

  @override
  String get refreshAction => '刷新';

  @override
  String get storageCacheSection => '缓存';

  @override
  String get storageImageCache => '图片缓存';

  @override
  String get storageCounting => '正在统计…';

  @override
  String storageFileCount(int count, String size) {
    return '$count 个文件 · $size';
  }

  @override
  String get storageDanmakuCache => '弹幕缓存';

  @override
  String storageVideoCount(int count, String size) {
    return '$count 个视频 · $size';
  }

  @override
  String get settingsAutoOfflineCache => '自动离线缓存播放过的视频';

  @override
  String get settingsAutoOfflineCacheHint =>
      '观看过的视频会自动下载到本地（约 2GB 上限，超出自动淘汰最旧），下次打开直接从本地播放、不再重复拉取；关闭后不再新增缓存。';

  @override
  String get storageVideoCache => '离线视频缓存';

  @override
  String get storageVideoCacheDesc => '播放过的视频媒体流（容量上限内自动缓存、LRU 淘汰），下次打开直接从本地播放';

  @override
  String get storageMemoryCache => '内存图片缓存';

  @override
  String get storageMemoryCacheDesc => '本次运行中已解码的图片，退出后自动释放';

  @override
  String get storageClearing => '正在清理…';

  @override
  String get storageClearAll => '一键清理全部缓存';

  @override
  String get storageCacheHint =>
      '图片缓存为应用私有目录（image_cache），清理后浏览过的评论配图会重新下载；弹幕缓存用于离线弹幕加载。';

  @override
  String get storageClearAllTitle => '清理全部缓存';

  @override
  String get storageClearAllConfirm => '将清空图片缓存、弹幕缓存与内存图片缓存，清理后重新浏览图片会再次下载。';

  @override
  String get storageAllCleared => '缓存已全部清理';

  @override
  String get verificationPendingRequests => '待处理请求';

  @override
  String get verificationNoPending => '暂无待处理请求';

  @override
  String verificationIpAddress(String ip) {
    return 'IP 地址：$ip';
  }

  @override
  String verificationNickname(String name) {
    return '昵称：$name';
  }

  @override
  String verificationRequestTime(String time) {
    return '请求时间：$time';
  }

  @override
  String get verificationRejectInvalid => '无法拒绝：IP 地址无效';

  @override
  String get verificationRejected => '已拒绝连接请求';

  @override
  String get verificationReject => '拒绝';

  @override
  String get verificationAcceptInvalid => '无法接受：IP 地址无效';

  @override
  String get verificationAccepted => '已接受连接请求';

  @override
  String get verificationAccept => '同意';

  @override
  String get startScreenWarning => '我们可能不再更新此项目';

  @override
  String get startScreenTitle => '开始屏幕';

  @override
  String get startScreenGoBack => '转到上一层级';

  @override
  String get enableStartScreen => '启用开始屏幕';

  @override
  String get startScreenEnableSubtitle => '允许从 Charm 的 Start 按钮进入开始屏幕';

  @override
  String get enableCharm => '启用 Charm';

  @override
  String get charmEnableSubtitle => '在屏幕右侧提供 Charm 快捷栏';

  @override
  String get charmGestureTitle => '手势拉出 Charm';

  @override
  String get charmGestureSubtitle => '从屏幕右边缘向左滑动或悬停右上角拉出 Charm';

  @override
  String get externalVideo => '外部视频';

  @override
  String get audioChannelName => '视频媒体播放';

  @override
  String get foregroundChannelName => 'Navi 保活';

  @override
  String get foregroundChannelDesc => '主人~保持我后台运行~';

  @override
  String get foregroundTitle => '保活中';

  @override
  String get foregroundText => '我验牌';

  @override
  String get drawerBilibiliSearch => 'B站搜索';

  @override
  String get commentImageLoadFail => '图片加载失败';

  @override
  String get commentDetailTitle => '评论详情';

  @override
  String get commentLikeLoginRequired => '请先登录 B 站账号（并开启携带 Cookie）后再点赞';

  @override
  String commentLikeFail(String error) {
    return '点赞失败：$error';
  }

  @override
  String get relatedEmpty => '暂无相关推荐';

  @override
  String get biliLoadFailed => '加载失败';

  @override
  String countWan(String count) {
    return '$count万';
  }

  @override
  String countYi(String count) {
    return '$count亿';
  }

  @override
  String get searchNoNewContent => '暂无新内容';

  @override
  String get searchNewContentRefreshed => '已为您刷新一组新内容';

  @override
  String get biliDialogNeedLogin => '需要登录';

  @override
  String get biliDialogInteractDesc => '点赞 / 投币 / 三连等互动需要登录 B 站账号';

  @override
  String get biliGoLogin => '去登录';

  @override
  String get biliCookieScopeHint => '请在账号设置中开启「携带 Cookie 请求」与「互动操作」范围';

  @override
  String get videoTabRelated => '相关视频';

  @override
  String get videoTabComments => '评论';

  @override
  String videoTabCommentsCount(int count) {
    return '评论 $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return '选集 $count';
  }

  @override
  String get videoTabIntro => '简介';

  @override
  String danmakuWatching(String count) {
    return '$count人正在看';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '已装填$count条弹幕';
  }

  @override
  String get danmakuToggleOn => '开启弹幕';

  @override
  String get danmakuDisable => '关闭弹幕';

  @override
  String get danmakuInputHint => '发个友善的弹幕见证当下';

  @override
  String get danmakuToastEmpty => '弹幕内容不能为空';

  @override
  String danmakuToastSendFail(String error) {
    return '发送失败：$error';
  }

  @override
  String get danmakuToastSent => '弹幕已发送';

  @override
  String get videoLikeTooltip => '点赞（长按一键三连）';

  @override
  String get videoUnlikeTooltip => '取消点赞';

  @override
  String get videoCoinTooltip => '投币';

  @override
  String get videoFavTooltip => '收藏';

  @override
  String get videoUnfavTooltip => '取消收藏';

  @override
  String get videoShareLabel => '分享';

  @override
  String videoStatRating(String count) {
    return '$count人评分';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count追番';
  }

  @override
  String videoStatWatching(String count) {
    return '$count人在看';
  }

  @override
  String get videoFollowLabel => '关注';

  @override
  String get videoFollowedLabel => '已关注';

  @override
  String get commentDetailEmpty => '还没有回复';

  @override
  String commentDetailNoMore(int count) {
    return '没有更多回复了（共 $count 条）';
  }

  @override
  String get commentDetailLoadMore => '滑动加载更多';

  @override
  String get commentDetailRootBadge => '楼主';

  @override
  String get commentDetailDeleted => '(评论已删除)';

  @override
  String get commentMenuCopy => '复制评论';

  @override
  String get commentMenuSelectText => '选择文本';

  @override
  String get commentDialogTitle => '评论内容';

  @override
  String get commentDialogEmpty => '(这里空空的)';

  @override
  String get danmakuInputBvPrompt => '请输入 BV 号';

  @override
  String get danmakuInputCidPrompt => '请输入 CID';

  @override
  String get danmakuInputCidNumeric => 'CID 必须为纯数字';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return '命中本地缓存：$count 条弹幕 (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return '获取成功：$count 条弹幕 (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => '获取失败';

  @override
  String get danmakuInputTitle => 'Bilibili 弹幕';

  @override
  String get danmakuInputTypeLabel => '类型：';

  @override
  String get danmakuInputBvHint => '输入 BV 号，将自动获取第一个分P的 CID';

  @override
  String get danmakuInputCidHint => '直接输入 CID 纯数字（如从 API 获取）';

  @override
  String get danmakuInputFetching => '获取中...';

  @override
  String get danmakuInputFetchDanmaku => '获取弹幕';

  @override
  String get danmakuInputEmpty => '输入不能为空';

  @override
  String get danmakuCidFetchFail => '无法获取 CID，请检查 BV 号';

  @override
  String danmakuNoData(String oid) {
    return '未获取到弹幕数据（oid=$oid）';
  }

  @override
  String get danmakuSettingsTitle => '弹幕设置';

  @override
  String get danmakuDataSource => '数据源';

  @override
  String get danmakuDisplayControl => '显示控制';

  @override
  String get danmakuEnable => '启用弹幕';

  @override
  String get danmakuSmartMask => '智能防遮挡';

  @override
  String get danmakuSmartMaskDesc => '识别人物，弹幕不遮挡画面主体';

  @override
  String get danmakuTypeFilter => '弹幕类型';

  @override
  String get danmakuTypeScroll => '滚动弹幕';

  @override
  String get danmakuTypeTop => '顶部弹幕';

  @override
  String get danmakuTypeBottom => '底部弹幕';

  @override
  String get danmakuTypeAdvanced => '高级弹幕 (BAS)';

  @override
  String get danmakuAdvancedSubtitle => '动画弹幕，开启可能影响性能';

  @override
  String get danmakuParameters => '参数调节';

  @override
  String get danmakuScrollSpeed => '滚动速度';

  @override
  String get danmakuOpacity => '不透明度';

  @override
  String get danmakuFontSize => '字体大小';

  @override
  String get danmakuMaxLines => '显示行数';

  @override
  String danmakuLinesCount(int count) {
    return '$count 行';
  }

  @override
  String get danmakuQuickActions => '快捷操作';

  @override
  String get danmakuResetParams => '重置参数';

  @override
  String get danmakuClearDanmaku => '清空弹幕';

  @override
  String get danmakuLoadLocalXml => '加载本地 XML 弹幕';

  @override
  String get danmakuFetchOnline => '获取 Bilibili 在线弹幕';

  @override
  String get danmakuNotLoaded => '尚未加载弹幕';

  @override
  String danmakuLoadedCount(int count) {
    return '已加载 $count 条弹幕';
  }

  @override
  String get danmakuBlockColorful => '彩色弹幕';

  @override
  String get danmakuCloudFilter => '智能云屏蔽';

  @override
  String get danmakuCloudFilterOff => '关闭';

  @override
  String danmakuCloudFilterLevel(int level) {
    return '$level 级';
  }

  @override
  String get danmakuFontSizeFS => '全屏字体大小';

  @override
  String danmakuSeconds(int value) {
    return '$value 秒';
  }

  @override
  String get danmakuOthers => '其他';

  @override
  String get danmakuMassiveMode => '海量弹幕';

  @override
  String get danmakuStatic2Scroll => '固定转滚动';

  @override
  String get danmakuShowArea => '显示区域';

  @override
  String get danmakuFontWeight => '字体粗细';

  @override
  String get danmakuStrokeWidth => '描边粗细';

  @override
  String get danmakuScrollDuration => '滚动弹幕时长';

  @override
  String get danmakuStaticDuration => '静态弹幕时长';

  @override
  String get danmakuLineHeight => '弹幕行高';

  @override
  String danmakuResetTo(String value) {
    return '恢复默认：$value';
  }

  @override
  String get naviAddAction => '添加';

  @override
  String playlistImportAdded(int count) {
    return '已添加 $count 个文件';
  }

  @override
  String get playlistAddEpisodeTitle => '添加集数';

  @override
  String get playlistTitleLabel => '标题';

  @override
  String get playlistEpisodeHint => '第 1 集';

  @override
  String get playlistVideoUrlLabel => '视频 URL';

  @override
  String get playlistAdd => '添加';

  @override
  String get playlistNameRequired => '请输入播放列表名称';

  @override
  String get playlistAtLeastOneVideo => '请至少添加一个视频';

  @override
  String get playlistEditTitle => '编辑播放列表';

  @override
  String get playlistCreateTitle => '创建播放列表';

  @override
  String get playlistNameLabel => '播放列表名称';

  @override
  String get playlistNameHint => '我的追番列表';

  @override
  String get playlistWebdavMulti => 'WebDAV 多选';

  @override
  String playlistItemsCount(int count) {
    return '$count 集';
  }

  @override
  String get playlistNoItems => '还没有添加任何视频';

  @override
  String get playlistImportHint => '点击上方按钮导入';

  @override
  String get playlistSaveChanges => '保存修改';

  @override
  String get playlistEpisodePanelTitle => '选集';

  @override
  String playlistEpisodeCurrent(int index) {
    return '当前: 第 $index 集';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what：$message';
  }

  @override
  String get playlistSyncTwoWay => '双向同步播放列表';

  @override
  String get playlistSyncTwoWaySubtitle => '下载云端并合并，再上传合并结果（含背景图）';

  @override
  String get playlistRestoreFromCloud => '从云端恢复';

  @override
  String get playlistRestoreFromCloudSubtitle => '用云端数据整体覆盖本地播放列表（含背景图）';

  @override
  String get playlistUploadToCloud => '上传到云端';

  @override
  String get playlistUploadToCloudSubtitle => '把本地播放列表全量上传（含背景图，不合并）';

  @override
  String get playlistSyncDanmaku => '同步弹幕缓存';

  @override
  String get playlistSyncDanmakuSubtitle => '与云端弹幕缓存互相合并（取较新）';

  @override
  String playlistCreated(String name) {
    return '已创建: $name';
  }

  @override
  String get playlistDeleteTitle => '删除播放列表';

  @override
  String playlistDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get playlistNewTooltip => '新建播放列表';

  @override
  String get playlistListTitle => '播放列表';

  @override
  String get playlistCloudSync => '云同步';

  @override
  String get playlistMyLists => '我的列表';

  @override
  String get playlistNoLists => '暂无播放列表';

  @override
  String playlistListSummary(int count) {
    return '共 $count 个 · 点击列表查看全部剧集';
  }

  @override
  String get playlistEmptyTitle => '还没有播放列表';

  @override
  String get playlistEmptyHint => '点击右下角「创建」按钮新建一个吧';

  @override
  String get playlistResume => '续播';

  @override
  String get playlistEditAction => '编辑';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total 集 · 看到第 $current 集';
  }

  @override
  String get subtitleOff => '关闭字幕';

  @override
  String subtitleTrackFallback(String id) {
    return '轨道 $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return '已加载字幕: $name';
  }

  @override
  String get subtitleWebdavNotConfigured => 'WebDAV 未配置，请先登录';

  @override
  String get subtitleWebdavFolderEmpty => 'WebDAV 字幕文件夹为空';

  @override
  String get subtitleSelectFile => '选择字幕文件';

  @override
  String subtitleDownloadFailed(int code) {
    return '字幕下载失败: HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return '已加载远程字幕: $name';
  }

  @override
  String subtitleLoadError(String error) {
    return '字幕加载异常: $error';
  }

  @override
  String get subtitlePanelTitle => '字幕 (CC)';

  @override
  String get subtitleLoadLocal => '加载本地字幕';

  @override
  String get subtitleLoadWebdav => '从 WebDAV 加载字幕';

  @override
  String get subtitleFontSize => '字号';

  @override
  String get subtitleFontColor => '字体颜色';

  @override
  String get subtitleBgColor => '背景颜色';

  @override
  String get webdavInputPath => '输入路径';

  @override
  String get webdavGoTo => '前往';

  @override
  String get webdavLoginRequired => '请先登录 WebDAV 账号';

  @override
  String get webdavLoginSubtitle => '配置服务器后可浏览远程视频';

  @override
  String get webdavLoginSubtitleMulti => '登录后可多选远程视频创建播放列表';

  @override
  String get webdavRefresh => '刷新';

  @override
  String get webdavRoot => '根';

  @override
  String get webdavParent => '上级';

  @override
  String get webdavFolderEmpty => '此文件夹为空';

  @override
  String get webdavPullToRefresh => '下拉刷新试试?';

  @override
  String get webdavSelectVideo => '请选择视频文件';

  @override
  String get webdavPlay => '播放';

  @override
  String get webdavMultiSelectTitle => '多选文件';

  @override
  String get webdavNoSelection => '未选择文件';

  @override
  String webdavSelectedCount(int count) {
    return '已选 $count 个视频';
  }

  @override
  String webdavSelectionOrder(String names) {
    return '按选择顺序: $names';
  }

  @override
  String get webdavClear => '清空';

  @override
  String get webdavConfirmSelection => '确认选择';

  @override
  String get webdavGoLogin => '去登录';

  @override
  String get profileTitle => '个人信息';

  @override
  String get settingsAvatarTitle => '头像';

  @override
  String get settingsAvatarSet => '已设置';

  @override
  String get settingsNotSet => '未设置';

  @override
  String get settingsAvatarChangeTooltip => '更换头像';

  @override
  String get settingsAvatarDeleteTooltip => '删除头像';

  @override
  String get settingsAvatarUpdated => '头像已更新';

  @override
  String settingsPickAvatarFailed(String error) {
    return '选择头像失败：$error';
  }

  @override
  String get settingsAvatarDeleteTitle => '删除头像';

  @override
  String get settingsAvatarDeleteConfirm => '确定要删除当前头像吗？';

  @override
  String get settingsAvatarDeleteConfirmPermanent => '确定要删除当前头像吗？此操作无法撤销。';

  @override
  String get settingsAvatarDeleted => '头像已删除';

  @override
  String get settingsNickname => '昵称';

  @override
  String get settingsNicknameEditTooltip => '编辑昵称';

  @override
  String get settingsSetNickname => '设置昵称';

  @override
  String get settingsNicknamePrompt => '请输入您的昵称';

  @override
  String get settingsNicknameHint => '输入昵称';

  @override
  String get settingsNicknameEmpty => '昵称不能为空';

  @override
  String get settingsNicknameTooLong => '昵称长度不能超过 20 个字符';

  @override
  String get settingsNicknameUpdated => '昵称已更新';

  @override
  String get settingsLockWallpaper => '锁屏壁纸';

  @override
  String get settingsWallpaperCustomSet => '已设置自定义壁纸';

  @override
  String get settingsWallpaperDefaultBg => '使用默认深色背景';

  @override
  String get settingsWallpaperUpdated => '壁纸已更新';

  @override
  String get settingsWallpaperPickTooltip => '选择壁纸';

  @override
  String get settingsWallpaperDelete => '删除壁纸';

  @override
  String get settingsWallpaperDeleteConfirm => '确定要删除锁屏壁纸并恢复默认吗？';

  @override
  String get settingsWallpaperDeleted => '壁纸已删除';

  @override
  String get settingsDecoImage => '右下角装饰图';

  @override
  String get settingsDecoImageSet => '已设置 (支持透明 PNG/WebP)';

  @override
  String get settingsDecoImageUpdated => '装饰图已更新';

  @override
  String settingsPickImageFailed(String error) {
    return '选择图片失败：$error';
  }

  @override
  String get settingsPickImageTooltip => '选择图片';

  @override
  String get settingsDecoImageDelete => '删除装饰图';

  @override
  String get settingsDecoImageDeleteConfirm => '确定要删除右下角装饰图吗？';

  @override
  String get settingsDecoImageDeleted => '装饰图已删除';

  @override
  String get settingsSize => '大小';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => '透明';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => '显示';

  @override
  String get settingsDisplaySubtitle => '主题 · 配色 · 文字 · 缩放';

  @override
  String get settingsAppTheme => '应用主题';

  @override
  String settingsCurrentColor(String color) {
    return '当前配色：#$color';
  }

  @override
  String get settingsFontWeight => '文字粗细';

  @override
  String settingsCurrentFontWeight(int weight) {
    return '当前粗细：$weight';
  }

  @override
  String get settingsDisplayScale => '显示缩放';

  @override
  String settingsCurrentScale(int percent) {
    return '当前比例：$percent%';
  }

  @override
  String get settingsRestrictIp => '限制内网 IP 连接';

  @override
  String get settingsRestrictIpSubtitle => '仅允许 A 类、B 类、C 类内网 IP 地址';

  @override
  String get settingsDefaultPort => '默认端口';

  @override
  String get settingsAdjustFontWeight => '调整文字粗细';

  @override
  String settingsFontWeightPreview(int weight) {
    return '预览：$weight';
  }

  @override
  String get settingsWeightHairline => '极细';

  @override
  String get settingsWeightThin => '细';

  @override
  String get settingsWeightRegular => '常规';

  @override
  String get settingsWeightMedium => '中等';

  @override
  String get settingsWeightBold => '粗';

  @override
  String get settingsWeightBlack => '极粗';

  @override
  String get settingsFontWeightUpdated => '字体粗细已更新';

  @override
  String get logTitle => '日志';

  @override
  String get logBackTooltip => '转到上一层级';

  @override
  String get logRefresh => '刷新';

  @override
  String get logClearAll => '清空日志';

  @override
  String get logClearTitle => '清空日志';

  @override
  String get logClearConfirm => '将删除 error/ 与 mpv/ 目录下的全部日志文件，确定吗？';

  @override
  String get logClearAction => '清空';

  @override
  String logDeletedCount(int count) {
    return '已删除 $count 个日志文件';
  }

  @override
  String get logCopyContent => '复制内容';

  @override
  String get logShare => '分享日志';

  @override
  String get logDeleteThis => '删除此日志';

  @override
  String get logEmptyContent => '（空日志）';

  @override
  String logStorageLocation(String path) {
    return '存储位置：$path';
  }

  @override
  String get logErrorSection => '错误日志（崩溃必写）';

  @override
  String get logNoErrorLogs => '暂无错误日志';

  @override
  String get logMpvSection => 'mpv 日志（可选）';

  @override
  String get logNoMpvLogs => '暂无 mpv 日志';

  @override
  String get logReadingLogs => '正在读取日志…';

  @override
  String get lockFollowThemeColor => '跟随主题色 (时间)';

  @override
  String get lockShowBattery => '显示电池';

  @override
  String get lockShowNetwork => '显示网络';

  @override
  String lockDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get myQrSelectIpHint => '点击选择二维码使用的 IP';

  @override
  String get myQrNoIpType => '无该类型 IP';

  @override
  String get myQrInUse => '使用中';

  @override
  String get myQrSetAsQr => '设为二维码';

  @override
  String get netLanDiscoveryPort => '本机发现端口';

  @override
  String netDohNoRecord(String domain) {
    return '未查询到 $domain 的 A 记录';
  }

  @override
  String netDohQueryFailed(String error) {
    return '查询失败: $error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return '已保存映射: $domain → $ip';
  }

  @override
  String get netAddHostMapping => '添加 Host 映射';

  @override
  String get netDomainLabel => '域名';

  @override
  String get netIpLabel => 'IP 地址';

  @override
  String get netAdd => '添加';

  @override
  String netMappingAdded(String host, String ip) {
    return '已添加映射: $host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return '已移除映射: $host';
  }

  @override
  String get netTitle => '网络';

  @override
  String get netBackTooltip => '转到上一层级';

  @override
  String get netRetestAll => '全部重测';

  @override
  String get netConnectionModeSection => '连接模式';

  @override
  String get netNetworkMode => '网络模式';

  @override
  String get netModeStandardLabel => '标准模式';

  @override
  String get netModeCompatLabel => '兼容直连';

  @override
  String get netModeStandardDesc => '使用系统默认网络栈';

  @override
  String get netAllowInsecureCert => '允许不安全证书';

  @override
  String get netAllowInsecureCertDesc => '兼容直连时跳过证书校验 (IP 直连场景)';

  @override
  String get netChatIpv6 => '聊天 IPv6';

  @override
  String get netChatIpv6On => '已开启：支持 IPv6 聊天、发现与二维码';

  @override
  String get netChatIpv6Off => '已关闭：仅使用 IPv4 聊天';

  @override
  String get netChatIpv6EnabledSnack => '已开启聊天 IPv6（重启应用生效）';

  @override
  String get netChatIpv6DisabledSnack => '已关闭聊天 IPv6（重启应用生效）';

  @override
  String get netLocalSendCompat => 'LocalSend 兼容';

  @override
  String get netLocalSendCompatOn =>
      '已开启：启用 LocalSend 协议（端口 53317），可与 LocalSend 官方客户端互传文件';

  @override
  String get netLocalSendCompatOff => '已关闭：使用 navi 原生协议方案';

  @override
  String get netLocalSendCompatEnabledSnack => '已开启 LocalSend 兼容';

  @override
  String get netLocalSendCompatDisabledSnack => '已关闭 LocalSend 兼容（恢复原生方案）';

  @override
  String get lsSectionTitle => 'LocalSend 设备';

  @override
  String get lsHintEnable => 'LocalSend 兼容未开启';

  @override
  String get lsHintEnableDesc =>
      '开启后可与 LocalSend 官方客户端（Android/iOS/Windows/macOS/Linux）互传文件';

  @override
  String get lsEnableNow => '开启';

  @override
  String get lsEnabledSnack => '已开启 LocalSend 兼容';

  @override
  String get lsNoDevices => '未发现 LocalSend 设备';

  @override
  String get lsHttpScan => 'HTTP 扫描';

  @override
  String get lsHttpScanning => '正在扫描局域网（组播不通时的兜底）...';

  @override
  String get lsHttpScanDone => '扫描完成';

  @override
  String get lsSendFile => '发送文件';

  @override
  String get lsSendFileDesc => '通过 LocalSend 协议发送到该设备';

  @override
  String get lsProbe => '重新探测';

  @override
  String get lsProbing => '正在探测...';

  @override
  String get lsProbeFound => '探测成功';

  @override
  String get lsProbeNotFound => '设备未响应';

  @override
  String lsPickFailed(String error) {
    return '选择文件失败：$error';
  }

  @override
  String get lsNoPath => '无法获取文件路径';

  @override
  String lsSendingTitle(String alias) {
    return '正在发送到 $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '成功发送 $count 个文件';
  }

  @override
  String lsSendFailed(int count) {
    return '有 $count 个文件发送成功，其余失败';
  }

  @override
  String get lsReceiveRequestTitle => '接收文件请求';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return '对方发送了 $count 个文件，共 $size';
  }

  @override
  String get lsAccept => '接受';

  @override
  String get lsReject => '拒绝';

  @override
  String get lsOpenFile => '打开文件';

  @override
  String get lsReceiveCompleteTitle => '文件接收完成';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName 已保存到：\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return '已接收文件：$fileName';
  }

  @override
  String get netConnectivitySection => '连通性测试';

  @override
  String get netHostMappingSection => 'Host 映射';

  @override
  String get netMappingReset => '已恢复内置默认 IP 表';

  @override
  String get netRestoreDefaults => '恢复默认';

  @override
  String get netNoMappings => '暂无映射';

  @override
  String get netAddMapping => '添加映射';

  @override
  String get netDohQuerySection => 'DoH 查询';

  @override
  String get netDohQueryDesc =>
      '通过 Cloudflare JSON DNS API 查询域名 A 记录，结果可一键保存为 Host 映射';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => '保存为映射';

  @override
  String get netHeadersSection => '请求头';

  @override
  String get netRefererNotSet => '未设置 (示例: https://www.bilibili.com/)';

  @override
  String get netNotSet => '未设置';

  @override
  String netHeaderEditorTitle(String title) {
    return '设置 $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title 已保存';
  }

  @override
  String get ossTitle => '开源许可';

  @override
  String get ossBackTooltip => '转到上一层级';

  @override
  String get ossThanks => '致谢';

  @override
  String ossSummary(int count) {
    return '本项目基于 Flutter 构建，共引用 $count 个开源项目，涵盖 MIT、Apache-2.0 与 BSD-3-Clause 许可证。点击条目即可查看完整许可文本，感谢所有开源作者的无私贡献。';
  }

  @override
  String ossGroupCount(String name, int count) {
    return '$name · $count 项';
  }

  @override
  String get ossCopyFullText => '复制全文';

  @override
  String get ossLicenseCopied => '许可文本已复制到剪贴板';

  @override
  String get playHistoryTitle => '播放历史';

  @override
  String get playHistoryBackTooltip => '转到上一层级';

  @override
  String get playHistoryClearAll => '清空全部';

  @override
  String get playHistoryEmpty => '这里空空的';

  @override
  String get playHistoryEmptySub => '唔,今天真是寂寞如雪啊';

  @override
  String get playHistoryClearTitle => '清空播放历史';

  @override
  String get playHistoryClearConfirm => '您确定要删除所有保存的播放进度吗？此操作不可撤销。';

  @override
  String get playHistoryClearAction => '清空';

  @override
  String get playHistoryResume => '继续播放';

  @override
  String get playHistoryDeleteRecord => '删除记录';

  @override
  String playHistoryDeleted(String title) {
    return '已删除「$title」的播放记录';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get playerArtistVideo => '视频播放';

  @override
  String get playerArtistPlaylist => '播放列表';

  @override
  String get playerArtistWebdav => 'WebDAV 视频';

  @override
  String get playerWebdavSubtitle => 'WebDAV 字幕';

  @override
  String playerResumeFrom(String position) {
    return '已从 $position 继续播放';
  }

  @override
  String playerNowPlaying(String title) {
    return '正在播放: $title';
  }

  @override
  String playerDanmakuCache(int count) {
    return '弹幕缓存 ($count条)';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili 弹幕 ($count条)';
  }

  @override
  String get playerDanmakuNoData => '未解析到弹幕数据';

  @override
  String playerDanmakuLoaded(int count) {
    return '已加载 $count 条弹幕';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili 在线弹幕 ($count条)';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return '已从本地缓存加载 $count 条弹幕';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return '已加载 $count 条在线弹幕';
  }

  @override
  String playerScreenshotFailed(String error) {
    return '截图失败: $error';
  }

  @override
  String get playerSavedToAlbum => '已保存到相册';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return '截图 $fileName 已保存到相册';
  }

  @override
  String playerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String playerPipFailed(String error) {
    return '画中画调用失败: $error';
  }

  @override
  String get playerFitAdapt => '适配';

  @override
  String get playerFitStretch => '拉伸';

  @override
  String get playerFitFill => '填充';

  @override
  String get playerEndPause => '播完暂停';

  @override
  String get playerEndLoop => '洗脑循环';

  @override
  String get playerEndExit => '播完退出';

  @override
  String get playerSubtitleSettings => '字幕设置';

  @override
  String get playerAdvancedSettings => '高级设置';

  @override
  String get playerFlipHorizontal => '水平镜像';

  @override
  String get playerFlipHorizontalDesc => '左右翻转画面';

  @override
  String get playerFlipVertical => '垂直翻转';

  @override
  String get playerFlipVerticalDesc => '上下翻转画面';

  @override
  String get playerShowStats => '显示视频统计信息';

  @override
  String get playerShowStatsDesc => '编码/分辨率/码率/帧率';

  @override
  String get playerAutoPip => '返回桌面自动画中画';

  @override
  String get playerLoadDanmakuOnResume => '恢复播放时加载弹幕';

  @override
  String get playerLoadDanmakuOnResumeDesc => '从播放历史继续时自动读取/拉取弹幕';

  @override
  String get playerDefaultRate => '默认倍速';

  @override
  String get playerDefaultEndBehavior => '默认退出行为';

  @override
  String get playerBuffering => '缓冲中...';

  @override
  String get playerHwdecSoftware => '软解 (SW)';

  @override
  String playerHwdecHardware(String mode) {
    return '硬解 ($mode)';
  }

  @override
  String get playerSourceLocal => '本地文件';

  @override
  String get playerStatResolution => '分辨率';

  @override
  String get playerStatVideoCodec => '视频编码';

  @override
  String get playerStatAudioCodec => '音频编码';

  @override
  String get playerStatBitrate => '码率';

  @override
  String get playerStatFps => '帧率';

  @override
  String get playerStatDecode => '解码';

  @override
  String get playerStatSubtitle => '字幕';

  @override
  String get playerOn => '开启';

  @override
  String get playerOff => '关闭';

  @override
  String get playerStatDanmaku => '弹幕';

  @override
  String get playerStatDownload => '下载';

  @override
  String get playerStatSource => '来源';

  @override
  String get playerStatPosition => '进度';

  @override
  String get playerStatDuration => '时长';

  @override
  String get playerCopyLink => '复制视频链接';

  @override
  String playerCopyLinkAt(String time) {
    return '复制空降链接（$time）';
  }

  @override
  String get playerCopyLinkAt0 => '复制空降链接';

  @override
  String playerCopyLinkDone(String url) {
    return '已复制：$url';
  }

  @override
  String get playerCopyLinkNotBili => '仅 B 站视频支持复制链接';

  @override
  String get playerColorAdjust => '视频色彩调节';

  @override
  String get playerColorBrightness => '亮度';

  @override
  String get playerColorContrast => '对比度';

  @override
  String get playerColorSaturation => '饱和度';

  @override
  String get playerColorHue => '色相';

  @override
  String get playerColorGamma => '伽马';

  @override
  String get playerColorReset => '重置';

  @override
  String get playerColorUnavailable => '当前播放器不支持色彩调节';

  @override
  String get playerStats => '统计信息';

  @override
  String get playerAlignAspectRatio => '对齐宽高比';

  @override
  String get playerAlignAspectRatioDone => '窗口已对齐视频比例';

  @override
  String get playerAlignAspectRatioFailed => '无法获取视频尺寸';

  @override
  String get commonClose => '关闭';

  @override
  String get playerPlaybackError => '播放出错';

  @override
  String playerAllEpisodesPlayed(int count) {
    return '已播放完全部 $count 集';
  }

  @override
  String playerFastForwarding(String rate) {
    return '$rate 倍速播放中';
  }

  @override
  String get playerTapToSave => '点我保存';

  @override
  String get playerResetScreen => '还原屏幕';

  @override
  String get playerBackTooltip => '转到上一层级';

  @override
  String get playerRotate90 => '旋转90度';

  @override
  String get playerQuality => '画质';

  @override
  String get playerQualityLocked => '该画质不可用（需登录或大会员）';

  @override
  String get playerFullscreen => '全屏';

  @override
  String get playerBiliSubtitle => 'B站字幕';

  @override
  String get playerDecodeFormat => '解码格式';

  @override
  String get playerDecodeFormatSwitchFailed => '切换解码格式失败';

  @override
  String get playerDecodeAuto => '自动';

  @override
  String get playerDecodeAutoShort => '自动';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => '字幕加载失败';

  @override
  String get playerPortraitMode => '竖屏模式';

  @override
  String get playerLandscapeMode => '横屏模式';

  @override
  String get playerDescription => '简介';

  @override
  String get playerWebdavSource => 'WebDAV 视频源';

  @override
  String get playerCast => '投屏';

  @override
  String get playerWatchTogether => '一起看';

  @override
  String get watchInviteTitle => '邀请你一起看视频';

  @override
  String get watchWaitingAccept => '等待对方接受…';

  @override
  String get watchSelectPeer => '选择一起看的好友';

  @override
  String get watchNoOnlinePeer => '没有在线的联系人';

  @override
  String watchInviteSent(String name) {
    return '已发送一起看邀请给 $name';
  }

  @override
  String watchActiveWith(String name) {
    return '正在与 $name 一起看';
  }

  @override
  String get watchPeerRejected => '对方拒绝了你的邀请';

  @override
  String get watchPeerNoAnswer => '对方没有接受邀请';

  @override
  String get watchPeerLeft => '对方已退出一起看';

  @override
  String get watchTcpFailed => '无法建立连接，一起看失败';

  @override
  String get watchConnectionDropped => '连接已断开，一起看失败';

  @override
  String get watchUrlInvalid => '视频地址不可用，无法发起一起看';

  @override
  String get rcInviteTitle => '请求远程控制你的设备';

  @override
  String get rcInviteHint => '同意后对方可以看到你的屏幕并操作你的设备';

  @override
  String get rcPeerRejected => '对方拒绝了远程控制请求';

  @override
  String get rcTcpFailed => '无法建立连接，远程控制失败';

  @override
  String get rcConnectionDropped => '连接已断开，远程控制失败';

  @override
  String get rcTimeout => '等待对方响应超时';

  @override
  String get rcShizukuNotInstalled => '对方设备未安装 Shizuku';

  @override
  String get rcShizukuNotInstalledHint =>
      '被控端需要安装并启动 Shizuku 服务（shizuku.rikka.app）';

  @override
  String get rcShizukuGrantTitle => '需要 Shizuku 授权';

  @override
  String get rcShizukuGrantHint => '被控端授予 Navi Shizuku 权限后，对方才能远程操作屏幕';

  @override
  String get rcShizukuGrant => '授权 Shizuku';

  @override
  String get rcRequesting => '请求中…';

  @override
  String get rcShizukuNotGranted => 'Shizuku 未授权';

  @override
  String rcScreenCaptureFailed(String error) {
    return '屏幕采集失败：$error';
  }

  @override
  String get rcShareFailed => '屏幕共享失败';

  @override
  String get rcRetry => '重试';

  @override
  String get rcClose => '关闭';

  @override
  String get rcCancel => '取消';

  @override
  String get rcSend => '发送';

  @override
  String get rcConnecting => '正在连接…';

  @override
  String rcControlling(String name) {
    return '正在远程控制 $name';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name 正在远程控制你的设备';
  }

  @override
  String get rcEnd => '结束远程控制';

  @override
  String get rcConnectionLost => '远程控制连接已断开';

  @override
  String get rcSessionEnded => '远程控制已结束';

  @override
  String get rcInputText => '输入文字';

  @override
  String get rcInputTextHint => '要发送到对方设备上的文字';

  @override
  String get rcKeyBack => '返回';

  @override
  String get rcKeyHome => '主页';

  @override
  String get rcKeyRecents => '最近任务';

  @override
  String get rcKeyVolumeUp => '音量+';

  @override
  String get rcKeyVolumeDown => '音量-';

  @override
  String get dlnaPageTitle => '投屏';

  @override
  String get dlnaRefresh => '重新搜索';

  @override
  String get dlnaSearching => '正在搜索局域网投屏设备…';

  @override
  String get dlnaNoDevice => '未发现可投屏设备';

  @override
  String get dlnaNoDeviceHint => '请确认电视/盒子与本机处于同一局域网，且已开启 DLNA/投屏功能';

  @override
  String get dlnaSearchAgain => '重新搜索';

  @override
  String get dlnaFoundDevices => '发现设备';

  @override
  String dlnaCastStarted(String device) {
    return '已投屏到 $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return '投屏失败：$device';
  }

  @override
  String dlnaCastingTo(String device) {
    return '正在投屏到 $device';
  }

  @override
  String get dlnaStopCast => '停止投屏';

  @override
  String get dlnaPlay => '播放';

  @override
  String get dlnaPause => '暂停';

  @override
  String get dlnaVolumeUp => '增大音量';

  @override
  String get dlnaVolumeDown => '减小音量';

  @override
  String get dlnaFileMissing => '视频文件不存在';

  @override
  String dlnaServerStartFailed(String error) {
    return '本地文件服务启动失败：$error';
  }

  @override
  String get playerEpisodeSelect => '选集';

  @override
  String get playerDanmakuSettings => '弹幕设置';

  @override
  String get psTitle => '播放器';

  @override
  String get psBackTooltip => '转到上一层级';

  @override
  String get psStaffEntrance => '员工通道';

  @override
  String get psDisplaySection => '显示';

  @override
  String get psStatusBar => '状态栏';

  @override
  String get psStatusBarDesc => '在播放器顶部显示时间、电量与网络图标';

  @override
  String get psKeepWindowRatio => '等比例拉伸窗口';

  @override
  String get psKeepWindowRatioDesc => '播放时窗口仅允许按当前比例缩放';

  @override
  String get psKeepWindowRatioDesktopOnly => '仅 Windows / macOS / Linux 桌面平台生效';

  @override
  String get psInteractionSection => '交互';

  @override
  String get psLongPressSpeed => '长按键加速';

  @override
  String get psLongPressSpeedDesc => '按住屏幕或键盘 D 键以 2× 倍速快进';

  @override
  String get psScreenshot => '截图功能';

  @override
  String get psScreenshotDesc => '允许在播放器中截取当前画面并保存至相册';

  @override
  String get psScreenshotDanmaku => '截图时显示弹幕';

  @override
  String get psScreenshotDanmakuDesc => '截图时把当前弹幕一并截入画面';

  @override
  String get psProgressSection => '进度';

  @override
  String get psPlayProgress => '播放进度';

  @override
  String get psNoHistory => '暂无保存的播放记录';

  @override
  String psHistoryCount(int count) {
    return '您有 $count 条记录';
  }

  @override
  String get psMiscSection => '杂项';

  @override
  String get psHwdec => '硬件解码';

  @override
  String get psHwdecAuto => '自动选择最佳解码器';

  @override
  String get psHwdecSoftware => '强制使用 CPU 软件解码';

  @override
  String get psHwdecAutoShort => '自动';

  @override
  String get psHwdecPureSoftware => '纯软解';

  @override
  String get psVideoSync => '视频同步';

  @override
  String get psVsyncAudioDefault => '以音频时钟为基准（默认）';

  @override
  String get psVsyncResample => '重采样音频以匹配显示刷新率';

  @override
  String get psVsyncAdrop => '丢弃 / 重复音频帧以匹配显示';

  @override
  String get psVsyncVdrop => '丢弃 / 重复视频帧以匹配显示';

  @override
  String get psVsyncAudio => '音频';

  @override
  String get psVsyncDisplayResample => '显示重采样';

  @override
  String get psVsyncDisplayAdrop => '显示音频丢弃';

  @override
  String get psVsyncDisplayVdrop => '显示视频丢弃';

  @override
  String get psImmersiveLongPress => '沉浸模式长按加速';

  @override
  String get psImmersiveLongPressDesc => '控制栏隐藏时仍可通过长按触发 2× 倍速';

  @override
  String get psLogSection => '日志';

  @override
  String get psMpvLog => '记录 mpv 日志';

  @override
  String psMpvLogEnabled(String level) {
    return '已开启，下次播放生效（细度：$level）';
  }

  @override
  String get psMpvLogDisabled => '关闭。崩溃日志始终记录，不受此开关影响';

  @override
  String get psMpvLogLevel => 'mpv 日志细度';

  @override
  String get psMpvLogLevelDesc => '细度越高日志越详细，占用空间也越大';

  @override
  String get psMpvLogError => '仅错误';

  @override
  String get psMpvLogWarn => '警告';

  @override
  String get psMpvLogWarnDefault => '警告（默认）';

  @override
  String get psMpvLogInfo => '信息';

  @override
  String get psMpvLogVerbose => '详细';

  @override
  String get psMpvLogDebug => '调试';

  @override
  String get psMpvLogTrace => '全部（极详细）';

  @override
  String get psViewLogs => '查看日志';

  @override
  String get psViewLogsDesc => '浏览错误日志与 mpv 日志，支持分享与清除';

  @override
  String testPlaylistCreated(String name) {
    return '已创建: $name';
  }

  @override
  String get testPageTitle => '测试页';

  @override
  String get testVideoSourceSection => '视频来源';

  @override
  String get testVideoSourceSubtitle => '选择一个来源开始播放';

  @override
  String get testWebdavVideo => 'WebDAV 视频';

  @override
  String get testWebdavVideoDesc => '从 WebDAV 服务器浏览并播放';

  @override
  String get testLocalVideo => '本地视频';

  @override
  String get testLocalVideoDesc => '从设备存储中选择视频文件';

  @override
  String get testRecentSection => '最近播放';

  @override
  String get testLastPlayedSubtitle => '上次播放记录';

  @override
  String get testNoRecords => '暂无播放记录';

  @override
  String get testPlaylistSection => '播放列表';

  @override
  String get testPlaylistSectionSubtitle => '创建、管理播放列表，选集播放';

  @override
  String get testPlaylistManage => '播放列表管理';

  @override
  String get testPlaylistManageDesc => '查看 / 编辑 / 删除播放列表，点击直接播放';

  @override
  String get testPlaylistCreate => '新建播放列表';

  @override
  String get testPlaylistCreateDesc => 'WebDAV 多选文件建表 / 手动逐集导入';

  @override
  String get testQuickActionsSection => '快捷操作';

  @override
  String get testQuickActionsSubtitle => '常用测试入口';

  @override
  String get testUrlDirectPlay => 'URL 直接播放';

  @override
  String get testUrlDirectPlayDesc => '输入视频 URL 直接播放';

  @override
  String get testVideoWithSubtitle => '视频 + 字幕';

  @override
  String get testVideoWithSubtitleDesc => '同时选择视频和字幕文件';

  @override
  String get testNoVideoPlayed => '还没有播放过任何视频';

  @override
  String get testEnterUrlTitle => '输入视频 URL';

  @override
  String get testPlay => '播放';

  @override
  String get testAddSubtitleTitle => '添加字幕？';

  @override
  String testAddSubtitlePrompt(String name) {
    return '已选择视频：$name\n是否要加载外挂字幕？';
  }

  @override
  String get testSkip => '跳过';

  @override
  String get testSelectSubtitle => '选择字幕';

  @override
  String get testAboutLegalese => '播放器前端测试页面';

  @override
  String get testAboutBody =>
      '此页面用于测试 MpvPlayerPage 的各种入口：\n• WebDAV 远程视频\n• 本地视频文件\n• URL 直接播放\n• 视频 + 外挂字幕';

  @override
  String get testSourceLocal => '本地文件';

  @override
  String get testSourceLocalSubtitle => '本地 + 字幕';

  @override
  String get accountsBiliLoginSuccess => 'B 站登录成功';

  @override
  String get accountsBiliLogoutTitle => '退出 B 站登录？';

  @override
  String get accountsBiliLogoutHint => '退出后将不再携带 Cookie 请求 B 站 API。';

  @override
  String get accountsClearWebviewCookieTitle => '同时清空内置浏览器 Cookie';

  @override
  String get accountsClearWebviewCookieSubtitle => '不勾选也没关系，之后可在账号设置里手动清除';

  @override
  String get accountsLogout => '退出';

  @override
  String get accountsLoggedOutWithCookie => '已退出登录并清空浏览器 Cookie';

  @override
  String get accountsLoggedOut => '已退出登录';

  @override
  String get accountsClearCookieTitle => '清空内置浏览器 Cookie？';

  @override
  String get accountsClearCookieContent => '将清除内置浏览器保存的全部 Cookie，包括网页端的登录状态。';

  @override
  String get accountsClearAction => '清空';

  @override
  String get accountsCookieCleared => '已清空内置浏览器 Cookie';

  @override
  String get accountsCookieEmpty => '暂无内置浏览器 Cookie 可清（浏览器未使用过）';

  @override
  String get accountsBiliLoginTitle => '登录 B 站账号';

  @override
  String get accountsBiliLoginSubtitle => '扫码 / 粘贴 Cookie / 密码登录';

  @override
  String get accountsClearBrowserCookie => '清空内置浏览器 Cookie';

  @override
  String get accountsClearBrowserCookieSubtitle => '清除网页端残留登录态';

  @override
  String get accountsLoggedIn => '已登录';

  @override
  String accountsLoggedInUid(int mid) {
    return '已登录 · UID $mid';
  }

  @override
  String get accountsCarryCookie => '携带 Cookie 请求';

  @override
  String get accountsCarryCookieOn => '已开启：B 站 API 以登录身份请求';

  @override
  String get accountsCarryCookieOff => '已关闭：B 站 API 以游客身份请求';

  @override
  String get accountsCookieScope => 'Cookie 使用范围';

  @override
  String get accountsCookieScopeSubtitle => '选择哪些请求使用账号 Cookie';

  @override
  String get cookieScopeTitle => 'Cookie 使用范围';

  @override
  String get cookieScopeHint =>
      '仅影响以下请求类型；「携带 Cookie 请求」总开关关闭时，下列设置不生效。B 站在线收藏夹操作始终携带登录 Cookie。';

  @override
  String get cookieScopeVideo => '视频详情与播放';

  @override
  String get cookieScopeVideoDesc => '视频详情、播放地址与历史进度上报';

  @override
  String get cookieScopeComments => '评论';

  @override
  String get cookieScopeCommentsDesc => '评论区列表请求';

  @override
  String get cookieScopeSearch => '搜索';

  @override
  String get cookieScopeSearchDesc => '搜索建议与搜索结果请求';

  @override
  String get cookieScopeArticle => '专栏与动态';

  @override
  String get cookieScopeArticleDesc => '专栏文章与动态内容请求';

  @override
  String get cookieScopeUserSpace => '用户空间';

  @override
  String get cookieScopeUserSpaceDesc => 'UP 主空间、投稿与粉丝列表请求';

  @override
  String get cookieScopeSeason => '番剧与剧集';

  @override
  String get cookieScopeSeasonDesc => '番剧详情与剧集列表请求';

  @override
  String get cookieScopeInteractions => '互动操作';

  @override
  String get cookieScopeInteractionsDesc => '点赞、投币、收藏、关注、发送弹幕等；关闭后无法互动';

  @override
  String get cookieScopeEnableAll => '全部开启';

  @override
  String get cookieScopeDisableAll => '全部关闭';

  @override
  String get accountsWebdavCloud => 'WebDAV 云盘';

  @override
  String get accountsWebdavConfiguredOn => '已配置 · 自动备份已开启';

  @override
  String get accountsWebdavConfiguredOff => '已配置 · 自动备份未开启';

  @override
  String get accountsWebdavNotConfigured => '未配置 · 点击进入设置';

  @override
  String get accountsTitle => '账号';

  @override
  String get accountsSectionBili => 'B 站账号';

  @override
  String get commonBackTooltip => '转到上一层级';

  @override
  String get biliLoginFetchingQr => '正在获取二维码…';

  @override
  String get biliLoginQrFetchFailed => '获取二维码失败，请检查网络';

  @override
  String get biliLoginScanWithApp => '请使用 B 站 App 扫码登录';

  @override
  String get biliLoginInputAccountPwd => '请输入账号和密码';

  @override
  String get biliLoginFailedRetry => '登录失败，请重试';

  @override
  String get biliLoginTitle => 'B 站登录';

  @override
  String get biliLoginScanMode => '扫码登录';

  @override
  String get biliLoginCookieMode => '粘贴 Cookie';

  @override
  String get biliLoginPwdMode => '密码登录';

  @override
  String get biliLoginViaBrowser => '使用内置浏览器登录';

  @override
  String get biliLoginCookieHint => '登录后「携带 Cookie 请求」默认开启，可在 设置 → 账号 中关闭';

  @override
  String get biliLoginWebTitle => '网页版登录';

  @override
  String get biliLoginCookieImportFailed => '网页登录 Cookie 导入失败，请重试或改用其他方式';

  @override
  String get biliLoginRefetch => '重新获取';

  @override
  String get biliLoginRefreshQr => '刷新二维码';

  @override
  String get biliLoginScanTip => '提示：打开 B 站 App → 扫一扫，或用「哔哩哔哩」小程序扫码';

  @override
  String get biliLoginCookieInstruction =>
      '在电脑浏览器登录 bilibili.com，按 F12 打开开发者工具 → Application → Cookies → bilibili.com，复制全部 Cookie（以 SESSDATA= 开头的一串），粘贴到下方输入框';

  @override
  String get biliLoginVerifying => '校验中…';

  @override
  String get biliLoginVerifyAndLogin => '登录并校验';

  @override
  String get biliLoginAccountLabel => '账号（手机号 / 邮箱 / 用户名）';

  @override
  String get biliLoginPasswordLabel => '密码';

  @override
  String get biliLoginLoggingIn => '登录中…';

  @override
  String get biliLoginLoginAction => '登录';

  @override
  String get biliLoginSliderHint => '账号密码登录可能触发滑块验证码，完成验证后会自动重试';

  @override
  String get searchFilterAny => '不限';

  @override
  String get searchFilterLastDay => '最近一天';

  @override
  String get searchFilterLastWeek => '最近一周';

  @override
  String get searchFilterHalfYear => '最近半年';

  @override
  String get searchFilterAllDuration => '全部时长';

  @override
  String get searchFilterDur0to10 => '0-10分钟';

  @override
  String get searchFilterDur10to30 => '10-30分钟';

  @override
  String get searchFilterDur30to60 => '30-60分钟';

  @override
  String get searchFilterDur60plus => '60分钟+';

  @override
  String get searchZoneAll => '全部';

  @override
  String get searchZoneAnime => '动画';

  @override
  String get searchZoneGuochuang => '国创';

  @override
  String get searchZoneMusic => '音乐';

  @override
  String get searchZoneDance => '舞蹈';

  @override
  String get searchZoneGame => '游戏';

  @override
  String get searchZoneKnowledge => '知识';

  @override
  String get searchZoneTech => '科技';

  @override
  String get searchZoneSports => '运动';

  @override
  String get searchZoneCar => '汽车';

  @override
  String get searchZoneLife => '生活';

  @override
  String get searchZoneFood => '美食';

  @override
  String get searchZoneAnimal => '动物';

  @override
  String get searchZoneKichiku => '鬼畜';

  @override
  String get searchZoneFashion => '时尚';

  @override
  String get searchZoneInfo => '资讯';

  @override
  String get searchZoneEnt => '娱乐';

  @override
  String get searchZoneDoc => '记录';

  @override
  String get searchZoneFilm => '电影';

  @override
  String get searchZoneTv => '电视';

  @override
  String get searchCaptchaInitFailed => '验证码初始化失败';

  @override
  String get searchCaptchaIncomplete => '未完成滑块验证';

  @override
  String get searchCaptchaValidateFailed => '验证码校验失败';

  @override
  String get searchCaptchaValidateFailedRetry => '验证码校验失败，请重试';

  @override
  String get searchCaptchaPassed => '验证通过，正在重新搜索';

  @override
  String get searchBiliHint => '搜索 B 站…';

  @override
  String get searchHistoryTitle => '搜索历史';

  @override
  String get searchHistoryClear => '清空';

  @override
  String get searchHistoryClearConfirm => '确定清空当前分区的搜索历史？';

  @override
  String get searchHistoryEmpty => '暂无搜索历史';

  @override
  String get searchVideoFilter => '视频搜索筛选';

  @override
  String searchFilterWithCount(int count) {
    return '筛选 · $count';
  }

  @override
  String get searchFilter => '筛选';

  @override
  String get searchSwitchSingleCol => '单列';

  @override
  String get searchSwitchMulti => '多列';

  @override
  String get searchLayoutMulti => '多列';

  @override
  String get searchLayoutSingle => '单列';

  @override
  String get searchPickStartDate => '选择开始日期';

  @override
  String get searchPickEndDate => '选择结束日期';

  @override
  String get searchPubTimeSection => '发布时间';

  @override
  String get searchDateBegin => '开始';

  @override
  String get searchDateTo => '至';

  @override
  String get searchDateEnd => '结束';

  @override
  String get searchDurationSection => '内容时长';

  @override
  String get searchZoneSection => '内容分区';

  @override
  String get searchAntiFuzzy => '防模糊搜索';

  @override
  String get searchAntiFuzzyHint => '限定 2009-06-26 至今的结果，避免异常早期数据干扰';

  @override
  String get searchFilterReset => '重置';

  @override
  String get searchAllLoaded => '— 已全部加载 —';

  @override
  String get searchKeywordHint => '输入关键词搜索 B 站';

  @override
  String get searchPressToSearch => '点击「搜索」或回车开始搜索';

  @override
  String searchNoResultInType(String keyword, String type) {
    return '「$keyword」在$type中暂无结果';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · 共 $count 个结果';
  }

  @override
  String get userSpaceLoadFailed => '加载失败';

  @override
  String get userSpaceAvatarLoadFailed => '头像加载失败';

  @override
  String get userSpaceTitle => 'UP 主空间';

  @override
  String get userSpaceLoading => '正在加载 UP 主空间…';

  @override
  String get userSpaceLoadingName => '加载中…';

  @override
  String get userSpaceStatFans => '粉丝';

  @override
  String get userSpaceStatFollowing => '关注';

  @override
  String get userSpaceStatVideos => '视频';

  @override
  String get userSpaceStatLikes => '获赞';

  @override
  String userSpaceVideoCount(int count) {
    return '共 $count 个视频';
  }

  @override
  String get userSpaceSectionAllVideos => '全部视频';

  @override
  String get userSpaceNoVideos => '暂无投稿';

  @override
  String get userSpaceDynLoadFailed => '动态加载失败';

  @override
  String get userSpaceNoDynamics => '暂无动态';

  @override
  String get userSpaceBangumiLoadFailed => '追番列表加载失败';

  @override
  String get userSpaceNoBangumi => '暂无追番';

  @override
  String userSpaceBangumiCount(int count) {
    return '追番 · 共 $count 部';
  }

  @override
  String get userSpaceLazySign => '这个人很懒，什么都没有留下';

  @override
  String get userSpaceTabHome => '主页';

  @override
  String get userSpaceTabDynamic => '动态';

  @override
  String get userSpaceTabBangumi => '追番';

  @override
  String get userSpaceToday => '今天';

  @override
  String get userSpaceBangumiFinished => '完结';

  @override
  String get userSpaceBangumiSerializing => '连载中';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return '开播 $date';
  }

  @override
  String get browserApp => '应用';

  @override
  String browserOpenAppAttempt(String app) {
    return '网页尝试打开: $app';
  }

  @override
  String get browserNoAppForLink => '未找到可打开该链接的应用';

  @override
  String get browserOpenFailedSystem => '打开失败: 未安装对应应用或受系统限制';

  @override
  String get browserEmptyCookieHint => '这里空空的';

  @override
  String get browserCopyAll => '复制全部';

  @override
  String get browserCookieCopied => 'Cookie已复制';

  @override
  String get browserCookieEmpty => 'Cookie空空的';

  @override
  String get browserSetUaTitle => '设置 User-Agent';

  @override
  String get browserUaHint => '输入自定义 User-Agent';

  @override
  String get browserApplyAndReload => '应用并刷新';

  @override
  String get browserUaUpdated => 'UA 已更新并刷新页面';

  @override
  String browserUaSetFailed(String error) {
    return '设置 UA 失败: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView 初始化失败，请检查 WebView2 是否已安装';

  @override
  String get browserBiliCookieReadFailed =>
      '未能读取到完整登录 Cookie（SESSDATA 为 HttpOnly，当前平台无法自动读取），请改用扫码登录或粘贴 Cookie';

  @override
  String get browserCookieImportFailed => 'Cookie 导入失败，请重试';

  @override
  String get browserStoppedLoading => '已停止加载';

  @override
  String get browserClipboardAllowed => '已允许网页写入剪贴板';

  @override
  String get browserClipboardBlocked => '已禁止网页自动写入剪贴板';

  @override
  String get browserNoCurrentUrl => '无法获取当前链接';

  @override
  String get browserTroubleshootFailed => '打开失败,请检查\"获取帮助\"是否存在';

  @override
  String get browserSystemBrowserMissing => '系统浏览器不见了(';

  @override
  String get browserQrTitle => '扫我';

  @override
  String get browserSaveToDevice => '保存到设备';

  @override
  String get browserQrSaved => '二维码已保存到相册/图片库';

  @override
  String browserSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get browserStopLoading => '停止加载';

  @override
  String get browserImporting => '导入中…';

  @override
  String get browserLoginDoneImport => '登录完成，导入';

  @override
  String get browserClipboardAccess => '剪贴板访问';

  @override
  String get browserShareQr => '分享二维码';

  @override
  String get browserCopyLink => '复制链接';

  @override
  String get browserViewCookies => '查看 Cookies';

  @override
  String get browserSetUa => '设置 UA';

  @override
  String get browserUaModeAuto => '自动（跟随系统）';

  @override
  String get browserUaModeDesktop => '电脑端';

  @override
  String get browserUaModeMobile => '手机端';

  @override
  String get browserRefresh => '刷新';

  @override
  String get browserSystemBrowser => '系统浏览器';

  @override
  String get browserTroubleshootNetwork => '检测连接问题';

  @override
  String get browserUnsupportedPlatform => '当前平台不支持内嵌浏览器';

  @override
  String get browserOpenedInSystem => '已尝试在系统浏览器中打开';

  @override
  String get browserReopenInSystem => '重新用系统浏览器打开';

  @override
  String get browserAndroidErrorTitle => '沒有指令';

  @override
  String get browserAndroidErrorCause => '原因';

  @override
  String get browserAndroidErrorDetail =>
      'WebView 组件初始化失败\n可能是系统 WebView 未更新或已停用';

  @override
  String get browserUpdateWebview => '前往 Google Play 更新 Android System WebView';

  @override
  String get browserOpenDevOptions => '打开开发者选项查看 WebView 实现';

  @override
  String get browserAppleErrorTitle => '應用程式未預期的結束';

  @override
  String get browserAppleErrorReport => '問題報告';

  @override
  String get browserAppleErrorDetail => '無法在此裝置上初始化內嵌瀏覽器。請確認作業系統已更新至最新版本。';

  @override
  String get browserBsodMessage => '你的 Webview2 遇到问题，我们需要收集一些错误信息，然后为你重启应用。';

  @override
  String get browserBsodNoRestart => '(其实不用重启，安装完组件即可)';

  @override
  String get browserBsodComplete => '100% 完成';

  @override
  String get browserBsodSolutions => '查看解决方案：';

  @override
  String get browserBsodDownload => '下载 Webview2 运行时';

  @override
  String get browserBsodWinUpdate => '打开 Windows 更新设置';

  @override
  String get browserBsodScanQr => '扫描此 QR 码获取解决方案';

  @override
  String get browserBsodStopCode => '终止代码：WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => '无法打开外部链接';

  @override
  String get callOutgoing => '正在呼叫...';

  @override
  String get callIncoming => '来电...';

  @override
  String get callConnecting => '连接中...';

  @override
  String get chatConnectionNotEstablishedImage => '连接未建立，无法发送图片';

  @override
  String get chatImageSent => '✅ 图片已发送';

  @override
  String get chatImageSendFailed => '发送图片失败';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return '处理剪贴板图片失败：$error';
  }

  @override
  String get chatImageStaged => '🖼️ 图片已添加至输入框';

  @override
  String get chatClipboardNoImage => '剪贴板无图片数据';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return '获取剪贴板图片失败：$error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported => '剪贴板为空或格式不支持';

  @override
  String get chatConnectionNotEstablishedFile => '连接未建立，无法发送文件';

  @override
  String get chatFileNotExist => '文件不存在';

  @override
  String get chatFileSendFailed => '发送文件失败';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName 发送成功';
  }

  @override
  String chatFileSendError(String error) {
    return '发送文件失败：$error';
  }

  @override
  String get chatIpUnknown => 'IP 未知';

  @override
  String get chatReconnecting => '正在重新建立连接...';

  @override
  String get chatReconnectFailed => '重连失败，请检查网络或对方是否在线';

  @override
  String get chatStatusUnknown => '状态未知';

  @override
  String get chatStatusWaiting => '等待连接';

  @override
  String get chatMe => '我';

  @override
  String get chatFileInfoLost => '(文件信息丢失)';

  @override
  String chatOpenFileFailed(String message) {
    return '无法打开文件：$message';
  }

  @override
  String get chatFileNotDownloaded => '文件尚未下载';

  @override
  String chatOpenFileError(String error) {
    return '打开文件失败：$error';
  }

  @override
  String get chatFilePathUnavailable => '无法获取文件路径 (安卓权限限制?)';

  @override
  String chatPickFileFailed(String error) {
    return '选择文件失败：$error';
  }

  @override
  String get chatImagePathUnavailable => '无法获取图片路径';

  @override
  String chatPickImageFailed(String error) {
    return '选择图片失败：$error';
  }

  @override
  String get chatCopyText => '复制文本';

  @override
  String get chatSelectText => '选择文本';

  @override
  String get chatOpenFile => '打开文件';

  @override
  String get chatCopyImage => '复制图片';

  @override
  String get chatSaveImage => '保存图片';

  @override
  String get chatCopyingImage => '正在复制图片...';

  @override
  String get chatImageCopied => '✅ 图片已复制到剪贴板';

  @override
  String get chatCopyFailed => '复制失败';

  @override
  String chatCopyImageFailed(String error) {
    return '复制图片失败: $error';
  }

  @override
  String get chatSaving => '正在保存...';

  @override
  String get chatSaveSuccess => '✅ 保存成功';

  @override
  String chatSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get chatMessageContent => '消息内容';

  @override
  String get chatEmptyContent => '(这里空空的)';

  @override
  String get chatDeleteMessageConfirm => '主人确定要删除这条消息吗？';

  @override
  String get chatMessageDeleted => '消息已删除';

  @override
  String get chatOpenLinkTitle => '打开链接';

  @override
  String chatWillOpen(String url) {
    return '将打开：$url';
  }

  @override
  String get chatBrowserTitle => '内置网页浏览器';

  @override
  String get chatCantOpenLink => '无法打开链接';

  @override
  String chatOpenLinkFailed(String error) {
    return '打开链接失败：$error';
  }

  @override
  String get chatPlusImage => '图片';

  @override
  String get chatPlusFile => '文件';

  @override
  String get chatImageReady => '图片已就绪';

  @override
  String get chatMore => '更多';

  @override
  String get chatPasteImage => '粘贴图片';

  @override
  String get chatInputHint => '输入消息...';

  @override
  String get chatEmoji => '表情符号';

  @override
  String get chatSend => '发送';

  @override
  String get chatInvalidAddress => '连接地址无效，无法发送';

  @override
  String get chatImageSendError => '图片发送失败';

  @override
  String chatSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String get chatConnStatusUnknown => '连接状态未知，无法发送消息';

  @override
  String get chatPendingCannotSend => '等待对方验证，无法发送消息';

  @override
  String get chatConnRejected => '连接已被拒绝';

  @override
  String get chatConnDisconnected => '对方已断开连接';

  @override
  String get chatConnNotEstablished => '连接尚未建立，无法发送消息';

  @override
  String get chatNoMessages => '暂无消息，开始聊天吧';

  @override
  String get chatDisconnectedRetry => '连接已断开，点击尝试重连';

  @override
  String get chatRejectedRetry => '连接被拒绝，点击重试';

  @override
  String get chatExpandInput => '展开输入栏';

  @override
  String get discoverMyLanIps => '我的局域网 IP';

  @override
  String get discoverNoIpOfType => '未找到该类型的有效 IP，请检查网络连接。';

  @override
  String discoverIpCopied(String ip) {
    return '已复制 $ip';
  }

  @override
  String get discoverTitle => '发现附近设备';

  @override
  String get discoverMyIp => '我的 IP';

  @override
  String get discoverRefreshBroadcast => '刷新/广播';

  @override
  String get discoverLanDevices => '局域网设备';

  @override
  String get discoverSearching => '正在寻找附近的设备...';

  @override
  String get discoverSendRequest => '点击发送连接请求';

  @override
  String get discoverPendingVerify => '等待对方验证...';

  @override
  String get discoverRejectedRetry => '已被拒绝，点击重试';

  @override
  String get discoverDisconnectedRetry => '已断开，点击重连';

  @override
  String get discoverUnknownDevice => '未知设备';

  @override
  String get discoverAlreadyConnected => '该设备已连接';

  @override
  String get discoverAlreadyPending => '正在等待对方验证，请勿重复发送';

  @override
  String get discoverConnectFailed => '连接失败，请检查网络或对方是否在线';

  @override
  String get discoverManualConnect => '手动连接到对等端';

  @override
  String get discoverConnectIpHint => '输入 IP 地址（例如：192.168.1.100 / fe80::1）';

  @override
  String get displayScaleCompact => '紧凑模式 · 显示更多内容';

  @override
  String get displayScaleSmall => '略小 · 适合大屏';

  @override
  String get displayScaleDefault => '默认';

  @override
  String get displayScaleLarge => '略大 · 更易阅读';

  @override
  String get displayScaleLargeFont => '大字体 · 无障碍友好';

  @override
  String get displayScaleHuge => '超大 · 辅助功能';

  @override
  String get displayScaleMin => '最小 · 信息密度最高';

  @override
  String get displayScaleCompactBig => '紧凑 · 适合大屏';

  @override
  String get displayScaleSystemDefault => '系统默认';

  @override
  String get displayScaleLargeFontShort => '大字体 · 无障碍';

  @override
  String get displayScaleTitle => '显示缩放';

  @override
  String get displayHeroTransitionBlur => '使用新版动画';

  @override
  String get displayIosPushTransition => 'iOS 风格页面切换';

  @override
  String get displayIosPushTransitionCorner => '转场圆角';

  @override
  String get searchIosPushTransition => 'iOS 页面切换动画';

  @override
  String get pageBgTitle => '页面背景图';

  @override
  String get pageBgSubtitle => '设置类页面共用的背景图，选择后可裁剪';

  @override
  String get pageBgEnabled => '显示页面背景图';

  @override
  String get pageBgOpacity => '背景强度';

  @override
  String get pageBgBlur => '背景模糊';

  @override
  String get pageBgNotSet => '未设置';

  @override
  String get pageBgPick => '选择并裁剪图片';

  @override
  String get pageBgClear => '清除背景图';

  @override
  String get pageBgSaved => '背景图已更新';

  @override
  String get pageBgCleared => '背景图已清除';

  @override
  String get pageBgPickFailed => '选择图片失败';

  @override
  String get cropTitle => '裁剪背景图';

  @override
  String get cropAspectFree => '自由';

  @override
  String get cropApply => '应用';

  @override
  String get cropReset => '重置';

  @override
  String get displayAdvancedGlass => '高级渲染';

  @override
  String get displayDisableLiquidGlassMenus => '减弱效果';

  @override
  String get displayLiquidGlassTuner => '液态玻璃调校';

  @override
  String get displayLiquidGlassTunerSubtitle => '调节玻璃厚度、模糊、着色、折射率等材质参数';

  @override
  String get lgTunerPreview => '实时预览';

  @override
  String get lgTunerSectionMaterial => '材质参数';

  @override
  String get lgTunerThickness => '玻璃厚度';

  @override
  String get lgTunerBlur => '背景模糊';

  @override
  String get lgTunerTint => '着色强度';

  @override
  String get lgTunerSaturation => '饱和度';

  @override
  String get lgTunerRefractiveIndex => '折射率';

  @override
  String get lgTunerLightIntensity => '高光强度';

  @override
  String get lgTunerAmbient => '环境光';

  @override
  String get lgTunerLightAngle => '光源角度';

  @override
  String get lgTunerAberration => '色散';

  @override
  String get lgTunerReset => '恢复默认';

  @override
  String get lgTunerNote =>
      '调整即时生效并全局应用：未单独指定参数的玻璃表面（下拉菜单、弹窗等）都会跟随；聊天页顶栏等显式设定的表面保持独立样式。';

  @override
  String get lgTunerFallbackNote =>
      '当前平台不支持高级玻璃渲染（Impeller），预览为 FakeGlass 效果；厚度、折射率、饱和度等参数仅移动端生效。';

  @override
  String get displayScaleReset => '重置为 100%';

  @override
  String get displayScaleFineTune => '精细调节';

  @override
  String get displayScalePresets => '快捷预设';

  @override
  String get displayScaleNote =>
      '缩放比例会全局应用于文字与部分布局尺寸。设为 100% 可恢复默认。修改即时生效，无需重启。';

  @override
  String displayScaleConnCount(int count) {
    return '$count 个连接';
  }

  @override
  String get displayThemeLight => '浅色';

  @override
  String get displayThemeDark => '深色';

  @override
  String get displaySettingsTitle => '显示';

  @override
  String get displaySectionAppearance => '外观';

  @override
  String get displayThemeMode => '主题模式';

  @override
  String get displayPureBlack => '纯黑深色模式';

  @override
  String get displayPureBlackOn => '深色模式（已黑化）';

  @override
  String get displayOff => '已关闭';

  @override
  String get displaySectionPersonalize => '个性化';

  @override
  String get displayThemeColor => '主题配色';

  @override
  String get displayFollowSystemColor => '跟随系统配色';

  @override
  String get displayFontWeight => '文字粗细';

  @override
  String get displaySeedDefaultGreen => '默认绿';

  @override
  String get displaySeedPink => '粉红色';

  @override
  String get displaySeedRed => '红色';

  @override
  String get displaySeedOrange => '橙色';

  @override
  String get displaySeedAmber => '琥珀色';

  @override
  String get displaySeedYellow => '黄色';

  @override
  String get displaySeedLime => '酸橙色';

  @override
  String get displaySeedLightGreen => '浅绿色';

  @override
  String get displaySeedGreen => '绿色';

  @override
  String get displaySeedCyan => '青色';

  @override
  String get displaySeedTeal => '蓝绿色';

  @override
  String get displaySeedLightBlue => '浅蓝色';

  @override
  String get displaySeedBlue => '蓝色';

  @override
  String get displaySeedIndigo => '靛蓝色';

  @override
  String get displaySeedPurple => '紫色';

  @override
  String get displaySeedDeepPurple => '深紫色';

  @override
  String get displaySeedBlueGrey => '蓝灰色';

  @override
  String get displaySeedBrown => '棕色';

  @override
  String get displaySeedGrey => '灰色';

  @override
  String get displaySeedCustom => '自定义';

  @override
  String displayWeightThin(int weight) {
    return '极细 ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return '细 ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return '常规 ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return '中等 ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return '粗 ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return '极粗 ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return '自定义 ($weight)';
  }

  @override
  String get fontWeightThin => '极细';

  @override
  String get fontWeightLight => '细';

  @override
  String get fontWeightRegular => '常规';

  @override
  String get fontWeightMedium => '中等';

  @override
  String get fontWeightBold => '粗';

  @override
  String get fontWeightBlack => '极粗';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\n敏捷的棕色狐狸跳过懒惰的狗。';

  @override
  String get fontWeightSaveApply => '保存并应用';

  @override
  String get geetestTitle => '完成滑块验证';

  @override
  String get geetestInitFailed => '验证码组件初始化失败，请重试或改用其他登录方式';

  @override
  String get geetestUnsupported => '当前平台不支持内嵌验证码，请使用扫码或 Cookie 登录';

  @override
  String get slicerPickImageFirst => '请先选择图片';

  @override
  String get slicerRowColInvalid => '行列数必须大于0';

  @override
  String get slicerSuccess => '切割成功，已添加到开始屏幕';

  @override
  String slicerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get slicerTitle => '图片切割磁贴';

  @override
  String get slicerTileSize => '磁贴尺寸 (所有碎片均相同)';

  @override
  String get slicerColsLabel => '列数 (Cols)';

  @override
  String get slicerRowsLabel => '行数 (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return '预览：将切割为 $count 个 $type 磁贴';
  }

  @override
  String get slicerProcessing => '处理中...';

  @override
  String get slicerSaveToStart => '保存到开始屏幕';

  @override
  String get viewerSaving => '正在保存...';

  @override
  String get viewerSaveSuccess => '保存成功';

  @override
  String viewerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get viewerShareImage => '分享图片';

  @override
  String viewerShareFailed(String error) {
    return '分享失败: $error';
  }

  @override
  String get viewerCopying => '正在复制...';

  @override
  String viewerCopyFailed(String error) {
    return '复制失败: $error';
  }

  @override
  String get viewerSaveToAlbum => '保存到相册';

  @override
  String get viewerCopyToClipboard => '复制到剪贴板';

  @override
  String get viewerImageLoadFailed => '图片加载失败';

  @override
  String get viewerImageDataNotFound => '未找到图片数据';

  @override
  String get userSpaceMidInvalid => 'mid 无效';

  @override
  String get userSpaceNoCard => '响应缺少 card';

  @override
  String get userSpaceNoList => '响应缺少 list';

  @override
  String get searchTypeVideo => '视频';

  @override
  String get searchTypeBangumi => '番剧';

  @override
  String get searchTypeFt => '影视';

  @override
  String get searchTypeLive => '直播间';

  @override
  String get searchTypeUser => '用户';

  @override
  String get searchTypeArticle => '专栏';

  @override
  String get tenThousandUnit => '万';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play播放 · $danmaku弹幕';
  }

  @override
  String searchScore(String score) {
    return '评分 $score';
  }

  @override
  String searchOnline(String count) {
    return '$count人在线';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans粉丝 · $videos视频';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views阅读 · $replies评论';
  }

  @override
  String get searchBadgeCourse => '课堂';

  @override
  String get searchBadgeLive => '直播';

  @override
  String get searchBadgeCoop => '合作';

  @override
  String get searchBadgeLiveNow => '直播中';

  @override
  String get searchKeywordEmpty => '关键词为空';

  @override
  String get searchBadResponse => '响应格式异常';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get searchGaiaParamMissing => 'gaia register 参数缺失';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register 异常: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate 未通过 (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate 异常: $error';
  }

  @override
  String get commentOidEmpty => 'oid 为空';

  @override
  String commentException(String error) {
    return '异常: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return '楼中楼 HTTP $code';
  }

  @override
  String get commentSubNoData => '楼中楼响应缺少 data';

  @override
  String commentSubException(String error) {
    return '楼中楼异常: $error';
  }

  @override
  String get commentNotLoggedIn => '未登录或未开启「携带 Cookie 请求」';

  @override
  String get commentMissingJct => 'Cookie 缺少 bili_jct，请重新登录';

  @override
  String commentNetworkError(String error) {
    return '网络异常: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message（code=$code）';
  }

  @override
  String get deviceOs => '操作系统';

  @override
  String get deviceBuild => '内部构建';

  @override
  String get deviceSecurityPatch => '安全补丁';

  @override
  String get deviceOem => 'OEM 厂商';

  @override
  String get deviceBrand => '品牌';

  @override
  String get deviceModel => '型号';

  @override
  String get deviceRomVersion => 'ROM/显示版本';

  @override
  String get deviceFingerprint => '设备指纹';

  @override
  String get deviceName => '设备名称';

  @override
  String get deviceComputerName => '计算机名';

  @override
  String get deviceHardwareModel => '硬件型号';

  @override
  String get deviceKernel => '内核版本';

  @override
  String get deviceDistro => '发行版';

  @override
  String get deviceVersion => '版本';

  @override
  String get devicePlatform => '平台';

  @override
  String deviceInfoFailed(String error) {
    return '获取信息失败: $error';
  }

  @override
  String get logWebUnsupported => '（Web 不支持文件日志）';

  @override
  String get logNotInitialized => '（未初始化）';

  @override
  String logAppDataDir(String path) {
    return '应用数据目录\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData（Roaming）\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return '本地数据目录\n$path';
  }

  @override
  String get nowPlayingVideo => '正在播放视频';

  @override
  String get commonUnknown => '未知';

  @override
  String get unnamedPlaylist => '未命名播放列表';

  @override
  String get unknownVideo => '未知视频';

  @override
  String dohQueryFailed(int code) {
    return 'DoH 查询失败: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP 连接成功';

  @override
  String get netModeCompat => 'Host 映射 IP 直连, 绕过 SNI 干扰';

  @override
  String get netModeStandard => '系统默认网络栈';

  @override
  String netHostResolveFailed(String host) {
    return '无法解析主机 $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie 为空';

  @override
  String get biliCookieIncomplete =>
      'Cookie 不完整，请从浏览器复制全部 Cookie（需包含 SESSDATA）';

  @override
  String get biliCookieMissingJct =>
      'Cookie 缺少 bili_jct，请重新从浏览器复制完整 Cookie（点赞/发评论等操作依赖它）';

  @override
  String get biliCookieInvalid => 'Cookie 无效或已过期，请重新从浏览器复制';

  @override
  String get biliLoginSuccess => '登录成功';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked => '请求被风控拦截(-412)，请稍后重试';

  @override
  String get biliQrExpired => '二维码已失效';

  @override
  String get biliQrScanned => '已扫码，请在手机上确认';

  @override
  String get biliQrWaiting => '等待扫码';

  @override
  String get biliRequestFailed => '请求失败';

  @override
  String get biliResponseNoData => '响应缺少 data';

  @override
  String get biliQrNoSessionCookie => '未获取到会话 Cookie，请刷新二维码重试';

  @override
  String get biliQrMissingJct =>
      '扫码登录未获取到完整会话（缺少 bili_jct），请改用「粘贴 Cookie」或「浏览器登录」方式';

  @override
  String get biliNoSessionCookie => '未获取到会话 Cookie';

  @override
  String get biliWebKeyFailed => '获取登录公钥失败，请检查网络';

  @override
  String get biliPwdEncryptFailed => '密码加密失败';

  @override
  String get biliNeedGeetest => '需要完成滑块验证';

  @override
  String get biliUnknownError => '未知错误';

  @override
  String get csPlaylists => '播放列表';

  @override
  String get csDanmaku => '弹幕';

  @override
  String get csCloudEncrypted => '云端数据已加密，请先在 WebDAV 设置中填写同步密码';

  @override
  String get csCloudPassMismatch => '云端数据已加密且同步密码不匹配，无法同步';

  @override
  String get csCloudNoFile => '云端没有播放列表文件，无法恢复';

  @override
  String get csRestoredFromCloud => '已从云端恢复';

  @override
  String get csSyncDone => '同步完成';

  @override
  String csUploadBgCount(int count) {
    return '上传背景图 $count 张';
  }

  @override
  String csDownloadBgCount(int count) {
    return '下载背景图 $count 张';
  }

  @override
  String csUploadedFileCount(int count) {
    return '上传 $count 个文件';
  }

  @override
  String csDownloadedFileCount(int count) {
    return '下载 $count 个文件';
  }

  @override
  String csMergedListsCount(int count) {
    return '合并 $count 个列表';
  }

  @override
  String get csEncrypted => '已加密';

  @override
  String csSyncFailed(String error) {
    return '同步失败: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return '已上传 $count 个播放列表到云端';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return '上传 $uploaded 个，下载 $downloaded 个';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return '，失败 $failed 个（$details）';
  }

  @override
  String get unknownUser => '未知用户';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => '发送文件';

  @override
  String receivingFile(String fileName) {
    return '接收: $fileName';
  }

  @override
  String get notificationChannelName => '聊天消息';

  @override
  String get notificationChannelDesc => '接收聊天消息和快捷回复';

  @override
  String get notificationReply => '回复';

  @override
  String get screenshotSavedTitle => '截图已保存';

  @override
  String get screenshotSavedToAlbum => '截图已保存到相册';

  @override
  String get notificationConfirm => '确认';

  @override
  String get callInProgressError => '当前有未结束的通话，请先挂断';

  @override
  String get callTcpFailed => '无法连接对方（TCP 建立失败），请确认对方在线';

  @override
  String get callConnectionDropped => '连接建立后立即断开，请检查网络或对方状态';

  @override
  String callInitFailed(String error) {
    return '发起通话失败：$error';
  }

  @override
  String callAcceptFailed(String error) {
    return '接听通话失败：$error';
  }

  @override
  String get callRecordVoice => '语音通话';

  @override
  String get callRecordMissedOutgoing => '未接通话';

  @override
  String get callRecordRejected => '已拒绝来电';

  @override
  String get callRecordMissedIncoming => '未接来电';

  @override
  String get callPeerNoAnswer => '对方未接听';

  @override
  String get callUnknown => '未知';

  @override
  String get callInProgress => '通话中';

  @override
  String get webdavHttpWarning => '警告：使用 HTTP 连接，凭证将以明文传输。建议使用 HTTPS。';

  @override
  String get webdavConfigRequired => '请先填写服务器地址和用户名';

  @override
  String get webdavAuthFailed => '认证失败：用户名或密码错误';

  @override
  String webdavConnectFailed(int code) {
    return '连接失败：HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return '网络错误：无法连接到服务器 ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return '未知错误：$error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV 未配置';

  @override
  String webdavLocalFileMissing(String path) {
    return '本地文件不存在: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return '上传失败：HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return '上传异常：$error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return '下载失败: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return '下载异常: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String webdavListFailed(String error) {
    return '列出文件失败: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND 失败: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return '网络错误：$msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return '准备备份 $count 个文件...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return '正在备份 ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return '备份完成：$success 成功，$fail 失败';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonConnect => '连接';

  @override
  String get commonSave => '保存';

  @override
  String get commonCreate => '创建';

  @override
  String get commonDelete => '删除';

  @override
  String get drawerHome => '主页';

  @override
  String get drawerVerificationRequests => '验证请求';

  @override
  String get drawerSettings => '设置';

  @override
  String get drawerAbout => '关于';

  @override
  String get drawerCloseMenu => '关闭菜单';

  @override
  String get drawerLockNow => '立即锁定';

  @override
  String get drawerNoNickname => '未设置昵称';

  @override
  String get drawerSwitchToDark => '切换到深色模式';

  @override
  String get drawerSwitchToLight => '切换到浅色模式';

  @override
  String get drawerLightMode => '浅色模式';

  @override
  String get drawerDarkMode => '深色模式';

  @override
  String get drawerSystemMode => '跟随系统';

  @override
  String drawerThemeSwitched(String mode) {
    return '已切换到 $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return '获取失败: $error';
  }

  @override
  String get drawerNoDeviceInfo => '暂无设备信息';

  @override
  String get drawerBackgroundTitle => '侧边栏背景';

  @override
  String get drawerBackgroundHasCustom => '当前已设置自定义背景，您可以更换或移除。';

  @override
  String get drawerBackgroundNoCustom => '为侧边栏设置一张个性化背景图片。';

  @override
  String get drawerBackgroundUpdated => '✅ 侧边栏背景已更新';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '❌ 设置失败: $error';
  }

  @override
  String get drawerBackgroundChange => '更换背景';

  @override
  String get drawerBackgroundSelect => '选择背景图片';

  @override
  String get drawerBackgroundRestored => '已恢复默认背景';

  @override
  String get drawerBackgroundRemove => '移除背景';

  @override
  String get homeOpenMenu => '打开菜单';

  @override
  String get homeAddConnection => '添加连接';

  @override
  String get homeMessages => '消息';

  @override
  String get homeNoConnections => '暂无连接';

  @override
  String get homePullToRefreshHint => '下拉刷新或点击右上角添加';

  @override
  String get homeLoadFailed => '聊天记录加载失败，请重试';

  @override
  String get homeRetryLoad => '重新加载';

  @override
  String get homeUnknownAddress => '未知地址';

  @override
  String get homeNoMessages => '暂无消息';

  @override
  String homeFileMessage(String fileName) {
    return '[文件] $fileName';
  }

  @override
  String get homeFileFallbackName => '文件';

  @override
  String get homeMessagePlaceholder => '[消息]';

  @override
  String get connectionLost => '连接已失效';

  @override
  String get openVideoFailed => '无法打开该视频';

  @override
  String get connectDialogTitle => '连接到对等端';

  @override
  String get connectIpHint => '输入 IP 地址 (例如：192.168.1.100 或 fe80::1)';

  @override
  String get connectIpEmpty => '请输入 IP 地址';

  @override
  String get connectIpInvalid => 'IP 地址格式不正确';

  @override
  String get connectIpNotLan => '仅允许内网 IP 地址';

  @override
  String get connectRequestSent => '已发送连接请求，等待对方验证';

  @override
  String get connectFailed => '连接失败，请检查 IP 地址是否正确或对方是否在线';

  @override
  String get homeScanQr => '扫一扫';

  @override
  String get homeMyQrCode => '我的二维码';

  @override
  String get homeManualAdd => '手动添加';

  @override
  String get scannedFriends => '扫码添加的好友';

  @override
  String get scanTitle => '扫一扫';

  @override
  String get scanTitleWebdav => '扫描 WebDAV 地址';

  @override
  String get scanHint => '将二维码 / 条码对准框内';

  @override
  String get scanHintWebdav => '将 WebDAV 服务器地址二维码对准框内';

  @override
  String get scanHintAddFriend => '将好友的设备二维码对准框内';

  @override
  String get scanPreparing => '正在准备摄像头...';

  @override
  String get scanPermissionNeeded => '需要摄像头权限';

  @override
  String get scanPermissionNeededMsg => '请在权限弹窗中允许使用摄像头，才能扫码。';

  @override
  String get scanPermissionDenied => '摄像头权限被拒绝';

  @override
  String get scanPermissionDeniedMsg => '权限已被永久拒绝，请前往系统设置手动开启。';

  @override
  String get scanCameraUnavailable => '摄像头不可用';

  @override
  String get scanRetry => '重试';

  @override
  String get scanOpenSettings => '前往系统设置';

  @override
  String get scanTorch => '闪光灯';

  @override
  String get scanDetectedLink => '检测到链接';

  @override
  String get scanOpenLinkPrompt => '是否在内置浏览器中打开以下链接？';

  @override
  String get scanCopy => '复制';

  @override
  String get scanOpen => '打开';

  @override
  String get scanLinkCopied => '链接已复制';

  @override
  String get scanDetectedBiliVideo => '检测到 B 站视频链接';

  @override
  String get scanBiliVideoPrompt => '是否用内置播放器打开该视频？';

  @override
  String scanBiliVideoAt(String time) {
    return '空降至 $time';
  }

  @override
  String get scanOpenVideo => '打开视频';

  @override
  String get scanDetectedWebdav => '检测到 WebDAV 地址';

  @override
  String get scanWebdavPrompt => '该链接看起来是 WebDAV 服务器地址，是否自动填入配置？';

  @override
  String get scanOpenInBrowser => '浏览器打开';

  @override
  String get scanFillConfig => '填入配置';

  @override
  String get scanDetectedText => '识别到文本';

  @override
  String get scanCopiedToClipboard => '已复制到剪贴板';

  @override
  String get scanClose => '关闭';

  @override
  String get scanResultTitle => '扫码结果';

  @override
  String get scanErrorPermission => '摄像头权限被拒绝';

  @override
  String get scanErrorUnsupported => '当前设备不支持扫码';

  @override
  String get scanErrorDisposed => '扫码器已释放，请重试';

  @override
  String scanErrorGeneric(String code) {
    return '摄像头不可用（$code）';
  }

  @override
  String scanInitFailed(String error) {
    return '扫码器初始化失败：$error';
  }

  @override
  String get scanDetectedDevice => '检测到设备二维码';

  @override
  String get scanAddFriendPrompt => '是否添加该设备为好友？';

  @override
  String get scanAddFriend => '添加好友';

  @override
  String get scanFriendAdded => '已发送好友请求，等待对方验证';

  @override
  String get scanFriendAddFailed => '添加好友失败，请检查网络或对方是否在线';

  @override
  String get myQrTitle => '我的二维码';

  @override
  String get myQrHint => '让好友扫描此二维码添加你';

  @override
  String get myQrEmbedIp => '二维码中已嵌入第一个局域网 IP';

  @override
  String get myQrLocalIps => '当前局域网 IP';

  @override
  String get myQrCopyContent => '复制二维码内容';

  @override
  String get myQrCopied => '已复制到剪贴板';

  @override
  String get myQrNoIp => '未找到有效的局域网 IP，请检查网络连接。';

  @override
  String get displayModeSectionTitle => '屏幕';

  @override
  String get displayModeTitle => '屏幕帧率';

  @override
  String get displayModeAuto => '自动';

  @override
  String get displayModeSystemTag => '[系统]';

  @override
  String get displayModeHint => '没有生效？重启应用试试';

  @override
  String get displayModeUnsupported => '当前平台不支持设置屏幕帧率（仅 Android）';

  @override
  String get displayModeAndroidOnly => '仅 Android';

  @override
  String get displayModeLoading => '正在获取屏幕帧率...';

  @override
  String get displayModeEmpty => '未获取到可用的屏幕帧率';

  @override
  String get playerSectionEnhance => '画面增强';

  @override
  String get superResolutionTitle => '超分辨率';

  @override
  String get superResolutionOff => '关闭';

  @override
  String get superResolutionEfficiency => '效率（低开销）';

  @override
  String get superResolutionQuality => '画质（最佳效果）';

  @override
  String get superResolutionHint => '通过 mpv 着色器实时增强画面，建议配合硬件解码；对动画内容效果最佳';

  @override
  String get skipIntroOutroTitle => '跳过片头/片尾';

  @override
  String get skipIntroOutroHint => '通过社区共享数据识别片头片尾，仅在视频有 BV+CID 时提示';

  @override
  String get skipIntro => '跳过片头';

  @override
  String get skipOutro => '跳过片尾';

  @override
  String playlistDetailEpisodes(int count) {
    return '共 $count 集';
  }

  @override
  String get playlistDetailEmpty => '该播放列表为空，请先编辑添加视频';

  @override
  String playlistDetailEpisodeOf(int index) {
    return '第 $index 集';
  }

  @override
  String playlistDetailResume(String position) {
    return '看到这集 · $position';
  }

  @override
  String get playlistDetailBgTitle => '背景图';

  @override
  String get playlistDetailBgPick => '选择背景图片';

  @override
  String get playlistDetailBgChange => '更换背景';

  @override
  String get playlistDetailBgRemove => '移除背景';

  @override
  String get playlistDetailBgUpdated => '✅ 背景图已更新';

  @override
  String get playlistDetailBgRemoved => '已恢复默认背景';

  @override
  String playlistDetailBgFail(String error) {
    return '设置失败：$error';
  }

  @override
  String get playlistFabRestart => '从头开始';

  @override
  String get playlistMenuMore => '更多操作';

  @override
  String get playlistMenuRename => '编辑名字';

  @override
  String get playlistMenuMultiSelect => '多选';

  @override
  String get playlistMenuDanmaku => '弹幕';

  @override
  String get playlistRenameTitle => '重命名播放列表';

  @override
  String get playlistRenameHint => '输入新的列表名称';

  @override
  String get playlistRenameSaved => '已重命名';

  @override
  String get playlistSelectDone => '完成';

  @override
  String get playlistSelectEmpty => '请先选择剧集';

  @override
  String playlistSelectDelete(int count) {
    return '删除选中（$count）';
  }

  @override
  String playlistSelectDeleted(int count) {
    return '已删除 $count 集';
  }

  @override
  String get playlistDanmakuTitle => '导入番剧弹幕';

  @override
  String get playlistDanmakuSsHint => '输入番剧 SS 号（season_id）';

  @override
  String get playlistDanmakuFetchFail => '获取剧集失败，请检查 SS 号';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return '选择剧集（共 $count 集）';
  }

  @override
  String get playlistDanmakuSelectAll => '全选';

  @override
  String get playlistDanmakuImport => '导入并附加弹幕';

  @override
  String playlistDanmakuAttached(int count) {
    return '已为 $count 集附加弹幕';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '所选 $selected 集超过列表 $total 集，超出部分已忽略';
  }

  @override
  String get splitSelectChat => '选择一个聊天';

  @override
  String get statusPending => '待对方验证';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusRejected => '已拒绝';

  @override
  String get statusDisconnected => '已断开';

  @override
  String get homeStart => '开始';

  @override
  String get homeDone => '完成';

  @override
  String get homeBack => '返回';

  @override
  String get homeOverview => '鸟瞰视图';

  @override
  String get homeLocalUser => '本地用户';

  @override
  String get homeDefaultGroup => '默认分组';

  @override
  String get homeNewGroup => '新分组';

  @override
  String get homeUnnamedGroup => '(未命名分组)';

  @override
  String get homeDeleteGroupTitle => '确认删除';

  @override
  String get homeDeleteGroupMessage => '删除该组将同时删除组内的所有磁贴，是否继续？';

  @override
  String get homeNewGroupTitle => '新建分组';

  @override
  String get homeGroupNameHint => '输入分组名称';

  @override
  String get homeRenameGroupTitle => '为该组命名';

  @override
  String get homeNewGroupNameHint => '输入新组名';

  @override
  String get homeImageSlice => '图片碎片';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (小)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (宽)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (大)';
  }

  @override
  String get homeGroupOne => '分组1';

  @override
  String get homeGroupTwo => '分组2';

  @override
  String get homeGroupProductivity => '生产力工具';

  @override
  String get homeGroupLegacy => '旧版';

  @override
  String get tileImageSlicer => '图片切割';

  @override
  String get tileSystemSettings => '系统设置';

  @override
  String get tileDatabase => '数据库';

  @override
  String get tileLcdDisplay => 'LCD 显示屏';

  @override
  String get tileLedDynamic => 'LED 动态';

  @override
  String get tileLedStatic => 'LED 静态';

  @override
  String get tilePisScreen => 'PIS 屏幕';

  @override
  String get tileRoutePreview => '路线预览';

  @override
  String get tileStationEntranceDesign => '出入口设计';

  @override
  String get tileStationEntrancePillar => '出入口立柱';

  @override
  String get tileStationEntranceSideName => '出入口侧名';

  @override
  String get tilePlatformSideName => '侧方站名';

  @override
  String get tileScreenDoorCover => '屏蔽门盖板';

  @override
  String get tileStationNameSign => '站名牌';

  @override
  String get tileGeneralSign => '通用标识';

  @override
  String get tileLineSymbol => '线路符号';

  @override
  String get tileBusLcd => '巴士 LCD';

  @override
  String get tileJsonEditor => 'JSON 编辑器';

  @override
  String get tileNamingRule => '命名规范';

  @override
  String get tilePlatformText => '站台文本';

  @override
  String get tileDepartureText => '出发文本';

  @override
  String get tileArrivalText => '到站文本';

  @override
  String get tileOperationDirectionLegacy => '运营方向(旧)';

  @override
  String get tileLegacyLcdWarning => '旧版LCD(警告)';

  @override
  String get tileLinearRoute => '线性路线';

  @override
  String get tileRoadSign => '路牌';

  @override
  String get commentPanelTitle => '评论区';

  @override
  String commentTotalCount(int count) {
    return '共 $count 条';
  }

  @override
  String get commentSortHeat => '按热度';

  @override
  String get commentSortTime => '按时间';

  @override
  String get commentLoading => '正在加载评论...';

  @override
  String get commentLoadFail => '评论加载失败，请检查网络';

  @override
  String get commentLoadMoreFail => '加载更多评论失败';

  @override
  String get commentNoMore => '没有更多评论了';

  @override
  String get commentLoadingMore => '加载中...';

  @override
  String get commentEmpty => '还没有评论';

  @override
  String get commentPinned => '置顶';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get commentExpand => '展开';

  @override
  String get commentCollapse => '收起';

  @override
  String get commentTranslateNeedEnable => '请先在语言设置中开启 AI 翻译';

  @override
  String get commentTranslateNone => '没有可用翻译';

  @override
  String commentSubCount(int count) {
    return '共 $count 条回复';
  }

  @override
  String commentSubLoadMore(String hint) {
    return '加载更多回复（$hint）';
  }

  @override
  String get commentYesterday => '昨天';

  @override
  String get articleLoadFailed => '文章加载失败';

  @override
  String get articleNoContent => '文章正文为空或暂不支持渲染';

  @override
  String get articleOpenBrowser => '浏览器打开';

  @override
  String get articleShare => '分享';

  @override
  String get articleAuthorUnknown => '未知作者';

  @override
  String get browserLinkPageTitle => '网页链接';

  @override
  String articleViews(String count) {
    return '$count 阅读';
  }

  @override
  String get contactPickerTitle => '发送给联系人';

  @override
  String get contactPickerContentLabel => '发送内容';

  @override
  String get contactPickerContentHint => '输入要发送的内容';

  @override
  String get contactPickerContentEmpty => '内容不能为空';

  @override
  String get contactPickerSearchHint => '搜索联系人';

  @override
  String get contactPickerEmpty => '暂无联系人';

  @override
  String get contactPickerNoMatch => '未找到匹配的联系人';

  @override
  String get contactPickerSelectAll => '全选';

  @override
  String contactPickerSendToCount(int count) {
    return '发送给 $count 个联系人';
  }

  @override
  String contactPickerSent(int count) {
    return '已发送给 $count 个联系人';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '「$name」未连接，无法发送';
  }

  @override
  String contactPickerSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String get contactPickerOnline => '在线';

  @override
  String get contactPickerOffline => '离线';

  @override
  String get articleShareToContact => '私信分享';

  @override
  String get playerDanmakuList => '弹幕列表';

  @override
  String playerDanmakuListCount(int count) {
    return '弹幕列表 · 共 $count 条';
  }

  @override
  String get playerDanmakuListEmpty => '暂无弹幕';

  @override
  String get playerDanmakuListNoMatch => '无匹配的弹幕';

  @override
  String get playerDanmakuListSearchHint => '搜索弹幕内容';

  @override
  String get playerDanmakuListJumpCurrent => '定位到当前播放';

  @override
  String get playerViewNotes => '查看笔记';

  @override
  String get playerNotesTitle => '笔记';

  @override
  String playerNotesCount(int count) {
    return '笔记（$count）';
  }

  @override
  String get playerNotesEmpty => '该视频暂无公开笔记';

  @override
  String get playerNotesNoMore => '没有更多了';

  @override
  String get playerNotesLoadFailed => '笔记加载失败';

  @override
  String get playerNotesViewFull => '查看全部';

  @override
  String get playerWriteNote => '写笔记';

  @override
  String get noteEditorWrite => '写笔记';

  @override
  String get noteEditorTitle => '写笔记';

  @override
  String get noteEditorTitleHint => '标题（选填）';

  @override
  String get noteEditorContentHint => '开始记笔记…';

  @override
  String get noteEditorEmoji => '表情';

  @override
  String get noteEditorPublish => '发布';

  @override
  String get noteEditorEmptyContent => '笔记内容不能为空';

  @override
  String get noteEditorContentTooShort => '内容至少 10 个字符才能发布';

  @override
  String get noteEditorNotLoggedIn => '未登录：笔记已保存为本地草稿，登录后可发布';

  @override
  String get noteEditorPublished => '笔记已发布';

  @override
  String get noteEditorPublishNetworkError => '发布失败（网络异常），草稿已保存';

  @override
  String get noteEditorPublishRejected => '发布被服务端拒绝，草稿已保留';

  @override
  String get noteEditorDraftSaved => '已自动保存草稿';

  @override
  String get noteEditorLoggedInHint => '已登录，可发布公开笔记';

  @override
  String get noteEditorGuestHint => '未登录：仅保存本地草稿，不能发布';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return '草稿已保存 $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count 字';
  }

  @override
  String get noteEditorMyDraft => '我的草稿';

  @override
  String get noteEditorDeleteDraft => '删除草稿';

  @override
  String get playerMoreTooltip => '更多操作';

  @override
  String get commentComposerBarHint => '说点什么…';

  @override
  String get commentComposerHint => '输入评论内容…';

  @override
  String commentComposerReplyHint(String name) {
    return '回复 @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return '回复 @$name';
  }

  @override
  String get commentComposerEmote => '表情';

  @override
  String get commentComposerSend => '发送';

  @override
  String get commentComposerEmpty => '评论内容不能为空';

  @override
  String get commentComposerEmoteUnavailable => '表情面板不可用（可能未登录）';

  @override
  String get commentComposerPickImage => '选择图片';

  @override
  String get commentComposerMore => '更多';

  @override
  String get commentComposerVideoProgress => '视频进度';

  @override
  String get commentComposerVideoScreenshot => '视频截图';

  @override
  String commentComposerImageLimit(int count) {
    return '最多选择 $count 张图片';
  }

  @override
  String get commentComposerCaptureFailed => '截图失败，请先开始播放';

  @override
  String get commentComposerUploadFailed => '图片上传失败，请重试';

  @override
  String get commentComposerFabLabel => '发评论';

  @override
  String get commentComposerFabReply => '发回复';

  @override
  String get danmakuSendTitle => '发弹幕';

  @override
  String get danmakuSendModeLabel => '模式';

  @override
  String get danmakuSendFontSizeLabel => '字号';

  @override
  String get danmakuSendColorLabel => '颜色';

  @override
  String get danmakuFontSizeSmall => '小';

  @override
  String get danmakuFontSizeStandard => '标准';

  @override
  String get danmakuFontSizeLarge => '大';

  @override
  String get danmakuSendCustomColor => '自定义颜色';

  @override
  String get danmakuSendColorOk => '确定';

  @override
  String get danmakuSendPreviewPlaceholder => '发个友善的弹幕见证当下';

  @override
  String get drawerHistory => '历史记录';

  @override
  String get drawerWatchLater => '稍后再看';

  @override
  String get drawerMyCache => '我的缓存';

  @override
  String get historyCenterTitle => '历史记录';

  @override
  String get historyTabWatch => '观看历史';

  @override
  String get historyTabPlay => '播放进度';

  @override
  String get historySearchHint => '搜索历史...';

  @override
  String get historyPauseHistory => '暂停记录历史';

  @override
  String get historyResumeHistory => '恢复记录历史';

  @override
  String get historyPausedTip => '历史记录已暂停';

  @override
  String get historyPausedTipAction => '点击恢复';

  @override
  String get historyClearWatchHistory => '清空观看历史';

  @override
  String get historyClearPlayHistory => '清空播放记录';

  @override
  String get historyClearAllTitle => '清空历史';

  @override
  String historyClearAllConfirm(String label) {
    return '确定要清空全部$label吗？此操作不可恢复。';
  }

  @override
  String get historyNoWatchHistory => '暂无观看历史';

  @override
  String get historyNoPlayHistory => '暂无播放记录';

  @override
  String get historyDeleteSelected => '删除选中';

  @override
  String historySelectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get historySearchNoResult => '无匹配结果';

  @override
  String get historyPauseOnSnack => '已暂停历史记录';

  @override
  String get historyResumeOnSnack => '已恢复历史记录';

  @override
  String historyDeleteToast(int count) {
    return '已删除 $count 条记录';
  }

  @override
  String get myCacheTitle => '我的缓存';

  @override
  String get myCacheSearchHint => '搜索缓存视频...';

  @override
  String get myCacheDownloading => '正在缓存';

  @override
  String get myCacheCached => '已缓存';

  @override
  String get myCacheNoCache => '暂无缓存视频';

  @override
  String myCacheGroupCount(int count) {
    return '$count个视频';
  }

  @override
  String get myCacheDeleteGroup => '删除整组';

  @override
  String get myCacheUpdateDanmaku => '更新弹幕';

  @override
  String get myCacheClearAllTitle => '清空全部缓存';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return '将删除全部已缓存视频（$count个视频 · $size），确定吗？';
  }

  @override
  String get cacheActionDownload => '缓存';

  @override
  String get cacheActionCached => '已缓存';

  @override
  String get cacheActionCaching => '缓存中';

  @override
  String get cacheToastSuccess => '已加入缓存队列';

  @override
  String get cacheToastCached => '该视频已缓存';

  @override
  String cacheToastFailed(String error) {
    return '缓存失败：$error';
  }

  @override
  String get drawerRecommend => '推荐';

  @override
  String get recommendSourceWeb => 'Web端';

  @override
  String get recommendSourceApp => 'APP端';

  @override
  String get recommendEmpty => '暂无推荐内容';

  @override
  String get recommendSwitchList => '切换为单列';

  @override
  String get recommendSwitchGrid => '切换为多列';

  @override
  String get sideBarExpand => '展开侧边栏';

  @override
  String get sideBarCollapse => '收起侧边栏';

  @override
  String get sideBarMore => '更多';

  @override
  String get recommendTabHot => '热门';

  @override
  String get recommendTabBangumi => '番剧';

  @override
  String get recommendSourceTitle => '推荐数据来源';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String metroDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get metroSunday => '星期日';

  @override
  String get metroMonday => '星期一';

  @override
  String get metroTuesday => '星期二';

  @override
  String get metroWednesday => '星期三';

  @override
  String get metroThursday => '星期四';

  @override
  String get metroFriday => '星期五';

  @override
  String get metroSaturday => '星期六';

  @override
  String get metroLogin => '登录';

  @override
  String get metroWelcome => '欢迎';

  @override
  String get imageViewerNoFile => '未找到图片文件';

  @override
  String get syncPassphraseEmpty => '同步口令不能为空';

  @override
  String get imageBytesRequired => 'imageUrl 或 imageBytes 必须提供其一';

  @override
  String get webdavConnectSuccess => '✅ 连接成功！';

  @override
  String get webdavConfigSaved => '配置已保存';

  @override
  String get webdavConfigureFirst => '请先配置并测试 WebDAV 连接';

  @override
  String get webdavSelectContactsFirst => '请先在下方选择要备份的联系人';

  @override
  String get webdavNoFiles => '选中的联系人没有可备份的文件';

  @override
  String get webdavConfirmBackup => '确认备份';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return '将备份 $contacts 位联系人的 $files 个文件到 WebDAV 服务器。\n远程路径：$path/chats/<昵称>/';
  }

  @override
  String get webdavStartBackup => '开始备份';

  @override
  String get webdavBackingUpTitle => '正在备份';

  @override
  String get webdavBackupDoneTitle => '备份完成';

  @override
  String webdavTotalFiles(int count) {
    return '总计：$count 个文件';
  }

  @override
  String webdavSuccessCount(int count) {
    return '成功：$count';
  }

  @override
  String webdavFailCount(int count) {
    return '失败：$count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...还有 $count 个错误';
  }

  @override
  String get webdavBackupFab => '备份';

  @override
  String get webdavShowInfo => '显示我的信息';

  @override
  String get webdavHideInfo => '隐藏我的信息';

  @override
  String get webdavScanToFill => '扫码填入服务器地址';

  @override
  String get webdavScanFilled => '已通过扫码填入地址';

  @override
  String get webdavServerConfig => '服务器配置';

  @override
  String get webdavServerUrlLabel => '服务器地址';

  @override
  String get webdavUsernameLabel => '用户名';

  @override
  String get webdavPasswordLabel => '密码';

  @override
  String get webdavRemotePathLabel => '远程备份路径';

  @override
  String get webdavTesting => '测试中...';

  @override
  String get webdavSaveAndTest => '保存并测试连接';

  @override
  String get webdavSaveOnly => '仅保存';

  @override
  String get webdavConnectVerified => '连接验证通过';

  @override
  String get webdavAutoBackup => '自动备份';

  @override
  String get webdavAutoBackupOnReceive => '接收文件时自动备份';

  @override
  String get webdavAutoBackupSubtitle => '仅对下方选中的联系人生效';

  @override
  String get webdavMediaSync => '媒体同步';

  @override
  String get webdavSyncPlaylists => '同步播放列表';

  @override
  String get webdavSyncDanmaku => '同步弹幕';

  @override
  String get webdavPassphraseEncrypted => '同步密码（AES-256 加密）';

  @override
  String get webdavPassphrasePlain => '同步密码（留空 = 明文上传）';

  @override
  String get webdavPassphraseHint => '填写密码后播放列表将加密上传';

  @override
  String get webdavGeneratePassphrase => '生成随机密码';

  @override
  String get webdavMediaSyncHint =>
      '播放列表（含背景图）与弹幕保存到云端的独立目录（playlists/、danmaku/），不会与聊天备份混在一起。多个设备共用同一远程路径即可互相合并；播放列表可在播放列表页手动同步或从云端恢复。';

  @override
  String get webdavEncryptionOn =>
      '已启用加密：播放列表将以 AES-256-GCM 加密后上传（含内嵌的 WebDAV 鉴权信息），服务器无法读取内容。多台设备需填写相同密码才能解密。';

  @override
  String get webdavEncryptionOff =>
      '未加密：播放列表（含内嵌的 WebDAV 鉴权信息）将明文上传，任何能读取服务器文件的人都能看到，不推荐。';

  @override
  String get webdavBackupContacts => '备份联系人';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '已选 $selected / $total 位联系人';
  }

  @override
  String get webdavSearchContacts => '搜索联系人或 IP...';

  @override
  String get webdavDeselectAll => '取消全选';

  @override
  String webdavFileCount(int count) {
    return '$count 个文件';
  }

  @override
  String get webdavNoContacts => '暂无联系人';

  @override
  String get webdavNoMatch => '无匹配结果';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count 个文件';
  }

  @override
  String get webdavManage => '管理';

  @override
  String get webdavLastSync => '上次同步';

  @override
  String get webdavLastError => '最近错误';

  @override
  String get webdavClearConfig => '清除 WebDAV 配置';

  @override
  String get webdavClearConfigSubtitle => '删除所有服务器信息和凭据';

  @override
  String get webdavUserLabel => '用户';

  @override
  String webdavStatusActive(String name) {
    return '$name已激活';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name已配置';
  }

  @override
  String get webdavStatusNotConfigured => '未配置';

  @override
  String get webdavNotSynced => '尚未同步';

  @override
  String get webdavJustNow => '上次同步：刚刚';

  @override
  String webdavMinutesAgo(int minutes) {
    return '上次同步：$minutes 分钟前';
  }

  @override
  String webdavHoursAgo(int hours) {
    return '上次同步：$hours 小时前';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return '上次同步：$month月$day日 $time';
  }

  @override
  String get webdavPassphraseGenerated => '已生成同步密码并复制到剪贴板，请在其他设备上填入相同密码';

  @override
  String get webdavConfirmClear => '确认清除';

  @override
  String get webdavClearConfirmText =>
      '将删除所有 WebDAV 配置（服务器、凭据、联系人选择）。\n已上传的文件不受影响。';

  @override
  String get profileEditProfile => '编辑资料';

  @override
  String get profileAccountSection => '账户管理';

  @override
  String get profileWebdavBackup => 'WebDAV 备份';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username 已登录';
  }

  @override
  String get profileNotLoggedIn => '未登录';

  @override
  String get profileAvatarSection => '头像';

  @override
  String get profileChangeAvatar => '更换头像';

  @override
  String get profileRemoveAvatar => '移除头像';

  @override
  String get profilePickFromGallery => '从相册选择图片';

  @override
  String get profileRestoreDefaultAvatar => '恢复默认头像';

  @override
  String get profileSetBackground => '设置背景';

  @override
  String get profileBgSubtitle => '为侧边栏选择一张背景图';

  @override
  String get profileRestoreDefault => '恢复默认';

  @override
  String get profileBgRemoveSubtitle => '移除自定义背景，使用主题色渐变';

  @override
  String get profileInfoSection => '个人信息';

  @override
  String get profileNicknameLabel => '昵称';

  @override
  String get profileNotSet => '未设置';

  @override
  String get profileBgTitle => '个人资料背景';

  @override
  String get profileAvatarUpdated => '✅ 头像已更新';

  @override
  String profileAvatarFailed(String error) {
    return '❌ 选择头像失败: $error';
  }

  @override
  String get profileRemoveAvatarConfirm => '确定要删除当前头像吗？此操作无法撤销。';

  @override
  String get profileAvatarRemoved => '头像已移除';

  @override
  String get profileSetNickname => '设置昵称';

  @override
  String get profileNicknameHint => '输入昵称';

  @override
  String get profileNicknameEmpty => '昵称不能为空';

  @override
  String get profileNicknameUpdated => '✅ 昵称已更新';

  @override
  String get colorDefaultGreen => '默认绿';

  @override
  String get colorPink => '粉红色';

  @override
  String get colorRed => '红色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorYellow => '黄色';

  @override
  String get colorLime => '酸橙色';

  @override
  String get colorLightGreen => '浅绿色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '蓝绿色';

  @override
  String get colorLightBlue => '浅蓝色';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorIndigo => '靛蓝色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorBlueGrey => '蓝灰色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorGrey => '灰色';

  @override
  String get themeColorExtracted => '已从图片提取主题色';

  @override
  String themeColorFailed(String error) {
    return '取色失败: $error';
  }

  @override
  String get themeImageOnly => '仅支持图片格式';

  @override
  String get themeTitle => '主题';

  @override
  String themeColorCopied(String hex) {
    return '已复制色号: $hex';
  }

  @override
  String get themeAppearance => '外观';

  @override
  String get themeDarkBlackened => '深色模式（已黑化）';

  @override
  String get themeOff => '已关闭';

  @override
  String get themeEnabled => '已启用';

  @override
  String get themeColorsSection => '配色';

  @override
  String get themePaletteStyle => '调色板风格';

  @override
  String get themeFollowSystem => '跟随系统配色';

  @override
  String get themePickColor => '选择颜色';

  @override
  String get themeDropHint => '松开以从图片提取主题色';

  @override
  String get themeNewTheme => '新建主题';

  @override
  String themeSwitched(String name) {
    return '已切换至 $name 主题';
  }

  @override
  String get themeDeleteTitle => '删除主题';

  @override
  String themeDeleteConfirm(String name) {
    return '确定要删除自定义主题 \"$name\" 吗？';
  }

  @override
  String themeDeleted(String name) {
    return '已删除 \"$name\"';
  }

  @override
  String get themeCreateTitle => '创建自定义主题';

  @override
  String get themeNameLabel => '主题名称';

  @override
  String get themeNameHint => '请输入文本';

  @override
  String get themeHexLabel => '十六进制/RGB';

  @override
  String get themeHexHint => '例如 #FF0000 或 255,0,0';

  @override
  String themeCreated(String name) {
    return '主题 \"$name\" 已创建并保存';
  }

  @override
  String get themeCopyColor => '复制色号';

  @override
  String get themePickFromImage => '从图片取色';

  @override
  String get searchBack => '返回设置';

  @override
  String get searchHint => '搜索设置项…';

  @override
  String get searchPrompt => '输入关键词搜索设置项';

  @override
  String get searchExamples => '例如: 刷新率 / 解码 / UA / 弹幕';

  @override
  String searchNoResults(String query) {
    return '没有找到「$query」相关设置';
  }

  @override
  String get searchThemeMode => '主题模式';

  @override
  String get searchPureBlack => '纯黑深色模式';

  @override
  String get searchThemeColor => '主题配色';

  @override
  String get searchFontWeight => '文字粗细';

  @override
  String get searchDisplayScale => '显示缩放';

  @override
  String get searchDisplayMode => '显示模式 / 屏幕刷新率';

  @override
  String get searchStatusBar => '状态栏';

  @override
  String get searchKeepWindowRatio => '等比例拉伸窗口';

  @override
  String get searchLongPressSpeed => '长按键加速';

  @override
  String get searchScreenshot => '截图功能';

  @override
  String get searchScreenshotDanmaku => '截图时显示弹幕';

  @override
  String get searchPlayProgress => '播放进度';

  @override
  String get searchHwdec => '硬件解码';

  @override
  String get searchVideoSync => '视频同步';

  @override
  String get searchImmersiveLongPress => '沉浸模式长按加速';

  @override
  String get searchMpvLog => '记录 mpv 日志';

  @override
  String get searchMpvLogLevel => 'mpv 日志细度';

  @override
  String get searchNetworkMode => '网络模式';

  @override
  String get searchInsecureCert => '允许不安全证书';

  @override
  String get searchChatIpv6 => '聊天 IPv6';

  @override
  String get searchConnectivityTest => '连通性测试';

  @override
  String get searchHostOverrides => 'Host 映射';

  @override
  String get searchDohQuery => 'DoH 查询';

  @override
  String get searchReferer => '请求头 Referer';

  @override
  String get searchUserAgent => '请求头 User-Agent';

  @override
  String get searchSystemSettings => '系统设置';

  @override
  String get searchUserSettings => '用户设置';

  @override
  String get settingsDisplaySub => '主题、字体、布局';

  @override
  String get settingsSystem => '系统';

  @override
  String get settingsSystemSub => '语言、存储、权限';

  @override
  String get settingsStorage => '存储';

  @override
  String get settingsStorageSub => '图片缓存、弹幕缓存';

  @override
  String get settingsNetwork => '网络';

  @override
  String get settingsNetworkSub => 'Wi-Fi、代理、同步';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSub => '应用语言、B 站翻译（AI 翻译）';

  @override
  String get appLangSection => '应用语言';

  @override
  String get appLangFollowSystem => '跟随系统';

  @override
  String get biliLangSection => '翻译目标语言';

  @override
  String get biliAiSection => 'AI 翻译';

  @override
  String get biliAiTranslateEnable => '启用 AI 翻译';

  @override
  String get biliAiTranslateOnDesc => '已开启：B 站请求将携带翻译头，返回该语言内容';

  @override
  String get biliAiTranslateOffDesc => '关闭：按原始语言返回内容';

  @override
  String get langZhCn => '简体中文';

  @override
  String get langZhHk => '繁體中文（香港）';

  @override
  String get langZhTw => '繁體中文（台灣）';

  @override
  String get langEnUs => 'English（英語）';

  @override
  String get langJaJp => '日本語';

  @override
  String get langKoKr => '한국어';

  @override
  String get settingsPlayer => '播放器';

  @override
  String get settingsPlayerSub => '状态栏、加速、截图';

  @override
  String get settingsStartScreenSub => '开始屏幕、Charm';

  @override
  String get settingsLogs => '日志';

  @override
  String get settingsLogsSub => '错误日志、mpv 日志';

  @override
  String get settingsAccounts => '账号';

  @override
  String get settingsAccountsSub => 'B 站、WebDAV';

  @override
  String get settingsUser => '用户';

  @override
  String get settingsUserSub => '账户、隐私、安全';

  @override
  String get settingsAboutSub => '版本、许可证';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get settingsLicensesSub => '本项目引用的开源项目';

  @override
  String get settingsSearch => '搜索设置';

  @override
  String get openSidebar => '打开侧边栏';

  @override
  String get settingsPlaceholderEasterEgg => '唔,有什么问题为什么不问问神奇的芙莉莲呢';

  @override
  String storageClearTitle(String label) {
    return '清理$label';
  }

  @override
  String storageClearConfirm(String label) {
    return '确定要清理$label吗？清理后重新浏览图片会再次下载。';
  }

  @override
  String get storageClear => '清理';

  @override
  String storageCleared(String label) {
    return '$label已清理';
  }

  @override
  String get refreshAction => '刷新';

  @override
  String get storageCacheSection => '缓存';

  @override
  String get storageImageCache => '图片缓存';

  @override
  String get storageCounting => '正在统计…';

  @override
  String storageFileCount(int count, String size) {
    return '$count 个文件 · $size';
  }

  @override
  String get storageDanmakuCache => '弹幕缓存';

  @override
  String storageVideoCount(int count, String size) {
    return '$count 个视频 · $size';
  }

  @override
  String get settingsAutoOfflineCache => '自动离线缓存播放过的视频';

  @override
  String get settingsAutoOfflineCacheHint =>
      '观看过的视频会自动下载到本地（约 2GB 上限，超出自动淘汰最旧），下次打开直接从本地播放、不再重复拉取；关闭后不再新增缓存。';

  @override
  String get storageVideoCache => '离线视频缓存';

  @override
  String get storageVideoCacheDesc => '播放过的视频媒体流（容量上限内自动缓存、LRU 淘汰），下次打开直接从本地播放';

  @override
  String get storageMemoryCache => '内存图片缓存';

  @override
  String get storageMemoryCacheDesc => '本次运行中已解码的图片，退出后自动释放';

  @override
  String get storageClearing => '正在清理…';

  @override
  String get storageClearAll => '一键清理全部缓存';

  @override
  String get storageCacheHint =>
      '图片缓存为应用私有目录（image_cache），清理后浏览过的评论配图会重新下载；弹幕缓存用于离线弹幕加载。';

  @override
  String get storageClearAllTitle => '清理全部缓存';

  @override
  String get storageClearAllConfirm => '将清空图片缓存、弹幕缓存与内存图片缓存，清理后重新浏览图片会再次下载。';

  @override
  String get storageAllCleared => '缓存已全部清理';

  @override
  String get verificationPendingRequests => '待处理请求';

  @override
  String get verificationNoPending => '暂无待处理请求';

  @override
  String verificationIpAddress(String ip) {
    return 'IP 地址：$ip';
  }

  @override
  String verificationNickname(String name) {
    return '昵称：$name';
  }

  @override
  String verificationRequestTime(String time) {
    return '请求时间：$time';
  }

  @override
  String get verificationRejectInvalid => '无法拒绝：IP 地址无效';

  @override
  String get verificationRejected => '已拒绝连接请求';

  @override
  String get verificationReject => '拒绝';

  @override
  String get verificationAcceptInvalid => '无法接受：IP 地址无效';

  @override
  String get verificationAccepted => '已接受连接请求';

  @override
  String get verificationAccept => '同意';

  @override
  String get startScreenWarning => '我们可能不再更新此项目';

  @override
  String get startScreenTitle => '开始屏幕';

  @override
  String get startScreenGoBack => '转到上一层级';

  @override
  String get enableStartScreen => '启用开始屏幕';

  @override
  String get startScreenEnableSubtitle => '允许从 Charm 的 Start 按钮进入开始屏幕';

  @override
  String get enableCharm => '启用 Charm';

  @override
  String get charmEnableSubtitle => '在屏幕右侧提供 Charm 快捷栏';

  @override
  String get charmGestureTitle => '手势拉出 Charm';

  @override
  String get charmGestureSubtitle => '从屏幕右边缘向左滑动或悬停右上角拉出 Charm';

  @override
  String get externalVideo => '外部视频';

  @override
  String get audioChannelName => '视频媒体播放';

  @override
  String get foregroundChannelName => 'Navi 保活';

  @override
  String get foregroundChannelDesc => '主人~保持我后台运行~';

  @override
  String get foregroundTitle => '保活中';

  @override
  String get foregroundText => '我验牌';

  @override
  String get drawerBilibiliSearch => '搜索';

  @override
  String get commentImageLoadFail => '图片加载失败';

  @override
  String get commentDetailTitle => '评论详情';

  @override
  String get commentLikeLoginRequired => '请先登录 B 站账号（并开启携带 Cookie）后再点赞';

  @override
  String commentLikeFail(String error) {
    return '点赞失败：$error';
  }

  @override
  String get relatedEmpty => '暂无相关推荐';

  @override
  String get biliLoadFailed => '加载失败';

  @override
  String countWan(String count) {
    return '$count万';
  }

  @override
  String countYi(String count) {
    return '$count亿';
  }

  @override
  String get searchNoNewContent => '暂无新内容';

  @override
  String get searchNewContentRefreshed => '已为您刷新一组新内容';

  @override
  String get biliDialogNeedLogin => '需要登录';

  @override
  String get biliDialogInteractDesc => '点赞 / 投币 / 三连等互动需要登录 B 站账号';

  @override
  String get biliGoLogin => '去登录';

  @override
  String get biliCookieScopeHint => '请在账号设置中开启「携带 Cookie 请求」与「互动操作」范围';

  @override
  String get videoTabRelated => '相关视频';

  @override
  String get videoTabComments => '评论';

  @override
  String videoTabCommentsCount(int count) {
    return '评论 $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return '选集 $count';
  }

  @override
  String get videoTabIntro => '简介';

  @override
  String danmakuWatching(String count) {
    return '$count人正在看';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '已装填$count条弹幕';
  }

  @override
  String get danmakuToggleOn => '开启弹幕';

  @override
  String get danmakuDisable => '关闭弹幕';

  @override
  String get danmakuInputHint => '发个友善的弹幕见证当下';

  @override
  String get danmakuToastEmpty => '弹幕内容不能为空';

  @override
  String danmakuToastSendFail(String error) {
    return '发送失败：$error';
  }

  @override
  String get danmakuToastSent => '弹幕已发送';

  @override
  String get videoLikeTooltip => '点赞（长按一键三连）';

  @override
  String get videoUnlikeTooltip => '取消点赞';

  @override
  String get videoCoinTooltip => '投币';

  @override
  String get videoFavTooltip => '收藏';

  @override
  String get videoUnfavTooltip => '取消收藏';

  @override
  String get videoShareLabel => '分享';

  @override
  String videoStatRating(String count) {
    return '$count人评分';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count追番';
  }

  @override
  String videoStatWatching(String count) {
    return '$count人在看';
  }

  @override
  String get videoFollowLabel => '关注';

  @override
  String get videoFollowedLabel => '已关注';

  @override
  String get commentDetailEmpty => '还没有回复';

  @override
  String commentDetailNoMore(int count) {
    return '没有更多回复了（共 $count 条）';
  }

  @override
  String get commentDetailLoadMore => '滑动加载更多';

  @override
  String get commentDetailRootBadge => '楼主';

  @override
  String get commentDetailDeleted => '(评论已删除)';

  @override
  String get commentMenuCopy => '复制评论';

  @override
  String get commentMenuSelectText => '选择文本';

  @override
  String get commentDialogTitle => '评论内容';

  @override
  String get commentDialogEmpty => '(这里空空的)';

  @override
  String get danmakuInputBvPrompt => '请输入 BV 号';

  @override
  String get danmakuInputCidPrompt => '请输入 CID';

  @override
  String get danmakuInputCidNumeric => 'CID 必须为纯数字';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return '命中本地缓存：$count 条弹幕 (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return '获取成功：$count 条弹幕 (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => '获取失败';

  @override
  String get danmakuInputTitle => 'Bilibili 弹幕';

  @override
  String get danmakuInputTypeLabel => '类型：';

  @override
  String get danmakuInputBvHint => '输入 BV 号，将自动获取第一个分P的 CID';

  @override
  String get danmakuInputCidHint => '直接输入 CID 纯数字（如从 API 获取）';

  @override
  String get danmakuInputFetching => '获取中...';

  @override
  String get danmakuInputFetchDanmaku => '获取弹幕';

  @override
  String get danmakuInputEmpty => '输入不能为空';

  @override
  String get danmakuCidFetchFail => '无法获取 CID，请检查 BV 号';

  @override
  String danmakuNoData(String oid) {
    return '未获取到弹幕数据（oid=$oid）';
  }

  @override
  String get danmakuSettingsTitle => '弹幕设置';

  @override
  String get danmakuDataSource => '数据源';

  @override
  String get danmakuDisplayControl => '显示控制';

  @override
  String get danmakuEnable => '启用弹幕';

  @override
  String get danmakuSmartMask => '智能防遮挡';

  @override
  String get danmakuSmartMaskDesc => '识别人物，弹幕不遮挡画面主体';

  @override
  String get danmakuTypeFilter => '弹幕类型';

  @override
  String get danmakuTypeScroll => '滚动弹幕';

  @override
  String get danmakuTypeTop => '顶部弹幕';

  @override
  String get danmakuTypeBottom => '底部弹幕';

  @override
  String get danmakuTypeAdvanced => '高级弹幕 (BAS)';

  @override
  String get danmakuAdvancedSubtitle => '动画弹幕，开启可能影响性能';

  @override
  String get danmakuParameters => '参数调节';

  @override
  String get danmakuScrollSpeed => '滚动速度';

  @override
  String get danmakuOpacity => '不透明度';

  @override
  String get danmakuFontSize => '字体大小';

  @override
  String get danmakuMaxLines => '显示行数';

  @override
  String danmakuLinesCount(int count) {
    return '$count 行';
  }

  @override
  String get danmakuQuickActions => '快捷操作';

  @override
  String get danmakuResetParams => '重置参数';

  @override
  String get danmakuClearDanmaku => '清空弹幕';

  @override
  String get danmakuLoadLocalXml => '加载本地 XML 弹幕';

  @override
  String get danmakuFetchOnline => '获取 Bilibili 在线弹幕';

  @override
  String get danmakuNotLoaded => '尚未加载弹幕';

  @override
  String danmakuLoadedCount(int count) {
    return '已加载 $count 条弹幕';
  }

  @override
  String get danmakuBlockColorful => '彩色弹幕';

  @override
  String get danmakuCloudFilter => '智能云屏蔽';

  @override
  String get danmakuCloudFilterOff => '关闭';

  @override
  String danmakuCloudFilterLevel(int level) {
    return '$level 级';
  }

  @override
  String get danmakuFontSizeFS => '全屏字体大小';

  @override
  String danmakuSeconds(int value) {
    return '$value 秒';
  }

  @override
  String get danmakuOthers => '其他';

  @override
  String get danmakuMassiveMode => '海量弹幕';

  @override
  String get danmakuStatic2Scroll => '固定转滚动';

  @override
  String get danmakuShowArea => '显示区域';

  @override
  String get danmakuFontWeight => '字体粗细';

  @override
  String get danmakuStrokeWidth => '描边粗细';

  @override
  String get danmakuScrollDuration => '滚动弹幕时长';

  @override
  String get danmakuStaticDuration => '静态弹幕时长';

  @override
  String get danmakuLineHeight => '弹幕行高';

  @override
  String danmakuResetTo(String value) {
    return '恢复默认：$value';
  }

  @override
  String get naviAddAction => '添加';

  @override
  String playlistImportAdded(int count) {
    return '已添加 $count 个文件';
  }

  @override
  String get playlistAddEpisodeTitle => '添加集数';

  @override
  String get playlistTitleLabel => '标题';

  @override
  String get playlistEpisodeHint => '第 1 集';

  @override
  String get playlistVideoUrlLabel => '视频 URL';

  @override
  String get playlistAdd => '添加';

  @override
  String get playlistNameRequired => '请输入播放列表名称';

  @override
  String get playlistAtLeastOneVideo => '请至少添加一个视频';

  @override
  String get playlistEditTitle => '编辑播放列表';

  @override
  String get playlistCreateTitle => '创建播放列表';

  @override
  String get playlistNameLabel => '播放列表名称';

  @override
  String get playlistNameHint => '我的追番列表';

  @override
  String get playlistWebdavMulti => 'WebDAV 多选';

  @override
  String playlistItemsCount(int count) {
    return '$count 集';
  }

  @override
  String get playlistNoItems => '还没有添加任何视频';

  @override
  String get playlistImportHint => '点击上方按钮导入';

  @override
  String get playlistSaveChanges => '保存修改';

  @override
  String get playlistEpisodePanelTitle => '选集';

  @override
  String playlistEpisodeCurrent(int index) {
    return '当前: 第 $index 集';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what：$message';
  }

  @override
  String get playlistSyncTwoWay => '双向同步播放列表';

  @override
  String get playlistSyncTwoWaySubtitle => '下载云端并合并，再上传合并结果（含背景图）';

  @override
  String get playlistRestoreFromCloud => '从云端恢复';

  @override
  String get playlistRestoreFromCloudSubtitle => '用云端数据整体覆盖本地播放列表（含背景图）';

  @override
  String get playlistUploadToCloud => '上传到云端';

  @override
  String get playlistUploadToCloudSubtitle => '把本地播放列表全量上传（含背景图，不合并）';

  @override
  String get playlistSyncDanmaku => '同步弹幕缓存';

  @override
  String get playlistSyncDanmakuSubtitle => '与云端弹幕缓存互相合并（取较新）';

  @override
  String playlistCreated(String name) {
    return '已创建: $name';
  }

  @override
  String get playlistDeleteTitle => '删除播放列表';

  @override
  String playlistDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get playlistNewTooltip => '新建播放列表';

  @override
  String get playlistListTitle => '播放列表';

  @override
  String get playlistCloudSync => '云同步';

  @override
  String get playlistMyLists => '我的列表';

  @override
  String get playlistNoLists => '暂无播放列表';

  @override
  String playlistListSummary(int count) {
    return '共 $count 个 · 点击列表查看全部剧集';
  }

  @override
  String get playlistEmptyTitle => '还没有播放列表';

  @override
  String get playlistEmptyHint => '点击右下角「创建」按钮新建一个吧';

  @override
  String get playlistResume => '续播';

  @override
  String get playlistEditAction => '编辑';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total 集 · 看到第 $current 集';
  }

  @override
  String get subtitleOff => '关闭字幕';

  @override
  String subtitleTrackFallback(String id) {
    return '轨道 $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return '已加载字幕: $name';
  }

  @override
  String get subtitleWebdavNotConfigured => 'WebDAV 未配置，请先登录';

  @override
  String get subtitleWebdavFolderEmpty => 'WebDAV 字幕文件夹为空';

  @override
  String get subtitleSelectFile => '选择字幕文件';

  @override
  String subtitleDownloadFailed(int code) {
    return '字幕下载失败: HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return '已加载远程字幕: $name';
  }

  @override
  String subtitleLoadError(String error) {
    return '字幕加载异常: $error';
  }

  @override
  String get subtitlePanelTitle => '字幕 (CC)';

  @override
  String get subtitleLoadLocal => '加载本地字幕';

  @override
  String get subtitleLoadWebdav => '从 WebDAV 加载字幕';

  @override
  String get subtitleFontSize => '字号';

  @override
  String get subtitleFontColor => '字体颜色';

  @override
  String get subtitleBgColor => '背景颜色';

  @override
  String get webdavInputPath => '输入路径';

  @override
  String get webdavGoTo => '前往';

  @override
  String get webdavLoginRequired => '请先登录 WebDAV 账号';

  @override
  String get webdavLoginSubtitle => '配置服务器后可浏览远程视频';

  @override
  String get webdavLoginSubtitleMulti => '登录后可多选远程视频创建播放列表';

  @override
  String get webdavRefresh => '刷新';

  @override
  String get webdavRoot => '根';

  @override
  String get webdavParent => '上级';

  @override
  String get webdavFolderEmpty => '此文件夹为空';

  @override
  String get webdavPullToRefresh => '下拉刷新试试?';

  @override
  String get webdavSelectVideo => '请选择视频文件';

  @override
  String get webdavPlay => '播放';

  @override
  String get webdavMultiSelectTitle => '多选文件';

  @override
  String get webdavNoSelection => '未选择文件';

  @override
  String webdavSelectedCount(int count) {
    return '已选 $count 个视频';
  }

  @override
  String webdavSelectionOrder(String names) {
    return '按选择顺序: $names';
  }

  @override
  String get webdavClear => '清空';

  @override
  String get webdavConfirmSelection => '确认选择';

  @override
  String get webdavGoLogin => '去登录';

  @override
  String get profileTitle => '个人信息';

  @override
  String get settingsAvatarTitle => '头像';

  @override
  String get settingsAvatarSet => '已设置';

  @override
  String get settingsNotSet => '未设置';

  @override
  String get settingsAvatarChangeTooltip => '更换头像';

  @override
  String get settingsAvatarDeleteTooltip => '删除头像';

  @override
  String get settingsAvatarUpdated => '头像已更新';

  @override
  String settingsPickAvatarFailed(String error) {
    return '选择头像失败：$error';
  }

  @override
  String get settingsAvatarDeleteTitle => '删除头像';

  @override
  String get settingsAvatarDeleteConfirm => '确定要删除当前头像吗？';

  @override
  String get settingsAvatarDeleteConfirmPermanent => '确定要删除当前头像吗？此操作无法撤销。';

  @override
  String get settingsAvatarDeleted => '头像已删除';

  @override
  String get settingsNickname => '昵称';

  @override
  String get settingsNicknameEditTooltip => '编辑昵称';

  @override
  String get settingsSetNickname => '设置昵称';

  @override
  String get settingsNicknamePrompt => '请输入您的昵称';

  @override
  String get settingsNicknameHint => '输入昵称';

  @override
  String get settingsNicknameEmpty => '昵称不能为空';

  @override
  String get settingsNicknameTooLong => '昵称长度不能超过 20 个字符';

  @override
  String get settingsNicknameUpdated => '昵称已更新';

  @override
  String get settingsLockWallpaper => '锁屏壁纸';

  @override
  String get settingsWallpaperCustomSet => '已设置自定义壁纸';

  @override
  String get settingsWallpaperDefaultBg => '使用默认深色背景';

  @override
  String get settingsWallpaperUpdated => '壁纸已更新';

  @override
  String get settingsWallpaperPickTooltip => '选择壁纸';

  @override
  String get settingsWallpaperDelete => '删除壁纸';

  @override
  String get settingsWallpaperDeleteConfirm => '确定要删除锁屏壁纸并恢复默认吗？';

  @override
  String get settingsWallpaperDeleted => '壁纸已删除';

  @override
  String get settingsDecoImage => '右下角装饰图';

  @override
  String get settingsDecoImageSet => '已设置 (支持透明 PNG/WebP)';

  @override
  String get settingsDecoImageUpdated => '装饰图已更新';

  @override
  String settingsPickImageFailed(String error) {
    return '选择图片失败：$error';
  }

  @override
  String get settingsPickImageTooltip => '选择图片';

  @override
  String get settingsDecoImageDelete => '删除装饰图';

  @override
  String get settingsDecoImageDeleteConfirm => '确定要删除右下角装饰图吗？';

  @override
  String get settingsDecoImageDeleted => '装饰图已删除';

  @override
  String get settingsSize => '大小';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => '透明';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => '显示';

  @override
  String get settingsDisplaySubtitle => '主题 · 配色 · 文字 · 缩放';

  @override
  String get settingsAppTheme => '应用主题';

  @override
  String settingsCurrentColor(String color) {
    return '当前配色：#$color';
  }

  @override
  String get settingsFontWeight => '文字粗细';

  @override
  String settingsCurrentFontWeight(int weight) {
    return '当前粗细：$weight';
  }

  @override
  String get settingsDisplayScale => '显示缩放';

  @override
  String settingsCurrentScale(int percent) {
    return '当前比例：$percent%';
  }

  @override
  String get settingsRestrictIp => '限制内网 IP 连接';

  @override
  String get settingsRestrictIpSubtitle => '仅允许 A 类、B 类、C 类内网 IP 地址';

  @override
  String get settingsDefaultPort => '默认端口';

  @override
  String get settingsAdjustFontWeight => '调整文字粗细';

  @override
  String settingsFontWeightPreview(int weight) {
    return '预览：$weight';
  }

  @override
  String get settingsWeightHairline => '极细';

  @override
  String get settingsWeightThin => '细';

  @override
  String get settingsWeightRegular => '常规';

  @override
  String get settingsWeightMedium => '中等';

  @override
  String get settingsWeightBold => '粗';

  @override
  String get settingsWeightBlack => '极粗';

  @override
  String get settingsFontWeightUpdated => '字体粗细已更新';

  @override
  String get logTitle => '日志';

  @override
  String get logBackTooltip => '转到上一层级';

  @override
  String get logRefresh => '刷新';

  @override
  String get logClearAll => '清空日志';

  @override
  String get logClearTitle => '清空日志';

  @override
  String get logClearConfirm => '将删除 error/ 与 mpv/ 目录下的全部日志文件，确定吗？';

  @override
  String get logClearAction => '清空';

  @override
  String logDeletedCount(int count) {
    return '已删除 $count 个日志文件';
  }

  @override
  String get logCopyContent => '复制内容';

  @override
  String get logShare => '分享日志';

  @override
  String get logDeleteThis => '删除此日志';

  @override
  String get logEmptyContent => '（空日志）';

  @override
  String logStorageLocation(String path) {
    return '存储位置：$path';
  }

  @override
  String get logErrorSection => '错误日志（崩溃必写）';

  @override
  String get logNoErrorLogs => '暂无错误日志';

  @override
  String get logMpvSection => 'mpv 日志（可选）';

  @override
  String get logNoMpvLogs => '暂无 mpv 日志';

  @override
  String get logReadingLogs => '正在读取日志…';

  @override
  String get lockFollowThemeColor => '跟随主题色 (时间)';

  @override
  String get lockShowBattery => '显示电池';

  @override
  String get lockShowNetwork => '显示网络';

  @override
  String lockDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get myQrSelectIpHint => '点击选择二维码使用的 IP';

  @override
  String get myQrNoIpType => '无该类型 IP';

  @override
  String get myQrInUse => '使用中';

  @override
  String get myQrSetAsQr => '设为二维码';

  @override
  String get netLanDiscoveryPort => '本机发现端口';

  @override
  String netDohNoRecord(String domain) {
    return '未查询到 $domain 的 A 记录';
  }

  @override
  String netDohQueryFailed(String error) {
    return '查询失败: $error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return '已保存映射: $domain → $ip';
  }

  @override
  String get netAddHostMapping => '添加 Host 映射';

  @override
  String get netDomainLabel => '域名';

  @override
  String get netIpLabel => 'IP 地址';

  @override
  String get netAdd => '添加';

  @override
  String netMappingAdded(String host, String ip) {
    return '已添加映射: $host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return '已移除映射: $host';
  }

  @override
  String get netTitle => '网络';

  @override
  String get netBackTooltip => '转到上一层级';

  @override
  String get netRetestAll => '全部重测';

  @override
  String get netConnectionModeSection => '连接模式';

  @override
  String get netNetworkMode => '网络模式';

  @override
  String get netModeStandardLabel => '标准模式';

  @override
  String get netModeCompatLabel => '兼容直连';

  @override
  String get netModeStandardDesc => '使用系统默认网络栈';

  @override
  String get netAllowInsecureCert => '允许不安全证书';

  @override
  String get netAllowInsecureCertDesc => '兼容直连时跳过证书校验 (IP 直连场景)';

  @override
  String get netChatIpv6 => '聊天 IPv6';

  @override
  String get netChatIpv6On => '已开启：支持 IPv6 聊天、发现与二维码';

  @override
  String get netChatIpv6Off => '已关闭：仅使用 IPv4 聊天';

  @override
  String get netChatIpv6EnabledSnack => '已开启聊天 IPv6（重启应用生效）';

  @override
  String get netChatIpv6DisabledSnack => '已关闭聊天 IPv6（重启应用生效）';

  @override
  String get netLocalSendCompat => 'LocalSend 兼容';

  @override
  String get netLocalSendCompatOn =>
      '已开启：启用 LocalSend 协议（端口 53317），可与 LocalSend 官方客户端互传文件';

  @override
  String get netLocalSendCompatOff => '已关闭：使用 navi 原生协议方案';

  @override
  String get netLocalSendCompatEnabledSnack => '已开启 LocalSend 兼容';

  @override
  String get netLocalSendCompatDisabledSnack => '已关闭 LocalSend 兼容（恢复原生方案）';

  @override
  String get lsSectionTitle => 'LocalSend 设备';

  @override
  String get lsHintEnable => 'LocalSend 兼容未开启';

  @override
  String get lsHintEnableDesc =>
      '开启后可与 LocalSend 官方客户端（Android/iOS/Windows/macOS/Linux）互传文件';

  @override
  String get lsEnableNow => '开启';

  @override
  String get lsEnabledSnack => '已开启 LocalSend 兼容';

  @override
  String get lsNoDevices => '未发现 LocalSend 设备';

  @override
  String get lsHttpScan => 'HTTP 扫描';

  @override
  String get lsHttpScanning => '正在扫描局域网（组播不通时的兜底）...';

  @override
  String get lsHttpScanDone => '扫描完成';

  @override
  String get lsSendFile => '发送文件';

  @override
  String get lsSendFileDesc => '通过 LocalSend 协议发送到该设备';

  @override
  String get lsProbe => '重新探测';

  @override
  String get lsProbing => '正在探测...';

  @override
  String get lsProbeFound => '探测成功';

  @override
  String get lsProbeNotFound => '设备未响应';

  @override
  String lsPickFailed(String error) {
    return '选择文件失败：$error';
  }

  @override
  String get lsNoPath => '无法获取文件路径';

  @override
  String lsSendingTitle(String alias) {
    return '正在发送到 $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '成功发送 $count 个文件';
  }

  @override
  String lsSendFailed(int count) {
    return '有 $count 个文件发送成功，其余失败';
  }

  @override
  String get lsReceiveRequestTitle => '接收文件请求';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return '对方发送了 $count 个文件，共 $size';
  }

  @override
  String get lsAccept => '接受';

  @override
  String get lsReject => '拒绝';

  @override
  String get lsOpenFile => '打开文件';

  @override
  String get lsReceiveCompleteTitle => '文件接收完成';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName 已保存到：\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return '已接收文件：$fileName';
  }

  @override
  String get netConnectivitySection => '连通性测试';

  @override
  String get netHostMappingSection => 'Host 映射';

  @override
  String get netMappingReset => '已恢复内置默认 IP 表';

  @override
  String get netRestoreDefaults => '恢复默认';

  @override
  String get netNoMappings => '暂无映射';

  @override
  String get netAddMapping => '添加映射';

  @override
  String get netDohQuerySection => 'DoH 查询';

  @override
  String get netDohQueryDesc =>
      '通过 Cloudflare JSON DNS API 查询域名 A 记录，结果可一键保存为 Host 映射';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => '保存为映射';

  @override
  String get netHeadersSection => '请求头';

  @override
  String get netRefererNotSet => '未设置 (示例: https://www.bilibili.com/)';

  @override
  String get netNotSet => '未设置';

  @override
  String netHeaderEditorTitle(String title) {
    return '设置 $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title 已保存';
  }

  @override
  String get ossTitle => '开源许可';

  @override
  String get ossBackTooltip => '转到上一层级';

  @override
  String get ossThanks => '致谢';

  @override
  String ossSummary(int count) {
    return '本项目基于 Flutter 构建，共引用 $count 个开源项目，涵盖 MIT、Apache-2.0 与 BSD-3-Clause 许可证。点击条目即可查看完整许可文本，感谢所有开源作者的无私贡献。';
  }

  @override
  String ossGroupCount(String name, int count) {
    return '$name · $count 项';
  }

  @override
  String get ossCopyFullText => '复制全文';

  @override
  String get ossLicenseCopied => '许可文本已复制到剪贴板';

  @override
  String get playHistoryTitle => '播放历史';

  @override
  String get playHistoryBackTooltip => '转到上一层级';

  @override
  String get playHistoryClearAll => '清空全部';

  @override
  String get playHistoryEmpty => '这里空空的';

  @override
  String get playHistoryEmptySub => '唔,今天真是寂寞如雪啊';

  @override
  String get playHistoryClearTitle => '清空播放历史';

  @override
  String get playHistoryClearConfirm => '您确定要删除所有保存的播放进度吗？此操作不可撤销。';

  @override
  String get playHistoryClearAction => '清空';

  @override
  String get playHistoryResume => '继续播放';

  @override
  String get playHistoryDeleteRecord => '删除记录';

  @override
  String playHistoryDeleted(String title) {
    return '已删除「$title」的播放记录';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get playerArtistVideo => '视频播放';

  @override
  String get playerArtistPlaylist => '播放列表';

  @override
  String get playerArtistWebdav => 'WebDAV 视频';

  @override
  String get playerWebdavSubtitle => 'WebDAV 字幕';

  @override
  String playerResumeFrom(String position) {
    return '已从 $position 继续播放';
  }

  @override
  String playerNowPlaying(String title) {
    return '正在播放: $title';
  }

  @override
  String playerDanmakuCache(int count) {
    return '弹幕缓存 ($count条)';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili 弹幕 ($count条)';
  }

  @override
  String get playerDanmakuNoData => '未解析到弹幕数据';

  @override
  String playerDanmakuLoaded(int count) {
    return '已加载 $count 条弹幕';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili 在线弹幕 ($count条)';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return '已从本地缓存加载 $count 条弹幕';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return '已加载 $count 条在线弹幕';
  }

  @override
  String playerScreenshotFailed(String error) {
    return '截图失败: $error';
  }

  @override
  String get playerSavedToAlbum => '已保存到相册';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return '截图 $fileName 已保存到相册';
  }

  @override
  String playerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String playerPipFailed(String error) {
    return '画中画调用失败: $error';
  }

  @override
  String get playerFitAdapt => '适配';

  @override
  String get playerFitStretch => '拉伸';

  @override
  String get playerFitFill => '填充';

  @override
  String get playerEndPause => '播完暂停';

  @override
  String get playerEndLoop => '洗脑循环';

  @override
  String get playerEndExit => '播完退出';

  @override
  String get playerSubtitleSettings => '字幕设置';

  @override
  String get playerAdvancedSettings => '高级设置';

  @override
  String get playerFlipHorizontal => '水平镜像';

  @override
  String get playerFlipHorizontalDesc => '左右翻转画面';

  @override
  String get playerFlipVertical => '垂直翻转';

  @override
  String get playerFlipVerticalDesc => '上下翻转画面';

  @override
  String get playerShowStats => '显示视频统计信息';

  @override
  String get playerShowStatsDesc => '编码/分辨率/码率/帧率';

  @override
  String get playerAutoPip => '返回桌面自动画中画';

  @override
  String get playerLoadDanmakuOnResume => '恢复播放时加载弹幕';

  @override
  String get playerLoadDanmakuOnResumeDesc => '从播放历史继续时自动读取/拉取弹幕';

  @override
  String get playerDefaultRate => '默认倍速';

  @override
  String get playerDefaultEndBehavior => '默认退出行为';

  @override
  String get playerBuffering => '缓冲中...';

  @override
  String get playerHwdecSoftware => '软解 (SW)';

  @override
  String playerHwdecHardware(String mode) {
    return '硬解 ($mode)';
  }

  @override
  String get playerSourceLocal => '本地文件';

  @override
  String get playerStatResolution => '分辨率';

  @override
  String get playerStatVideoCodec => '视频编码';

  @override
  String get playerStatAudioCodec => '音频编码';

  @override
  String get playerStatBitrate => '码率';

  @override
  String get playerStatFps => '帧率';

  @override
  String get playerStatDecode => '解码';

  @override
  String get playerStatSubtitle => '字幕';

  @override
  String get playerOn => '开启';

  @override
  String get playerOff => '关闭';

  @override
  String get playerStatDanmaku => '弹幕';

  @override
  String get playerStatDownload => '下载';

  @override
  String get playerStatSource => '来源';

  @override
  String get playerStatPosition => '进度';

  @override
  String get playerStatDuration => '时长';

  @override
  String get playerCopyLink => '复制视频链接';

  @override
  String playerCopyLinkAt(String time) {
    return '复制空降链接（$time）';
  }

  @override
  String get playerCopyLinkAt0 => '复制空降链接';

  @override
  String playerCopyLinkDone(String url) {
    return '已复制：$url';
  }

  @override
  String get playerCopyLinkNotBili => '仅 B 站视频支持复制链接';

  @override
  String get playerColorAdjust => '视频色彩调节';

  @override
  String get playerColorBrightness => '亮度';

  @override
  String get playerColorContrast => '对比度';

  @override
  String get playerColorSaturation => '饱和度';

  @override
  String get playerColorHue => '色相';

  @override
  String get playerColorGamma => '伽马';

  @override
  String get playerColorReset => '重置';

  @override
  String get playerColorUnavailable => '当前播放器不支持色彩调节';

  @override
  String get playerStats => '统计信息';

  @override
  String get playerAlignAspectRatio => '对齐宽高比';

  @override
  String get playerAlignAspectRatioDone => '窗口已对齐视频比例';

  @override
  String get playerAlignAspectRatioFailed => '无法获取视频尺寸';

  @override
  String get commonClose => '关闭';

  @override
  String get playerPlaybackError => '播放出错';

  @override
  String playerAllEpisodesPlayed(int count) {
    return '已播放完全部 $count 集';
  }

  @override
  String playerFastForwarding(String rate) {
    return '$rate 倍速播放中';
  }

  @override
  String get playerTapToSave => '点我保存';

  @override
  String get playerResetScreen => '还原屏幕';

  @override
  String get playerBackTooltip => '转到上一层级';

  @override
  String get playerRotate90 => '旋转90度';

  @override
  String get playerQuality => '画质';

  @override
  String get playerQualityLocked => '该画质不可用（需登录或大会员）';

  @override
  String get playerFullscreen => '全屏';

  @override
  String get playerBiliSubtitle => 'B站字幕';

  @override
  String get playerDecodeFormat => '解码格式';

  @override
  String get playerDecodeFormatSwitchFailed => '切换解码格式失败';

  @override
  String get playerDecodeAuto => '自动';

  @override
  String get playerDecodeAutoShort => '自动';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => '字幕加载失败';

  @override
  String get playerPortraitMode => '竖屏模式';

  @override
  String get playerLandscapeMode => '横屏模式';

  @override
  String get playerDescription => '简介';

  @override
  String get playerWebdavSource => 'WebDAV 视频源';

  @override
  String get playerCast => '投屏';

  @override
  String get playerWatchTogether => '一起看';

  @override
  String get watchInviteTitle => '邀请你一起看视频';

  @override
  String get watchWaitingAccept => '等待对方接受…';

  @override
  String get watchSelectPeer => '选择一起看的好友';

  @override
  String get watchNoOnlinePeer => '没有在线的联系人';

  @override
  String watchInviteSent(String name) {
    return '已发送一起看邀请给 $name';
  }

  @override
  String watchActiveWith(String name) {
    return '正在与 $name 一起看';
  }

  @override
  String get watchPeerRejected => '对方拒绝了你的邀请';

  @override
  String get watchPeerNoAnswer => '对方没有接受邀请';

  @override
  String get watchPeerLeft => '对方已退出一起看';

  @override
  String get watchTcpFailed => '无法建立连接，一起看失败';

  @override
  String get watchConnectionDropped => '连接已断开，一起看失败';

  @override
  String get watchUrlInvalid => '视频地址不可用，无法发起一起看';

  @override
  String get rcInviteTitle => '请求远程控制你的设备';

  @override
  String get rcInviteHint => '同意后对方可以看到你的屏幕并操作你的设备';

  @override
  String get rcPeerRejected => '对方拒绝了远程控制请求';

  @override
  String get rcTcpFailed => '无法建立连接，远程控制失败';

  @override
  String get rcConnectionDropped => '连接已断开，远程控制失败';

  @override
  String get rcTimeout => '等待对方响应超时';

  @override
  String get rcShizukuNotInstalled => '对方设备未安装 Shizuku';

  @override
  String get rcShizukuNotInstalledHint =>
      '被控端需要安装并启动 Shizuku 服务（shizuku.rikka.app）';

  @override
  String get rcShizukuGrantTitle => '需要 Shizuku 授权';

  @override
  String get rcShizukuGrantHint => '被控端授予 Navi Shizuku 权限后，对方才能远程操作屏幕';

  @override
  String get rcShizukuGrant => '授权 Shizuku';

  @override
  String get rcRequesting => '请求中…';

  @override
  String get rcShizukuNotGranted => 'Shizuku 未授权';

  @override
  String rcScreenCaptureFailed(String error) {
    return '屏幕采集失败：$error';
  }

  @override
  String get rcShareFailed => '屏幕共享失败';

  @override
  String get rcRetry => '重试';

  @override
  String get rcClose => '关闭';

  @override
  String get rcCancel => '取消';

  @override
  String get rcSend => '发送';

  @override
  String get rcConnecting => '正在连接…';

  @override
  String rcControlling(String name) {
    return '正在远程控制 $name';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name 正在远程控制你的设备';
  }

  @override
  String get rcEnd => '结束远程控制';

  @override
  String get rcConnectionLost => '远程控制连接已断开';

  @override
  String get rcSessionEnded => '远程控制已结束';

  @override
  String get rcInputText => '输入文字';

  @override
  String get rcInputTextHint => '要发送到对方设备上的文字';

  @override
  String get rcKeyBack => '返回';

  @override
  String get rcKeyHome => '主页';

  @override
  String get rcKeyRecents => '最近任务';

  @override
  String get rcKeyVolumeUp => '音量+';

  @override
  String get rcKeyVolumeDown => '音量-';

  @override
  String get dlnaPageTitle => '投屏';

  @override
  String get dlnaRefresh => '重新搜索';

  @override
  String get dlnaSearching => '正在搜索局域网投屏设备…';

  @override
  String get dlnaNoDevice => '未发现可投屏设备';

  @override
  String get dlnaNoDeviceHint => '请确认电视/盒子与本机处于同一局域网，且已开启 DLNA/投屏功能';

  @override
  String get dlnaSearchAgain => '重新搜索';

  @override
  String get dlnaFoundDevices => '发现设备';

  @override
  String dlnaCastStarted(String device) {
    return '已投屏到 $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return '投屏失败：$device';
  }

  @override
  String dlnaCastingTo(String device) {
    return '正在投屏到 $device';
  }

  @override
  String get dlnaStopCast => '停止投屏';

  @override
  String get dlnaPlay => '播放';

  @override
  String get dlnaPause => '暂停';

  @override
  String get dlnaVolumeUp => '增大音量';

  @override
  String get dlnaVolumeDown => '减小音量';

  @override
  String get dlnaFileMissing => '视频文件不存在';

  @override
  String dlnaServerStartFailed(String error) {
    return '本地文件服务启动失败：$error';
  }

  @override
  String get playerEpisodeSelect => '选集';

  @override
  String get playerDanmakuSettings => '弹幕设置';

  @override
  String get psTitle => '播放器';

  @override
  String get psBackTooltip => '转到上一层级';

  @override
  String get psStaffEntrance => '员工通道';

  @override
  String get psDisplaySection => '显示';

  @override
  String get psStatusBar => '状态栏';

  @override
  String get psStatusBarDesc => '在播放器顶部显示时间、电量与网络图标';

  @override
  String get psKeepWindowRatio => '等比例拉伸窗口';

  @override
  String get psKeepWindowRatioDesc => '播放时窗口仅允许按当前比例缩放';

  @override
  String get psKeepWindowRatioDesktopOnly => '仅 Windows / macOS / Linux 桌面平台生效';

  @override
  String get psInteractionSection => '交互';

  @override
  String get psLongPressSpeed => '长按键加速';

  @override
  String get psLongPressSpeedDesc => '按住屏幕或键盘 D 键以 2× 倍速快进';

  @override
  String get psScreenshot => '截图功能';

  @override
  String get psScreenshotDesc => '允许在播放器中截取当前画面并保存至相册';

  @override
  String get psScreenshotDanmaku => '截图时显示弹幕';

  @override
  String get psScreenshotDanmakuDesc => '截图时把当前弹幕一并截入画面';

  @override
  String get psProgressSection => '进度';

  @override
  String get psPlayProgress => '播放进度';

  @override
  String get psNoHistory => '暂无保存的播放记录';

  @override
  String psHistoryCount(int count) {
    return '您有 $count 条记录';
  }

  @override
  String get psMiscSection => '杂项';

  @override
  String get psHwdec => '硬件解码';

  @override
  String get psHwdecAuto => '自动选择最佳解码器';

  @override
  String get psHwdecSoftware => '强制使用 CPU 软件解码';

  @override
  String get psHwdecAutoShort => '自动';

  @override
  String get psHwdecPureSoftware => '纯软解';

  @override
  String get psVideoSync => '视频同步';

  @override
  String get psVsyncAudioDefault => '以音频时钟为基准（默认）';

  @override
  String get psVsyncResample => '重采样音频以匹配显示刷新率';

  @override
  String get psVsyncAdrop => '丢弃 / 重复音频帧以匹配显示';

  @override
  String get psVsyncVdrop => '丢弃 / 重复视频帧以匹配显示';

  @override
  String get psVsyncAudio => '音频';

  @override
  String get psVsyncDisplayResample => '显示重采样';

  @override
  String get psVsyncDisplayAdrop => '显示音频丢弃';

  @override
  String get psVsyncDisplayVdrop => '显示视频丢弃';

  @override
  String get psImmersiveLongPress => '沉浸模式长按加速';

  @override
  String get psImmersiveLongPressDesc => '控制栏隐藏时仍可通过长按触发 2× 倍速';

  @override
  String get psLogSection => '日志';

  @override
  String get psMpvLog => '记录 mpv 日志';

  @override
  String psMpvLogEnabled(String level) {
    return '已开启，下次播放生效（细度：$level）';
  }

  @override
  String get psMpvLogDisabled => '关闭。崩溃日志始终记录，不受此开关影响';

  @override
  String get psMpvLogLevel => 'mpv 日志细度';

  @override
  String get psMpvLogLevelDesc => '细度越高日志越详细，占用空间也越大';

  @override
  String get psMpvLogError => '仅错误';

  @override
  String get psMpvLogWarn => '警告';

  @override
  String get psMpvLogWarnDefault => '警告（默认）';

  @override
  String get psMpvLogInfo => '信息';

  @override
  String get psMpvLogVerbose => '详细';

  @override
  String get psMpvLogDebug => '调试';

  @override
  String get psMpvLogTrace => '全部（极详细）';

  @override
  String get psViewLogs => '查看日志';

  @override
  String get psViewLogsDesc => '浏览错误日志与 mpv 日志，支持分享与清除';

  @override
  String testPlaylistCreated(String name) {
    return '已创建: $name';
  }

  @override
  String get testPageTitle => '测试页';

  @override
  String get testVideoSourceSection => '视频来源';

  @override
  String get testVideoSourceSubtitle => '选择一个来源开始播放';

  @override
  String get testWebdavVideo => 'WebDAV 视频';

  @override
  String get testWebdavVideoDesc => '从 WebDAV 服务器浏览并播放';

  @override
  String get testLocalVideo => '本地视频';

  @override
  String get testLocalVideoDesc => '从设备存储中选择视频文件';

  @override
  String get testRecentSection => '最近播放';

  @override
  String get testLastPlayedSubtitle => '上次播放记录';

  @override
  String get testNoRecords => '暂无播放记录';

  @override
  String get testPlaylistSection => '播放列表';

  @override
  String get testPlaylistSectionSubtitle => '创建、管理播放列表，选集播放';

  @override
  String get testPlaylistManage => '播放列表管理';

  @override
  String get testPlaylistManageDesc => '查看 / 编辑 / 删除播放列表，点击直接播放';

  @override
  String get testPlaylistCreate => '新建播放列表';

  @override
  String get testPlaylistCreateDesc => 'WebDAV 多选文件建表 / 手动逐集导入';

  @override
  String get testQuickActionsSection => '快捷操作';

  @override
  String get testQuickActionsSubtitle => '常用测试入口';

  @override
  String get testUrlDirectPlay => 'URL 直接播放';

  @override
  String get testUrlDirectPlayDesc => '输入视频 URL 直接播放';

  @override
  String get testVideoWithSubtitle => '视频 + 字幕';

  @override
  String get testVideoWithSubtitleDesc => '同时选择视频和字幕文件';

  @override
  String get testNoVideoPlayed => '还没有播放过任何视频';

  @override
  String get testEnterUrlTitle => '输入视频 URL';

  @override
  String get testPlay => '播放';

  @override
  String get testAddSubtitleTitle => '添加字幕？';

  @override
  String testAddSubtitlePrompt(String name) {
    return '已选择视频：$name\n是否要加载外挂字幕？';
  }

  @override
  String get testSkip => '跳过';

  @override
  String get testSelectSubtitle => '选择字幕';

  @override
  String get testAboutLegalese => '播放器前端测试页面';

  @override
  String get testAboutBody =>
      '此页面用于测试 MpvPlayerPage 的各种入口：\n• WebDAV 远程视频\n• 本地视频文件\n• URL 直接播放\n• 视频 + 外挂字幕';

  @override
  String get testSourceLocal => '本地文件';

  @override
  String get testSourceLocalSubtitle => '本地 + 字幕';

  @override
  String get accountsBiliLoginSuccess => 'B 站登录成功';

  @override
  String get accountsBiliLogoutTitle => '退出 B 站登录？';

  @override
  String get accountsBiliLogoutHint => '退出后将不再携带 Cookie 请求 B 站 API。';

  @override
  String get accountsClearWebviewCookieTitle => '同时清空内置浏览器 Cookie';

  @override
  String get accountsClearWebviewCookieSubtitle => '不勾选也没关系，之后可在账号设置里手动清除';

  @override
  String get accountsLogout => '退出';

  @override
  String get accountsLoggedOutWithCookie => '已退出登录并清空浏览器 Cookie';

  @override
  String get accountsLoggedOut => '已退出登录';

  @override
  String get accountsClearCookieTitle => '清空内置浏览器 Cookie？';

  @override
  String get accountsClearCookieContent => '将清除内置浏览器保存的全部 Cookie，包括网页端的登录状态。';

  @override
  String get accountsClearAction => '清空';

  @override
  String get accountsCookieCleared => '已清空内置浏览器 Cookie';

  @override
  String get accountsCookieEmpty => '暂无内置浏览器 Cookie 可清（浏览器未使用过）';

  @override
  String get accountsBiliLoginTitle => '登录 B 站账号';

  @override
  String get accountsBiliLoginSubtitle => '扫码 / 粘贴 Cookie / 密码登录';

  @override
  String get accountsClearBrowserCookie => '清空内置浏览器 Cookie';

  @override
  String get accountsClearBrowserCookieSubtitle => '清除网页端残留登录态';

  @override
  String get accountsLoggedIn => '已登录';

  @override
  String accountsLoggedInUid(int mid) {
    return '已登录 · UID $mid';
  }

  @override
  String get accountsCarryCookie => '携带 Cookie 请求';

  @override
  String get accountsCarryCookieOn => '已开启：B 站 API 以登录身份请求';

  @override
  String get accountsCarryCookieOff => '已关闭：B 站 API 以游客身份请求';

  @override
  String get accountsCookieScope => 'Cookie 使用范围';

  @override
  String get accountsCookieScopeSubtitle => '选择哪些请求使用账号 Cookie';

  @override
  String get cookieScopeTitle => 'Cookie 使用范围';

  @override
  String get cookieScopeHint =>
      '仅影响以下请求类型；「携带 Cookie 请求」总开关关闭时，下列设置不生效。B 站在线收藏夹操作始终携带登录 Cookie。';

  @override
  String get cookieScopeVideo => '视频详情与播放';

  @override
  String get cookieScopeVideoDesc => '视频详情、播放地址与历史进度上报';

  @override
  String get cookieScopeComments => '评论';

  @override
  String get cookieScopeCommentsDesc => '评论区列表请求';

  @override
  String get cookieScopeSearch => '搜索';

  @override
  String get cookieScopeSearchDesc => '搜索建议与搜索结果请求';

  @override
  String get cookieScopeArticle => '专栏与动态';

  @override
  String get cookieScopeArticleDesc => '专栏文章与动态内容请求';

  @override
  String get cookieScopeUserSpace => '用户空间';

  @override
  String get cookieScopeUserSpaceDesc => 'UP 主空间、投稿与粉丝列表请求';

  @override
  String get cookieScopeSeason => '番剧与剧集';

  @override
  String get cookieScopeSeasonDesc => '番剧详情与剧集列表请求';

  @override
  String get cookieScopeInteractions => '互动操作';

  @override
  String get cookieScopeInteractionsDesc => '点赞、投币、收藏、关注、发送弹幕等；关闭后无法互动';

  @override
  String get cookieScopeEnableAll => '全部开启';

  @override
  String get cookieScopeDisableAll => '全部关闭';

  @override
  String get accountsWebdavCloud => 'WebDAV 云盘';

  @override
  String get accountsWebdavConfiguredOn => '已配置 · 自动备份已开启';

  @override
  String get accountsWebdavConfiguredOff => '已配置 · 自动备份未开启';

  @override
  String get accountsWebdavNotConfigured => '未配置 · 点击进入设置';

  @override
  String get accountsTitle => '账号';

  @override
  String get accountsSectionBili => 'B 站账号';

  @override
  String get commonBackTooltip => '转到上一层级';

  @override
  String get biliLoginFetchingQr => '正在获取二维码…';

  @override
  String get biliLoginQrFetchFailed => '获取二维码失败，请检查网络';

  @override
  String get biliLoginScanWithApp => '请使用 B 站 App 扫码登录';

  @override
  String get biliLoginInputAccountPwd => '请输入账号和密码';

  @override
  String get biliLoginFailedRetry => '登录失败，请重试';

  @override
  String get biliLoginTitle => 'B 站登录';

  @override
  String get biliLoginScanMode => '扫码登录';

  @override
  String get biliLoginCookieMode => '粘贴 Cookie';

  @override
  String get biliLoginPwdMode => '密码登录';

  @override
  String get biliLoginViaBrowser => '使用内置浏览器登录';

  @override
  String get biliLoginCookieHint => '登录后「携带 Cookie 请求」默认开启，可在 设置 → 账号 中关闭';

  @override
  String get biliLoginWebTitle => '网页版登录';

  @override
  String get biliLoginCookieImportFailed => '网页登录 Cookie 导入失败，请重试或改用其他方式';

  @override
  String get biliLoginRefetch => '重新获取';

  @override
  String get biliLoginRefreshQr => '刷新二维码';

  @override
  String get biliLoginScanTip => '提示：打开 B 站 App → 扫一扫，或用「哔哩哔哩」小程序扫码';

  @override
  String get biliLoginCookieInstruction =>
      '在电脑浏览器登录 bilibili.com，按 F12 打开开发者工具 → Application → Cookies → bilibili.com，复制全部 Cookie（以 SESSDATA= 开头的一串），粘贴到下方输入框';

  @override
  String get biliLoginVerifying => '校验中…';

  @override
  String get biliLoginVerifyAndLogin => '登录并校验';

  @override
  String get biliLoginAccountLabel => '账号（手机号 / 邮箱 / 用户名）';

  @override
  String get biliLoginPasswordLabel => '密码';

  @override
  String get biliLoginLoggingIn => '登录中…';

  @override
  String get biliLoginLoginAction => '登录';

  @override
  String get biliLoginSliderHint => '账号密码登录可能触发滑块验证码，完成验证后会自动重试';

  @override
  String get searchFilterAny => '不限';

  @override
  String get searchFilterLastDay => '最近一天';

  @override
  String get searchFilterLastWeek => '最近一周';

  @override
  String get searchFilterHalfYear => '最近半年';

  @override
  String get searchFilterAllDuration => '全部时长';

  @override
  String get searchFilterDur0to10 => '0-10分钟';

  @override
  String get searchFilterDur10to30 => '10-30分钟';

  @override
  String get searchFilterDur30to60 => '30-60分钟';

  @override
  String get searchFilterDur60plus => '60分钟+';

  @override
  String get searchZoneAll => '全部';

  @override
  String get searchZoneAnime => '动画';

  @override
  String get searchZoneGuochuang => '国创';

  @override
  String get searchZoneMusic => '音乐';

  @override
  String get searchZoneDance => '舞蹈';

  @override
  String get searchZoneGame => '游戏';

  @override
  String get searchZoneKnowledge => '知识';

  @override
  String get searchZoneTech => '科技';

  @override
  String get searchZoneSports => '运动';

  @override
  String get searchZoneCar => '汽车';

  @override
  String get searchZoneLife => '生活';

  @override
  String get searchZoneFood => '美食';

  @override
  String get searchZoneAnimal => '动物';

  @override
  String get searchZoneKichiku => '鬼畜';

  @override
  String get searchZoneFashion => '时尚';

  @override
  String get searchZoneInfo => '资讯';

  @override
  String get searchZoneEnt => '娱乐';

  @override
  String get searchZoneDoc => '记录';

  @override
  String get searchZoneFilm => '电影';

  @override
  String get searchZoneTv => '电视';

  @override
  String get searchCaptchaInitFailed => '验证码初始化失败';

  @override
  String get searchCaptchaIncomplete => '未完成滑块验证';

  @override
  String get searchCaptchaValidateFailed => '验证码校验失败';

  @override
  String get searchCaptchaValidateFailedRetry => '验证码校验失败，请重试';

  @override
  String get searchCaptchaPassed => '验证通过，正在重新搜索';

  @override
  String get searchBiliHint => '搜索 B 站…';

  @override
  String get searchHistoryTitle => '搜索历史';

  @override
  String get searchHistoryClear => '清空';

  @override
  String get searchHistoryClearConfirm => '确定清空当前分区的搜索历史？';

  @override
  String get searchHistoryEmpty => '暂无搜索历史';

  @override
  String get searchVideoFilter => '视频搜索筛选';

  @override
  String searchFilterWithCount(int count) {
    return '筛选 · $count';
  }

  @override
  String get searchFilter => '筛选';

  @override
  String get searchSwitchSingleCol => '单列';

  @override
  String get searchSwitchMulti => '多列';

  @override
  String get searchLayoutMulti => '多列';

  @override
  String get searchLayoutSingle => '单列';

  @override
  String get searchPickStartDate => '选择开始日期';

  @override
  String get searchPickEndDate => '选择结束日期';

  @override
  String get searchPubTimeSection => '发布时间';

  @override
  String get searchDateBegin => '开始';

  @override
  String get searchDateTo => '至';

  @override
  String get searchDateEnd => '结束';

  @override
  String get searchDurationSection => '内容时长';

  @override
  String get searchZoneSection => '内容分区';

  @override
  String get searchAntiFuzzy => '防模糊搜索';

  @override
  String get searchAntiFuzzyHint => '限定 2009-06-26 至今的结果，避免异常早期数据干扰';

  @override
  String get searchFilterReset => '重置';

  @override
  String get searchAllLoaded => '— 已全部加载 —';

  @override
  String get searchKeywordHint => '输入关键词搜索 B 站';

  @override
  String get searchPressToSearch => '点击「搜索」或回车开始搜索';

  @override
  String searchNoResultInType(String keyword, String type) {
    return '「$keyword」在$type中暂无结果';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · 共 $count 个结果';
  }

  @override
  String get userSpaceLoadFailed => '加载失败';

  @override
  String get userSpaceAvatarLoadFailed => '头像加载失败';

  @override
  String get userSpaceTitle => 'UP 主空间';

  @override
  String get userSpaceLoading => '正在加载 UP 主空间…';

  @override
  String get userSpaceLoadingName => '加载中…';

  @override
  String get userSpaceStatFans => '粉丝';

  @override
  String get userSpaceStatFollowing => '关注';

  @override
  String get userSpaceStatVideos => '视频';

  @override
  String get userSpaceStatLikes => '获赞';

  @override
  String userSpaceVideoCount(int count) {
    return '共 $count 个视频';
  }

  @override
  String get userSpaceSectionAllVideos => '全部视频';

  @override
  String get userSpaceNoVideos => '暂无投稿';

  @override
  String get userSpaceDynLoadFailed => '动态加载失败';

  @override
  String get userSpaceNoDynamics => '暂无动态';

  @override
  String get userSpaceBangumiLoadFailed => '追番列表加载失败';

  @override
  String get userSpaceNoBangumi => '暂无追番';

  @override
  String userSpaceBangumiCount(int count) {
    return '追番 · 共 $count 部';
  }

  @override
  String get userSpaceLazySign => '这个人很懒，什么都没有留下';

  @override
  String get userSpaceTabHome => '主页';

  @override
  String get userSpaceTabDynamic => '动态';

  @override
  String get userSpaceTabBangumi => '追番';

  @override
  String get userSpaceToday => '今天';

  @override
  String get userSpaceBangumiFinished => '完结';

  @override
  String get userSpaceBangumiSerializing => '连载中';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return '开播 $date';
  }

  @override
  String get browserApp => '应用';

  @override
  String browserOpenAppAttempt(String app) {
    return '网页尝试打开: $app';
  }

  @override
  String get browserNoAppForLink => '未找到可打开该链接的应用';

  @override
  String get browserOpenFailedSystem => '打开失败: 未安装对应应用或受系统限制';

  @override
  String get browserEmptyCookieHint => '这里空空的';

  @override
  String get browserCopyAll => '复制全部';

  @override
  String get browserCookieCopied => 'Cookie已复制';

  @override
  String get browserCookieEmpty => 'Cookie空空的';

  @override
  String get browserSetUaTitle => '设置 User-Agent';

  @override
  String get browserUaHint => '输入自定义 User-Agent';

  @override
  String get browserApplyAndReload => '应用并刷新';

  @override
  String get browserUaUpdated => 'UA 已更新并刷新页面';

  @override
  String browserUaSetFailed(String error) {
    return '设置 UA 失败: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView 初始化失败，请检查 WebView2 是否已安装';

  @override
  String get browserBiliCookieReadFailed =>
      '未能读取到完整登录 Cookie（SESSDATA 为 HttpOnly，当前平台无法自动读取），请改用扫码登录或粘贴 Cookie';

  @override
  String get browserCookieImportFailed => 'Cookie 导入失败，请重试';

  @override
  String get browserStoppedLoading => '已停止加载';

  @override
  String get browserClipboardAllowed => '已允许网页写入剪贴板';

  @override
  String get browserClipboardBlocked => '已禁止网页自动写入剪贴板';

  @override
  String get browserNoCurrentUrl => '无法获取当前链接';

  @override
  String get browserTroubleshootFailed => '打开失败,请检查\"获取帮助\"是否存在';

  @override
  String get browserSystemBrowserMissing => '系统浏览器不见了(';

  @override
  String get browserQrTitle => '扫我';

  @override
  String get browserSaveToDevice => '保存到设备';

  @override
  String get browserQrSaved => '二维码已保存到相册/图片库';

  @override
  String browserSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get browserStopLoading => '停止加载';

  @override
  String get browserImporting => '导入中…';

  @override
  String get browserLoginDoneImport => '登录完成，导入';

  @override
  String get browserClipboardAccess => '剪贴板访问';

  @override
  String get browserShareQr => '分享二维码';

  @override
  String get browserCopyLink => '复制链接';

  @override
  String get browserViewCookies => '查看 Cookies';

  @override
  String get browserSetUa => '设置 UA';

  @override
  String get browserUaModeAuto => '自动（跟随系统）';

  @override
  String get browserUaModeDesktop => '电脑端';

  @override
  String get browserUaModeMobile => '手机端';

  @override
  String get browserRefresh => '刷新';

  @override
  String get browserSystemBrowser => '系统浏览器';

  @override
  String get browserTroubleshootNetwork => '检测连接问题';

  @override
  String get browserUnsupportedPlatform => '当前平台不支持内嵌浏览器';

  @override
  String get browserOpenedInSystem => '已尝试在系统浏览器中打开';

  @override
  String get browserReopenInSystem => '重新用系统浏览器打开';

  @override
  String get browserAndroidErrorTitle => '沒有指令';

  @override
  String get browserAndroidErrorCause => '原因';

  @override
  String get browserAndroidErrorDetail =>
      'WebView 组件初始化失败\n可能是系统 WebView 未更新或已停用';

  @override
  String get browserUpdateWebview => '前往 Google Play 更新 Android System WebView';

  @override
  String get browserOpenDevOptions => '打开开发者选项查看 WebView 实现';

  @override
  String get browserAppleErrorTitle => '應用程式未預期的結束';

  @override
  String get browserAppleErrorReport => '問題報告';

  @override
  String get browserAppleErrorDetail => '無法在此裝置上初始化內嵌瀏覽器。請確認作業系統已更新至最新版本。';

  @override
  String get browserBsodMessage => '你的 Webview2 遇到问题，我们需要收集一些错误信息，然后为你重启应用。';

  @override
  String get browserBsodNoRestart => '(其实不用重启，安装完组件即可)';

  @override
  String get browserBsodComplete => '100% 完成';

  @override
  String get browserBsodSolutions => '查看解决方案：';

  @override
  String get browserBsodDownload => '下载 Webview2 运行时';

  @override
  String get browserBsodWinUpdate => '打开 Windows 更新设置';

  @override
  String get browserBsodScanQr => '扫描此 QR 码获取解决方案';

  @override
  String get browserBsodStopCode => '终止代码：WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => '无法打开外部链接';

  @override
  String get callOutgoing => '正在呼叫...';

  @override
  String get callIncoming => '来电...';

  @override
  String get callConnecting => '连接中...';

  @override
  String get chatConnectionNotEstablishedImage => '连接未建立，无法发送图片';

  @override
  String get chatImageSent => '✅ 图片已发送';

  @override
  String get chatImageSendFailed => '发送图片失败';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return '处理剪贴板图片失败：$error';
  }

  @override
  String get chatImageStaged => '🖼️ 图片已添加至输入框';

  @override
  String get chatClipboardNoImage => '剪贴板无图片数据';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return '获取剪贴板图片失败：$error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported => '剪贴板为空或格式不支持';

  @override
  String get chatConnectionNotEstablishedFile => '连接未建立，无法发送文件';

  @override
  String get chatFileNotExist => '文件不存在';

  @override
  String get chatFileSendFailed => '发送文件失败';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName 发送成功';
  }

  @override
  String chatFileSendError(String error) {
    return '发送文件失败：$error';
  }

  @override
  String get chatIpUnknown => 'IP 未知';

  @override
  String get chatReconnecting => '正在重新建立连接...';

  @override
  String get chatReconnectFailed => '重连失败，请检查网络或对方是否在线';

  @override
  String get chatStatusUnknown => '状态未知';

  @override
  String get chatStatusWaiting => '等待连接';

  @override
  String get chatMe => '我';

  @override
  String get chatFileInfoLost => '(文件信息丢失)';

  @override
  String chatOpenFileFailed(String message) {
    return '无法打开文件：$message';
  }

  @override
  String get chatFileNotDownloaded => '文件尚未下载';

  @override
  String chatOpenFileError(String error) {
    return '打开文件失败：$error';
  }

  @override
  String get chatFilePathUnavailable => '无法获取文件路径 (安卓权限限制?)';

  @override
  String chatPickFileFailed(String error) {
    return '选择文件失败：$error';
  }

  @override
  String get chatImagePathUnavailable => '无法获取图片路径';

  @override
  String chatPickImageFailed(String error) {
    return '选择图片失败：$error';
  }

  @override
  String get chatCopyText => '复制文本';

  @override
  String get chatSelectText => '选择文本';

  @override
  String get chatOpenFile => '打开文件';

  @override
  String get chatCopyImage => '复制图片';

  @override
  String get chatSaveImage => '保存图片';

  @override
  String get chatCopyingImage => '正在复制图片...';

  @override
  String get chatImageCopied => '✅ 图片已复制到剪贴板';

  @override
  String get chatCopyFailed => '复制失败';

  @override
  String chatCopyImageFailed(String error) {
    return '复制图片失败: $error';
  }

  @override
  String get chatSaving => '正在保存...';

  @override
  String get chatSaveSuccess => '✅ 保存成功';

  @override
  String chatSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get chatMessageContent => '消息内容';

  @override
  String get chatEmptyContent => '(这里空空的)';

  @override
  String get chatDeleteMessageConfirm => '主人确定要删除这条消息吗？';

  @override
  String get chatMessageDeleted => '消息已删除';

  @override
  String get chatOpenLinkTitle => '打开链接';

  @override
  String chatWillOpen(String url) {
    return '将打开：$url';
  }

  @override
  String get chatBrowserTitle => '内置网页浏览器';

  @override
  String get chatCantOpenLink => '无法打开链接';

  @override
  String chatOpenLinkFailed(String error) {
    return '打开链接失败：$error';
  }

  @override
  String get chatPlusImage => '图片';

  @override
  String get chatPlusFile => '文件';

  @override
  String get chatImageReady => '图片已就绪';

  @override
  String get chatMore => '更多';

  @override
  String get chatPasteImage => '粘贴图片';

  @override
  String get chatInputHint => '输入消息...';

  @override
  String get chatEmoji => '表情符号';

  @override
  String get chatSend => '发送';

  @override
  String get chatInvalidAddress => '连接地址无效，无法发送';

  @override
  String get chatImageSendError => '图片发送失败';

  @override
  String chatSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String get chatConnStatusUnknown => '连接状态未知，无法发送消息';

  @override
  String get chatPendingCannotSend => '等待对方验证，无法发送消息';

  @override
  String get chatConnRejected => '连接已被拒绝';

  @override
  String get chatConnDisconnected => '对方已断开连接';

  @override
  String get chatConnNotEstablished => '连接尚未建立，无法发送消息';

  @override
  String get chatNoMessages => '暂无消息，开始聊天吧';

  @override
  String get chatDisconnectedRetry => '连接已断开，点击尝试重连';

  @override
  String get chatRejectedRetry => '连接被拒绝，点击重试';

  @override
  String get chatExpandInput => '展开输入栏';

  @override
  String get discoverMyLanIps => '我的局域网 IP';

  @override
  String get discoverNoIpOfType => '未找到该类型的有效 IP，请检查网络连接。';

  @override
  String discoverIpCopied(String ip) {
    return '已复制 $ip';
  }

  @override
  String get discoverTitle => '发现附近设备';

  @override
  String get discoverMyIp => '我的 IP';

  @override
  String get discoverRefreshBroadcast => '刷新/广播';

  @override
  String get discoverLanDevices => '局域网设备';

  @override
  String get discoverSearching => '正在寻找附近的设备...';

  @override
  String get discoverSendRequest => '点击发送连接请求';

  @override
  String get discoverPendingVerify => '等待对方验证...';

  @override
  String get discoverRejectedRetry => '已被拒绝，点击重试';

  @override
  String get discoverDisconnectedRetry => '已断开，点击重连';

  @override
  String get discoverUnknownDevice => '未知设备';

  @override
  String get discoverAlreadyConnected => '该设备已连接';

  @override
  String get discoverAlreadyPending => '正在等待对方验证，请勿重复发送';

  @override
  String get discoverConnectFailed => '连接失败，请检查网络或对方是否在线';

  @override
  String get discoverManualConnect => '手动连接到对等端';

  @override
  String get discoverConnectIpHint => '输入 IP 地址（例如：192.168.1.100 / fe80::1）';

  @override
  String get displayScaleCompact => '紧凑模式 · 显示更多内容';

  @override
  String get displayScaleSmall => '略小 · 适合大屏';

  @override
  String get displayScaleDefault => '默认';

  @override
  String get displayScaleLarge => '略大 · 更易阅读';

  @override
  String get displayScaleLargeFont => '大字体 · 无障碍友好';

  @override
  String get displayScaleHuge => '超大 · 辅助功能';

  @override
  String get displayScaleMin => '最小 · 信息密度最高';

  @override
  String get displayScaleCompactBig => '紧凑 · 适合大屏';

  @override
  String get displayScaleSystemDefault => '系统默认';

  @override
  String get displayScaleLargeFontShort => '大字体 · 无障碍';

  @override
  String get displayScaleTitle => '显示缩放';

  @override
  String get displayHeroTransitionBlur => '使用新版动画';

  @override
  String get displayIosPushTransition => 'iOS 风格页面切换';

  @override
  String get displayIosPushTransitionCorner => '转场圆角';

  @override
  String get searchIosPushTransition => 'iOS 页面切换动画';

  @override
  String get pageBgTitle => '页面背景图';

  @override
  String get pageBgSubtitle => '设置类页面共用的背景图，选择后可裁剪';

  @override
  String get pageBgEnabled => '显示页面背景图';

  @override
  String get pageBgOpacity => '背景强度';

  @override
  String get pageBgBlur => '背景模糊';

  @override
  String get pageBgNotSet => '未设置';

  @override
  String get pageBgPick => '选择并裁剪图片';

  @override
  String get pageBgClear => '清除背景图';

  @override
  String get pageBgSaved => '背景图已更新';

  @override
  String get pageBgCleared => '背景图已清除';

  @override
  String get pageBgPickFailed => '选择图片失败';

  @override
  String get cropTitle => '裁剪背景图';

  @override
  String get cropAspectFree => '自由';

  @override
  String get cropApply => '应用';

  @override
  String get cropReset => '重置';

  @override
  String get displayAdvancedGlass => '高级渲染';

  @override
  String get displayDisableLiquidGlassMenus => '减弱效果';

  @override
  String get displayLiquidGlassTuner => '液态玻璃调校';

  @override
  String get displayLiquidGlassTunerSubtitle => '调节玻璃厚度、模糊、着色、折射率等材质参数';

  @override
  String get lgTunerPreview => '实时预览';

  @override
  String get lgTunerSectionMaterial => '材质参数';

  @override
  String get lgTunerThickness => '玻璃厚度';

  @override
  String get lgTunerBlur => '背景模糊';

  @override
  String get lgTunerTint => '着色强度';

  @override
  String get lgTunerSaturation => '饱和度';

  @override
  String get lgTunerRefractiveIndex => '折射率';

  @override
  String get lgTunerLightIntensity => '高光强度';

  @override
  String get lgTunerAmbient => '环境光';

  @override
  String get lgTunerLightAngle => '光源角度';

  @override
  String get lgTunerAberration => '色散';

  @override
  String get lgTunerReset => '恢复默认';

  @override
  String get lgTunerNote =>
      '调整即时生效并全局应用：未单独指定参数的玻璃表面（下拉菜单、弹窗等）都会跟随；聊天页顶栏等显式设定的表面保持独立样式。';

  @override
  String get lgTunerFallbackNote =>
      '当前平台不支持高级玻璃渲染（Impeller），预览为 FakeGlass 效果；厚度、折射率、饱和度等参数仅移动端生效。';

  @override
  String get displayScaleReset => '重置为 100%';

  @override
  String get displayScaleFineTune => '精细调节';

  @override
  String get displayScalePresets => '快捷预设';

  @override
  String get displayScaleNote =>
      '缩放比例会全局应用于文字与部分布局尺寸。设为 100% 可恢复默认。修改即时生效，无需重启。';

  @override
  String displayScaleConnCount(int count) {
    return '$count 个连接';
  }

  @override
  String get displayThemeLight => '浅色';

  @override
  String get displayThemeDark => '深色';

  @override
  String get displaySettingsTitle => '显示';

  @override
  String get displaySectionAppearance => '外观';

  @override
  String get displayThemeMode => '主题模式';

  @override
  String get displayPureBlack => '纯黑深色模式';

  @override
  String get displayPureBlackOn => '深色模式（已黑化）';

  @override
  String get displayOff => '已关闭';

  @override
  String get displaySectionPersonalize => '个性化';

  @override
  String get displayThemeColor => '主题配色';

  @override
  String get displayFollowSystemColor => '跟随系统配色';

  @override
  String get displayFontWeight => '文字粗细';

  @override
  String get displaySeedDefaultGreen => '默认绿';

  @override
  String get displaySeedPink => '粉红色';

  @override
  String get displaySeedRed => '红色';

  @override
  String get displaySeedOrange => '橙色';

  @override
  String get displaySeedAmber => '琥珀色';

  @override
  String get displaySeedYellow => '黄色';

  @override
  String get displaySeedLime => '酸橙色';

  @override
  String get displaySeedLightGreen => '浅绿色';

  @override
  String get displaySeedGreen => '绿色';

  @override
  String get displaySeedCyan => '青色';

  @override
  String get displaySeedTeal => '蓝绿色';

  @override
  String get displaySeedLightBlue => '浅蓝色';

  @override
  String get displaySeedBlue => '蓝色';

  @override
  String get displaySeedIndigo => '靛蓝色';

  @override
  String get displaySeedPurple => '紫色';

  @override
  String get displaySeedDeepPurple => '深紫色';

  @override
  String get displaySeedBlueGrey => '蓝灰色';

  @override
  String get displaySeedBrown => '棕色';

  @override
  String get displaySeedGrey => '灰色';

  @override
  String get displaySeedCustom => '自定义';

  @override
  String displayWeightThin(int weight) {
    return '极细 ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return '细 ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return '常规 ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return '中等 ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return '粗 ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return '极粗 ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return '自定义 ($weight)';
  }

  @override
  String get fontWeightThin => '极细';

  @override
  String get fontWeightLight => '细';

  @override
  String get fontWeightRegular => '常规';

  @override
  String get fontWeightMedium => '中等';

  @override
  String get fontWeightBold => '粗';

  @override
  String get fontWeightBlack => '极粗';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\n敏捷的棕色狐狸跳过懒惰的狗。';

  @override
  String get fontWeightSaveApply => '保存并应用';

  @override
  String get geetestTitle => '完成滑块验证';

  @override
  String get geetestInitFailed => '验证码组件初始化失败，请重试或改用其他登录方式';

  @override
  String get geetestUnsupported => '当前平台不支持内嵌验证码，请使用扫码或 Cookie 登录';

  @override
  String get slicerPickImageFirst => '请先选择图片';

  @override
  String get slicerRowColInvalid => '行列数必须大于0';

  @override
  String get slicerSuccess => '切割成功，已添加到开始屏幕';

  @override
  String slicerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get slicerTitle => '图片切割磁贴';

  @override
  String get slicerTileSize => '磁贴尺寸 (所有碎片均相同)';

  @override
  String get slicerColsLabel => '列数 (Cols)';

  @override
  String get slicerRowsLabel => '行数 (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return '预览：将切割为 $count 个 $type 磁贴';
  }

  @override
  String get slicerProcessing => '处理中...';

  @override
  String get slicerSaveToStart => '保存到开始屏幕';

  @override
  String get viewerSaving => '正在保存...';

  @override
  String get viewerSaveSuccess => '保存成功';

  @override
  String viewerSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get viewerShareImage => '分享图片';

  @override
  String viewerShareFailed(String error) {
    return '分享失败: $error';
  }

  @override
  String get viewerCopying => '正在复制...';

  @override
  String viewerCopyFailed(String error) {
    return '复制失败: $error';
  }

  @override
  String get viewerSaveToAlbum => '保存到相册';

  @override
  String get viewerCopyToClipboard => '复制到剪贴板';

  @override
  String get viewerImageLoadFailed => '图片加载失败';

  @override
  String get viewerImageDataNotFound => '未找到图片数据';

  @override
  String get userSpaceMidInvalid => 'mid 无效';

  @override
  String get userSpaceNoCard => '响应缺少 card';

  @override
  String get userSpaceNoList => '响应缺少 list';

  @override
  String get searchTypeVideo => '视频';

  @override
  String get searchTypeBangumi => '番剧';

  @override
  String get searchTypeFt => '影视';

  @override
  String get searchTypeLive => '直播间';

  @override
  String get searchTypeUser => '用户';

  @override
  String get searchTypeArticle => '专栏';

  @override
  String get tenThousandUnit => '万';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play播放 · $danmaku弹幕';
  }

  @override
  String searchScore(String score) {
    return '评分 $score';
  }

  @override
  String searchOnline(String count) {
    return '$count人在线';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans粉丝 · $videos视频';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views阅读 · $replies评论';
  }

  @override
  String get searchBadgeCourse => '课堂';

  @override
  String get searchBadgeLive => '直播';

  @override
  String get searchBadgeCoop => '合作';

  @override
  String get searchBadgeLiveNow => '直播中';

  @override
  String get searchKeywordEmpty => '关键词为空';

  @override
  String get searchBadResponse => '响应格式异常';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get searchGaiaParamMissing => 'gaia register 参数缺失';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register 异常: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate 未通过 (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate 异常: $error';
  }

  @override
  String get commentOidEmpty => 'oid 为空';

  @override
  String commentException(String error) {
    return '异常: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return '楼中楼 HTTP $code';
  }

  @override
  String get commentSubNoData => '楼中楼响应缺少 data';

  @override
  String commentSubException(String error) {
    return '楼中楼异常: $error';
  }

  @override
  String get commentNotLoggedIn => '未登录或未开启「携带 Cookie 请求」';

  @override
  String get commentMissingJct => 'Cookie 缺少 bili_jct，请重新登录';

  @override
  String commentNetworkError(String error) {
    return '网络异常: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message（code=$code）';
  }

  @override
  String get deviceOs => '操作系统';

  @override
  String get deviceBuild => '内部构建';

  @override
  String get deviceSecurityPatch => '安全补丁';

  @override
  String get deviceOem => 'OEM 厂商';

  @override
  String get deviceBrand => '品牌';

  @override
  String get deviceModel => '型号';

  @override
  String get deviceRomVersion => 'ROM/显示版本';

  @override
  String get deviceFingerprint => '设备指纹';

  @override
  String get deviceName => '设备名称';

  @override
  String get deviceComputerName => '计算机名';

  @override
  String get deviceHardwareModel => '硬件型号';

  @override
  String get deviceKernel => '内核版本';

  @override
  String get deviceDistro => '发行版';

  @override
  String get deviceVersion => '版本';

  @override
  String get devicePlatform => '平台';

  @override
  String deviceInfoFailed(String error) {
    return '获取信息失败: $error';
  }

  @override
  String get logWebUnsupported => '（Web 不支持文件日志）';

  @override
  String get logNotInitialized => '（未初始化）';

  @override
  String logAppDataDir(String path) {
    return '应用数据目录\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData（Roaming）\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return '本地数据目录\n$path';
  }

  @override
  String get nowPlayingVideo => '正在播放视频';

  @override
  String get commonUnknown => '未知';

  @override
  String get unnamedPlaylist => '未命名播放列表';

  @override
  String get unknownVideo => '未知视频';

  @override
  String dohQueryFailed(int code) {
    return 'DoH 查询失败: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP 连接成功';

  @override
  String get netModeCompat => 'Host 映射 IP 直连, 绕过 SNI 干扰';

  @override
  String get netModeStandard => '系统默认网络栈';

  @override
  String netHostResolveFailed(String host) {
    return '无法解析主机 $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie 为空';

  @override
  String get biliCookieIncomplete =>
      'Cookie 不完整，请从浏览器复制全部 Cookie（需包含 SESSDATA）';

  @override
  String get biliCookieMissingJct =>
      'Cookie 缺少 bili_jct，请重新从浏览器复制完整 Cookie（点赞/发评论等操作依赖它）';

  @override
  String get biliCookieInvalid => 'Cookie 无效或已过期，请重新从浏览器复制';

  @override
  String get biliLoginSuccess => '登录成功';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked => '请求被风控拦截(-412)，请稍后重试';

  @override
  String get biliQrExpired => '二维码已失效';

  @override
  String get biliQrScanned => '已扫码，请在手机上确认';

  @override
  String get biliQrWaiting => '等待扫码';

  @override
  String get biliRequestFailed => '请求失败';

  @override
  String get biliResponseNoData => '响应缺少 data';

  @override
  String get biliQrNoSessionCookie => '未获取到会话 Cookie，请刷新二维码重试';

  @override
  String get biliQrMissingJct =>
      '扫码登录未获取到完整会话（缺少 bili_jct），请改用「粘贴 Cookie」或「浏览器登录」方式';

  @override
  String get biliNoSessionCookie => '未获取到会话 Cookie';

  @override
  String get biliWebKeyFailed => '获取登录公钥失败，请检查网络';

  @override
  String get biliPwdEncryptFailed => '密码加密失败';

  @override
  String get biliNeedGeetest => '需要完成滑块验证';

  @override
  String get biliUnknownError => '未知错误';

  @override
  String get csPlaylists => '播放列表';

  @override
  String get csDanmaku => '弹幕';

  @override
  String get csCloudEncrypted => '云端数据已加密，请先在 WebDAV 设置中填写同步密码';

  @override
  String get csCloudPassMismatch => '云端数据已加密且同步密码不匹配，无法同步';

  @override
  String get csCloudNoFile => '云端没有播放列表文件，无法恢复';

  @override
  String get csRestoredFromCloud => '已从云端恢复';

  @override
  String get csSyncDone => '同步完成';

  @override
  String csUploadBgCount(int count) {
    return '上传背景图 $count 张';
  }

  @override
  String csDownloadBgCount(int count) {
    return '下载背景图 $count 张';
  }

  @override
  String csUploadedFileCount(int count) {
    return '上传 $count 个文件';
  }

  @override
  String csDownloadedFileCount(int count) {
    return '下载 $count 个文件';
  }

  @override
  String csMergedListsCount(int count) {
    return '合并 $count 个列表';
  }

  @override
  String get csEncrypted => '已加密';

  @override
  String csSyncFailed(String error) {
    return '同步失败: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return '已上传 $count 个播放列表到云端';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return '上传 $uploaded 个，下载 $downloaded 个';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return '，失败 $failed 个（$details）';
  }

  @override
  String get unknownUser => '未知用户';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => '发送文件';

  @override
  String receivingFile(String fileName) {
    return '接收: $fileName';
  }

  @override
  String get notificationChannelName => '聊天消息';

  @override
  String get notificationChannelDesc => '接收聊天消息和快捷回复';

  @override
  String get notificationReply => '回复';

  @override
  String get screenshotSavedTitle => '截图已保存';

  @override
  String get screenshotSavedToAlbum => '截图已保存到相册';

  @override
  String get notificationConfirm => '确认';

  @override
  String get callInProgressError => '当前有未结束的通话，请先挂断';

  @override
  String get callTcpFailed => '无法连接对方（TCP 建立失败），请确认对方在线';

  @override
  String get callConnectionDropped => '连接建立后立即断开，请检查网络或对方状态';

  @override
  String callInitFailed(String error) {
    return '发起通话失败：$error';
  }

  @override
  String callAcceptFailed(String error) {
    return '接听通话失败：$error';
  }

  @override
  String get callRecordVoice => '语音通话';

  @override
  String get callRecordMissedOutgoing => '未接通话';

  @override
  String get callRecordRejected => '已拒绝来电';

  @override
  String get callRecordMissedIncoming => '未接来电';

  @override
  String get callPeerNoAnswer => '对方未接听';

  @override
  String get callUnknown => '未知';

  @override
  String get callInProgress => '通话中';

  @override
  String get webdavHttpWarning => '警告：使用 HTTP 连接，凭证将以明文传输。建议使用 HTTPS。';

  @override
  String get webdavConfigRequired => '请先填写服务器地址和用户名';

  @override
  String get webdavAuthFailed => '认证失败：用户名或密码错误';

  @override
  String webdavConnectFailed(int code) {
    return '连接失败：HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return '网络错误：无法连接到服务器 ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return '未知错误：$error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV 未配置';

  @override
  String webdavLocalFileMissing(String path) {
    return '本地文件不存在: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return '上传失败：HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return '上传异常：$error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return '下载失败: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return '下载异常: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String webdavListFailed(String error) {
    return '列出文件失败: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND 失败: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return '网络错误：$msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return '准备备份 $count 个文件...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return '正在备份 ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return '备份完成：$success 成功，$fail 失败';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonConnect => '连接';

  @override
  String get commonSave => '保存';

  @override
  String get commonCreate => '创建';

  @override
  String get commonDelete => '删除';

  @override
  String get drawerHome => '主页';

  @override
  String get drawerVerificationRequests => '验证请求';

  @override
  String get drawerSettings => '设置';

  @override
  String get drawerAbout => '关于';

  @override
  String get drawerCloseMenu => '关闭菜单';

  @override
  String get drawerLockNow => '立即锁定';

  @override
  String get drawerNoNickname => '未设置昵称';

  @override
  String get drawerSwitchToDark => '切换到深色模式';

  @override
  String get drawerSwitchToLight => '切换到浅色模式';

  @override
  String get drawerLightMode => '浅色模式';

  @override
  String get drawerDarkMode => '深色模式';

  @override
  String get drawerSystemMode => '跟随系统';

  @override
  String drawerThemeSwitched(String mode) {
    return '已切换到 $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return '获取失败: $error';
  }

  @override
  String get drawerNoDeviceInfo => '暂无设备信息';

  @override
  String get drawerBackgroundTitle => '侧边栏背景';

  @override
  String get drawerBackgroundHasCustom => '当前已设置自定义背景，您可以更换或移除。';

  @override
  String get drawerBackgroundNoCustom => '为侧边栏设置一张个性化背景图片。';

  @override
  String get drawerBackgroundUpdated => '侧边栏背景已更新';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '设置失败: $error';
  }

  @override
  String get drawerBackgroundChange => '更换背景';

  @override
  String get drawerBackgroundSelect => '选择背景图片';

  @override
  String get drawerBackgroundRestored => '已恢复默认背景';

  @override
  String get drawerBackgroundRemove => '移除背景';

  @override
  String get homeOpenMenu => '打开菜单';

  @override
  String get homeAddConnection => '添加连接';

  @override
  String get homeMessages => '消息';

  @override
  String get homeNoConnections => '暂无连接';

  @override
  String get homePullToRefreshHint => '下拉刷新或点击右上角添加';

  @override
  String get homeLoadFailed => '聊天记录加载失败，请重试';

  @override
  String get homeRetryLoad => '重新加载';

  @override
  String get homeUnknownAddress => '未知地址';

  @override
  String get homeNoMessages => '暂无消息';

  @override
  String homeFileMessage(String fileName) {
    return '[文件] $fileName';
  }

  @override
  String get homeFileFallbackName => '文件';

  @override
  String get homeMessagePlaceholder => '[消息]';

  @override
  String get connectionLost => '连接已失效';

  @override
  String get openVideoFailed => '无法打开该视频';

  @override
  String get connectDialogTitle => '连接到对等端';

  @override
  String get connectIpHint => '输入 IP 地址 (例如：192.168.1.100 或 fe80::1)';

  @override
  String get connectIpEmpty => '请输入 IP 地址';

  @override
  String get connectIpInvalid => 'IP 地址格式不正确';

  @override
  String get connectIpNotLan => '仅允许内网 IP 地址';

  @override
  String get connectRequestSent => '已发送连接请求，等待对方验证';

  @override
  String get connectFailed => '连接失败，请检查 IP 地址是否正确或对方是否在线';

  @override
  String get homeScanQr => '扫一扫';

  @override
  String get homeMyQrCode => '我的二维码';

  @override
  String get homeManualAdd => '手动添加';

  @override
  String get scannedFriends => '扫码添加的好友';

  @override
  String get scanTitle => '扫一扫';

  @override
  String get scanTitleWebdav => '扫描 WebDAV 地址';

  @override
  String get scanHint => '将二维码 / 条码对准框内';

  @override
  String get scanHintWebdav => '将 WebDAV 服务器地址二维码对准框内';

  @override
  String get scanHintAddFriend => '将好友的设备二维码对准框内';

  @override
  String get scanPreparing => '正在准备摄像头...';

  @override
  String get scanPermissionNeeded => '需要摄像头权限';

  @override
  String get scanPermissionNeededMsg => '请在权限弹窗中允许使用摄像头，才能扫码。';

  @override
  String get scanPermissionDenied => '摄像头权限被拒绝';

  @override
  String get scanPermissionDeniedMsg => '权限已被永久拒绝，请前往系统设置手动开启。';

  @override
  String get scanCameraUnavailable => '摄像头不可用';

  @override
  String get scanRetry => '重试';

  @override
  String get scanOpenSettings => '前往系统设置';

  @override
  String get scanTorch => '闪光灯';

  @override
  String get scanDetectedLink => '检测到链接';

  @override
  String get scanOpenLinkPrompt => '是否在内置浏览器中打开以下链接？';

  @override
  String get scanCopy => '复制';

  @override
  String get scanOpen => '打开';

  @override
  String get scanLinkCopied => '链接已复制';

  @override
  String get scanDetectedBiliVideo => '检测到 B 站视频链接';

  @override
  String get scanBiliVideoPrompt => '是否用内置播放器打开该视频？';

  @override
  String scanBiliVideoAt(String time) {
    return '空降至 $time';
  }

  @override
  String get scanOpenVideo => '打开视频';

  @override
  String get scanDetectedWebdav => '检测到 WebDAV 地址';

  @override
  String get scanWebdavPrompt => '该链接看起来是 WebDAV 服务器地址，是否自动填入配置？';

  @override
  String get scanOpenInBrowser => '浏览器打开';

  @override
  String get scanFillConfig => '填入配置';

  @override
  String get scanDetectedText => '识别到文本';

  @override
  String get scanCopiedToClipboard => '已复制到剪贴板';

  @override
  String get scanClose => '关闭';

  @override
  String get scanResultTitle => '扫码结果';

  @override
  String get scanErrorPermission => '摄像头权限被拒绝';

  @override
  String get scanErrorUnsupported => '当前设备不支持扫码';

  @override
  String get scanErrorDisposed => '扫码器已释放，请重试';

  @override
  String scanErrorGeneric(String code) {
    return '摄像头不可用（$code）';
  }

  @override
  String scanInitFailed(String error) {
    return '扫码器初始化失败：$error';
  }

  @override
  String get scanDetectedDevice => '检测到设备二维码';

  @override
  String get scanAddFriendPrompt => '是否添加该设备为好友？';

  @override
  String get scanAddFriend => '添加好友';

  @override
  String get scanFriendAdded => '已发送好友请求，等待对方验证';

  @override
  String get scanFriendAddFailed => '添加好友失败，请检查网络或对方是否在线';

  @override
  String get myQrTitle => '我的二维码';

  @override
  String get myQrHint => '让好友扫描此二维码添加您';

  @override
  String get myQrEmbedIp => '二维码中已嵌入第一个局域网 IP';

  @override
  String get myQrLocalIps => '当前局域网 IP';

  @override
  String get myQrCopyContent => '复制二维码内容';

  @override
  String get myQrCopied => '已复制到剪贴板';

  @override
  String get myQrNoIp => '未找到有效的局域网 IP，请检查网络连接。';

  @override
  String get displayModeSectionTitle => '屏幕';

  @override
  String get displayModeTitle => '屏幕帧率';

  @override
  String get displayModeAuto => '自动';

  @override
  String get displayModeSystemTag => '[系统]';

  @override
  String get displayModeHint => '没有生效？重启应用试试';

  @override
  String get displayModeUnsupported => '当前平台不支持设置屏幕帧率（仅 Android）';

  @override
  String get displayModeAndroidOnly => '仅 Android';

  @override
  String get displayModeLoading => '正在获取屏幕帧率...';

  @override
  String get displayModeEmpty => '未获取到可用的屏幕帧率';

  @override
  String get playerSectionEnhance => '画面增强';

  @override
  String get superResolutionTitle => '超分辨率';

  @override
  String get superResolutionOff => '关闭';

  @override
  String get superResolutionEfficiency => '效率（低开销）';

  @override
  String get superResolutionQuality => '画质（最佳效果）';

  @override
  String get superResolutionHint => '通过 mpv 着色器实时增强画面，建议配合硬件解码；对动画内容效果最佳';

  @override
  String get skipIntroOutroTitle => '跳过片头/片尾';

  @override
  String get skipIntroOutroHint => '通过社区共享数据识别片头片尾，仅在视频有 BV+CID 时提示';

  @override
  String get skipIntro => '跳过片头';

  @override
  String get skipOutro => '跳过片尾';

  @override
  String playlistDetailEpisodes(int count) {
    return '共 $count 集';
  }

  @override
  String get playlistDetailEmpty => '该播放列表为空，请先编辑添加视频';

  @override
  String playlistDetailEpisodeOf(int index) {
    return '第 $index 集';
  }

  @override
  String playlistDetailResume(String position) {
    return '看到这集 · $position';
  }

  @override
  String get playlistDetailBgTitle => '背景图';

  @override
  String get playlistDetailBgPick => '选择背景图片';

  @override
  String get playlistDetailBgChange => '更换背景';

  @override
  String get playlistDetailBgRemove => '移除背景';

  @override
  String get playlistDetailBgUpdated => '✅ 背景图已更新';

  @override
  String get playlistDetailBgRemoved => '已恢复默认背景';

  @override
  String playlistDetailBgFail(String error) {
    return '设置失败：$error';
  }

  @override
  String get playlistFabRestart => '从头开始';

  @override
  String get playlistMenuMore => '更多操作';

  @override
  String get playlistMenuRename => '编辑名字';

  @override
  String get playlistMenuMultiSelect => '多选';

  @override
  String get playlistMenuDanmaku => '弹幕';

  @override
  String get playlistRenameTitle => '重命名播放列表';

  @override
  String get playlistRenameHint => '输入新的列表名称';

  @override
  String get playlistRenameSaved => '已重命名';

  @override
  String get playlistSelectDone => '完成';

  @override
  String get playlistSelectEmpty => '请先选择剧集';

  @override
  String playlistSelectDelete(int count) {
    return '删除选中（$count）';
  }

  @override
  String playlistSelectDeleted(int count) {
    return '已删除 $count 集';
  }

  @override
  String get playlistDanmakuTitle => '导入番剧弹幕';

  @override
  String get playlistDanmakuSsHint => '输入番剧 SS 号（season_id）';

  @override
  String get playlistDanmakuFetchFail => '获取剧集失败，请检查 SS 号';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return '选择剧集（共 $count 集）';
  }

  @override
  String get playlistDanmakuSelectAll => '全选';

  @override
  String get playlistDanmakuImport => '导入并附加弹幕';

  @override
  String playlistDanmakuAttached(int count) {
    return '已为 $count 集附加弹幕';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '所选 $selected 集超过列表 $total 集，超出部分已忽略';
  }

  @override
  String get splitSelectChat => '选择一个聊天';

  @override
  String get statusPending => '待对方验证';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusRejected => '已拒绝';

  @override
  String get statusDisconnected => '已断开';

  @override
  String get homeStart => '开始';

  @override
  String get homeDone => '完成';

  @override
  String get homeBack => '返回';

  @override
  String get homeOverview => '鸟瞰视图';

  @override
  String get homeLocalUser => '本地用户';

  @override
  String get homeDefaultGroup => '默认分组';

  @override
  String get homeNewGroup => '新分组';

  @override
  String get homeUnnamedGroup => '(未命名分组)';

  @override
  String get homeDeleteGroupTitle => '确认删除';

  @override
  String get homeDeleteGroupMessage => '删除该组将同时删除组内的所有磁贴，是否继续？';

  @override
  String get homeNewGroupTitle => '新建分组';

  @override
  String get homeGroupNameHint => '输入分组名称';

  @override
  String get homeRenameGroupTitle => '为该组命名';

  @override
  String get homeNewGroupNameHint => '输入新组名';

  @override
  String get homeImageSlice => '图片碎片';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (小)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (宽)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (大)';
  }

  @override
  String get homeGroupOne => '分组1';

  @override
  String get homeGroupTwo => '分组2';

  @override
  String get homeGroupProductivity => '生产力工具';

  @override
  String get homeGroupLegacy => '旧版';

  @override
  String get tileImageSlicer => '图片切割';

  @override
  String get tileSystemSettings => '系统设置';

  @override
  String get tileDatabase => '数据库';

  @override
  String get tileLcdDisplay => 'LCD 显示屏';

  @override
  String get tileLedDynamic => 'LED 动态';

  @override
  String get tileLedStatic => 'LED 静态';

  @override
  String get tilePisScreen => 'PIS 屏幕';

  @override
  String get tileRoutePreview => '路线预览';

  @override
  String get tileStationEntranceDesign => '出入口设计';

  @override
  String get tileStationEntrancePillar => '出入口立柱';

  @override
  String get tileStationEntranceSideName => '出入口侧名';

  @override
  String get tilePlatformSideName => '侧方站名';

  @override
  String get tileScreenDoorCover => '屏蔽门盖板';

  @override
  String get tileStationNameSign => '站名牌';

  @override
  String get tileGeneralSign => '通用标识';

  @override
  String get tileLineSymbol => '线路符号';

  @override
  String get tileBusLcd => '巴士 LCD';

  @override
  String get tileJsonEditor => 'JSON 编辑器';

  @override
  String get tileNamingRule => '命名规范';

  @override
  String get tilePlatformText => '站台文本';

  @override
  String get tileDepartureText => '出发文本';

  @override
  String get tileArrivalText => '到站文本';

  @override
  String get tileOperationDirectionLegacy => '运营方向(旧)';

  @override
  String get tileLegacyLcdWarning => '旧版LCD(警告)';

  @override
  String get tileLinearRoute => '线性路线';

  @override
  String get tileRoadSign => '路牌';

  @override
  String get commentPanelTitle => '评论区';

  @override
  String commentTotalCount(int count) {
    return '共 $count 条';
  }

  @override
  String get commentSortHeat => '按热度';

  @override
  String get commentSortTime => '按时间';

  @override
  String get commentLoading => '正在加载评论...';

  @override
  String get commentLoadFail => '评论加载失败，请检查网络';

  @override
  String get commentLoadMoreFail => '加载更多评论失败';

  @override
  String get commentNoMore => '没有更多评论了';

  @override
  String get commentLoadingMore => '加载中...';

  @override
  String get commentEmpty => '还没有评论';

  @override
  String get commentPinned => '置顶';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get commentExpand => '展开';

  @override
  String get commentCollapse => '收起';

  @override
  String get commentTranslateNeedEnable => '请先在语言设置中开启 AI 翻译';

  @override
  String get commentTranslateNone => '没有可用翻译';

  @override
  String commentSubCount(int count) {
    return '共 $count 条回复';
  }

  @override
  String commentSubLoadMore(String hint) {
    return '加载更多回复（$hint）';
  }

  @override
  String get commentYesterday => '昨天';

  @override
  String get articleLoadFailed => '文章加载失败';

  @override
  String get articleNoContent => '文章正文为空或暂不支持渲染';

  @override
  String get articleOpenBrowser => '浏览器打开';

  @override
  String get articleShare => '分享';

  @override
  String get articleAuthorUnknown => '未知作者';

  @override
  String get browserLinkPageTitle => '网页链接';

  @override
  String articleViews(String count) {
    return '$count 阅读';
  }

  @override
  String get contactPickerTitle => '发送给联系人';

  @override
  String get contactPickerContentLabel => '发送内容';

  @override
  String get contactPickerContentHint => '输入要发送的内容';

  @override
  String get contactPickerContentEmpty => '内容不能为空';

  @override
  String get contactPickerSearchHint => '搜索联系人';

  @override
  String get contactPickerEmpty => '暂无联系人';

  @override
  String get contactPickerNoMatch => '未找到匹配的联系人';

  @override
  String get contactPickerSelectAll => '全选';

  @override
  String contactPickerSendToCount(int count) {
    return '发送给 $count 个联系人';
  }

  @override
  String contactPickerSent(int count) {
    return '已发送给 $count 个联系人';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '「$name」未连接，无法发送';
  }

  @override
  String contactPickerSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String get contactPickerOnline => '在线';

  @override
  String get contactPickerOffline => '离线';

  @override
  String get articleShareToContact => '私信分享';

  @override
  String get playerDanmakuList => '弹幕列表';

  @override
  String playerDanmakuListCount(int count) {
    return '弹幕列表 · 共 $count 条';
  }

  @override
  String get playerDanmakuListEmpty => '暂无弹幕';

  @override
  String get playerDanmakuListNoMatch => '无匹配的弹幕';

  @override
  String get playerDanmakuListSearchHint => '搜索弹幕内容';

  @override
  String get playerDanmakuListJumpCurrent => '定位到当前播放';

  @override
  String get playerViewNotes => '查看笔记';

  @override
  String get playerNotesTitle => '笔记';

  @override
  String playerNotesCount(int count) {
    return '笔记（$count）';
  }

  @override
  String get playerNotesEmpty => '该视频暂无公开笔记';

  @override
  String get playerNotesNoMore => '没有更多了';

  @override
  String get playerNotesLoadFailed => '笔记加载失败';

  @override
  String get playerNotesViewFull => '查看全部';

  @override
  String get playerWriteNote => '写笔记';

  @override
  String get noteEditorWrite => '写笔记';

  @override
  String get noteEditorTitle => '写笔记';

  @override
  String get noteEditorTitleHint => '标题（选填）';

  @override
  String get noteEditorContentHint => '开始记笔记…';

  @override
  String get noteEditorEmoji => '表情';

  @override
  String get noteEditorPublish => '发布';

  @override
  String get noteEditorEmptyContent => '笔记内容不能为空';

  @override
  String get noteEditorContentTooShort => '内容至少 10 个字符才能发布';

  @override
  String get noteEditorNotLoggedIn => '未登录：笔记已保存为本地草稿，登录后可发布';

  @override
  String get noteEditorPublished => '笔记已发布';

  @override
  String get noteEditorPublishNetworkError => '发布失败（网络异常），草稿已保存';

  @override
  String get noteEditorPublishRejected => '发布被服务端拒绝，草稿已保留';

  @override
  String get noteEditorDraftSaved => '已自动保存草稿';

  @override
  String get noteEditorLoggedInHint => '已登录，可发布公开笔记';

  @override
  String get noteEditorGuestHint => '未登录：仅保存本地草稿，不能发布';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return '草稿已保存 $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count 字';
  }

  @override
  String get noteEditorMyDraft => '我的草稿';

  @override
  String get noteEditorDeleteDraft => '删除草稿';

  @override
  String get playerMoreTooltip => '更多操作';

  @override
  String get commentComposerBarHint => '说点什么…';

  @override
  String get commentComposerHint => '输入评论内容…';

  @override
  String commentComposerReplyHint(String name) {
    return '回复 @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return '回复 @$name';
  }

  @override
  String get commentComposerEmote => '表情';

  @override
  String get commentComposerSend => '发送';

  @override
  String get commentComposerEmpty => '评论内容不能为空';

  @override
  String get commentComposerEmoteUnavailable => '表情面板不可用（可能未登录）';

  @override
  String get commentComposerPickImage => '选择图片';

  @override
  String get commentComposerMore => '更多';

  @override
  String get commentComposerVideoProgress => '视频进度';

  @override
  String get commentComposerVideoScreenshot => '视频截图';

  @override
  String commentComposerImageLimit(int count) {
    return '最多选择 $count 张图片';
  }

  @override
  String get commentComposerCaptureFailed => '截图失败，请先开始播放';

  @override
  String get commentComposerUploadFailed => '图片上传失败，请重试';

  @override
  String get commentComposerFabLabel => '发评论';

  @override
  String get commentComposerFabReply => '发回复';

  @override
  String get danmakuSendTitle => '发弹幕';

  @override
  String get danmakuSendModeLabel => '模式';

  @override
  String get danmakuSendFontSizeLabel => '字号';

  @override
  String get danmakuSendColorLabel => '颜色';

  @override
  String get danmakuFontSizeSmall => '小';

  @override
  String get danmakuFontSizeStandard => '标准';

  @override
  String get danmakuFontSizeLarge => '大';

  @override
  String get danmakuSendCustomColor => '自定义颜色';

  @override
  String get danmakuSendColorOk => '确定';

  @override
  String get danmakuSendPreviewPlaceholder => '发个友善的弹幕见证当下';

  @override
  String get drawerHistory => '历史记录';

  @override
  String get drawerWatchLater => '稍后再看';

  @override
  String get drawerMyCache => '我的缓存';

  @override
  String get historyCenterTitle => '历史记录';

  @override
  String get historyTabWatch => '观看历史';

  @override
  String get historyTabPlay => '播放进度';

  @override
  String get historySearchHint => '搜索历史...';

  @override
  String get historyPauseHistory => '暂停记录历史';

  @override
  String get historyResumeHistory => '恢复记录历史';

  @override
  String get historyPausedTip => '历史记录已暂停';

  @override
  String get historyPausedTipAction => '点击恢复';

  @override
  String get historyClearWatchHistory => '清空观看历史';

  @override
  String get historyClearPlayHistory => '清空播放记录';

  @override
  String get historyClearAllTitle => '清空历史';

  @override
  String historyClearAllConfirm(String label) {
    return '确定要清空全部$label吗？此操作不可恢复。';
  }

  @override
  String get historyNoWatchHistory => '暂无观看历史';

  @override
  String get historyNoPlayHistory => '暂无播放记录';

  @override
  String get historyDeleteSelected => '删除选中';

  @override
  String historySelectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get historySearchNoResult => '无匹配结果';

  @override
  String get historyPauseOnSnack => '已暂停历史记录';

  @override
  String get historyResumeOnSnack => '已恢复历史记录';

  @override
  String historyDeleteToast(int count) {
    return '已删除 $count 条记录';
  }

  @override
  String get myCacheTitle => '我的缓存';

  @override
  String get myCacheSearchHint => '搜索缓存视频...';

  @override
  String get myCacheDownloading => '正在缓存';

  @override
  String get myCacheCached => '已缓存';

  @override
  String get myCacheNoCache => '暂无缓存视频';

  @override
  String myCacheGroupCount(int count) {
    return '$count个视频';
  }

  @override
  String get myCacheDeleteGroup => '删除整组';

  @override
  String get myCacheUpdateDanmaku => '更新弹幕';

  @override
  String get myCacheClearAllTitle => '清空全部缓存';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return '将删除全部已缓存视频（$count个视频 · $size），确定吗？';
  }

  @override
  String get cacheActionDownload => '缓存';

  @override
  String get cacheActionCached => '已缓存';

  @override
  String get cacheActionCaching => '缓存中';

  @override
  String get cacheToastSuccess => '已加入缓存队列';

  @override
  String get cacheToastCached => '该视频已缓存';

  @override
  String cacheToastFailed(String error) {
    return '缓存失败：$error';
  }

  @override
  String get drawerRecommend => '推荐';

  @override
  String get recommendSourceWeb => 'Web端';

  @override
  String get recommendSourceApp => 'APP端';

  @override
  String get recommendEmpty => '暂无推荐内容';

  @override
  String get recommendSwitchList => '切换为单列';

  @override
  String get recommendSwitchGrid => '切换为多列';

  @override
  String get sideBarExpand => '展开侧边栏';

  @override
  String get sideBarCollapse => '收起侧边栏';

  @override
  String get sideBarMore => '更多';

  @override
  String get recommendTabHot => '热门';

  @override
  String get recommendTabBangumi => '番剧';

  @override
  String get recommendSourceTitle => '推荐数据来源';
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

  @override
  String metroDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get metroSunday => '星期日';

  @override
  String get metroMonday => '星期一';

  @override
  String get metroTuesday => '星期二';

  @override
  String get metroWednesday => '星期三';

  @override
  String get metroThursday => '星期四';

  @override
  String get metroFriday => '星期五';

  @override
  String get metroSaturday => '星期六';

  @override
  String get metroLogin => '登入';

  @override
  String get metroWelcome => '歡迎';

  @override
  String get imageViewerNoFile => '找不到圖片檔案';

  @override
  String get syncPassphraseEmpty => '同步口令不能為空';

  @override
  String get imageBytesRequired => 'imageUrl 或 imageBytes 必須提供其一';

  @override
  String get webdavConnectSuccess => '✅ 連線成功！';

  @override
  String get webdavConfigSaved => '設定已儲存';

  @override
  String get webdavConfigureFirst => '請先設定並測試 WebDAV 連線';

  @override
  String get webdavSelectContactsFirst => '請先在下方面選要備份的聯絡人';

  @override
  String get webdavNoFiles => '選中的聯絡人沒有可備份的檔案';

  @override
  String get webdavConfirmBackup => '確認備份';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return '將備份 $contacts 位聯絡人的 $files 個檔案到 WebDAV 伺服器。\n遠端路徑：$path/chats/<暱稱>/';
  }

  @override
  String get webdavStartBackup => '開始備份';

  @override
  String get webdavBackingUpTitle => '正在備份';

  @override
  String get webdavBackupDoneTitle => '備份完成';

  @override
  String webdavTotalFiles(int count) {
    return '總計：$count 個檔案';
  }

  @override
  String webdavSuccessCount(int count) {
    return '成功：$count';
  }

  @override
  String webdavFailCount(int count) {
    return '失敗：$count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...還有 $count 個錯誤';
  }

  @override
  String get webdavBackupFab => '備份';

  @override
  String get webdavShowInfo => '顯示我的資訊';

  @override
  String get webdavHideInfo => '隱藏我的資訊';

  @override
  String get webdavScanToFill => '掃碼填入伺服器地址';

  @override
  String get webdavScanFilled => '已透過掃碼填入地址';

  @override
  String get webdavServerConfig => '伺服器設定';

  @override
  String get webdavServerUrlLabel => '伺服器地址';

  @override
  String get webdavUsernameLabel => '使用者名稱';

  @override
  String get webdavPasswordLabel => '密碼';

  @override
  String get webdavRemotePathLabel => '遠端備份路徑';

  @override
  String get webdavTesting => '測試中...';

  @override
  String get webdavSaveAndTest => '儲存並測試連線';

  @override
  String get webdavSaveOnly => '僅儲存';

  @override
  String get webdavConnectVerified => '連線驗證通過';

  @override
  String get webdavAutoBackup => '自動備份';

  @override
  String get webdavAutoBackupOnReceive => '接收檔案時自動備份';

  @override
  String get webdavAutoBackupSubtitle => '僅對下方面選的聯絡人生效';

  @override
  String get webdavMediaSync => '媒體同步';

  @override
  String get webdavSyncPlaylists => '同步播放清單';

  @override
  String get webdavSyncDanmaku => '同步彈幕';

  @override
  String get webdavPassphraseEncrypted => '同步密碼（AES-256 加密）';

  @override
  String get webdavPassphrasePlain => '同步密碼（留空 = 明文上傳）';

  @override
  String get webdavPassphraseHint => '填寫密碼後播放清單將加密上傳';

  @override
  String get webdavGeneratePassphrase => '產生隨機密碼';

  @override
  String get webdavMediaSyncHint =>
      '播放清單（含背景圖）與彈幕儲存到雲端的獨立目錄（playlists/、danmaku/），不會與聊天備份混在一起。多台裝置共用同一遠端路徑即可互相合併；播放清單可在播放清單頁手動同步或從雲端還原。';

  @override
  String get webdavEncryptionOn =>
      '已啟用加密：播放清單將以 AES-256-GCM 加密後上傳（含內嵌的 WebDAV 鑑權資訊），伺服器無法讀取內容。多台裝置需填寫相同密碼才能解密。';

  @override
  String get webdavEncryptionOff =>
      '未加密：播放清單（含內嵌的 WebDAV 鑑權資訊）將明文上傳，任何能讀取伺服器檔案的人都能看到，不推薦。';

  @override
  String get webdavBackupContacts => '備份聯絡人';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '已選 $selected / $total 位聯絡人';
  }

  @override
  String get webdavSearchContacts => '搜尋聯絡人或 IP...';

  @override
  String get webdavDeselectAll => '取消全選';

  @override
  String webdavFileCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get webdavNoContacts => '暫無聯絡人';

  @override
  String get webdavNoMatch => '無相符結果';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count 個檔案';
  }

  @override
  String get webdavManage => '管理';

  @override
  String get webdavLastSync => '上次同步';

  @override
  String get webdavLastError => '最近錯誤';

  @override
  String get webdavClearConfig => '清除 WebDAV 設定';

  @override
  String get webdavClearConfigSubtitle => '刪除所有伺服器資訊和憑證';

  @override
  String get webdavUserLabel => '用戶';

  @override
  String webdavStatusActive(String name) {
    return '$name已啟用';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name已設定';
  }

  @override
  String get webdavStatusNotConfigured => '未設定';

  @override
  String get webdavNotSynced => '尚未同步';

  @override
  String get webdavJustNow => '上次同步：剛剛';

  @override
  String webdavMinutesAgo(int minutes) {
    return '上次同步：$minutes 分鐘前';
  }

  @override
  String webdavHoursAgo(int hours) {
    return '上次同步：$hours 小時前';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return '上次同步：$month月$day日 $time';
  }

  @override
  String get webdavPassphraseGenerated => '已產生同步密碼並複製到剪貼簿，請在其他裝置上填入相同密碼';

  @override
  String get webdavConfirmClear => '確認清除';

  @override
  String get webdavClearConfirmText =>
      '將刪除所有 WebDAV 設定（伺服器、憑證、聯絡人選取）。\n已上傳的檔案不受影響。';

  @override
  String get profileEditProfile => '編輯資料';

  @override
  String get profileAccountSection => '帳戶管理';

  @override
  String get profileWebdavBackup => 'WebDAV 備份';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username 已登入';
  }

  @override
  String get profileNotLoggedIn => '未登入';

  @override
  String get profileAvatarSection => '頭像';

  @override
  String get profileChangeAvatar => '更換頭像';

  @override
  String get profileRemoveAvatar => '移除頭像';

  @override
  String get profilePickFromGallery => '從相簿選擇圖片';

  @override
  String get profileRestoreDefaultAvatar => '還原預設頭像';

  @override
  String get profileSetBackground => '設定背景';

  @override
  String get profileBgSubtitle => '為側邊欄選擇一張背景圖';

  @override
  String get profileRestoreDefault => '還原預設';

  @override
  String get profileBgRemoveSubtitle => '移除自訂背景，使用主題色漸變';

  @override
  String get profileInfoSection => '個人資訊';

  @override
  String get profileNicknameLabel => '暱稱';

  @override
  String get profileNotSet => '未設定';

  @override
  String get profileBgTitle => '個人資料背景';

  @override
  String get profileAvatarUpdated => '✅ 頭像已更新';

  @override
  String profileAvatarFailed(String error) {
    return '❌ 選擇頭像失敗: $error';
  }

  @override
  String get profileRemoveAvatarConfirm => '確定要刪除目前頭像嗎？此操作無法還原。';

  @override
  String get profileAvatarRemoved => '頭像已移除';

  @override
  String get profileSetNickname => '設定暱稱';

  @override
  String get profileNicknameHint => '輸入暱稱';

  @override
  String get profileNicknameEmpty => '暱稱不能為空';

  @override
  String get profileNicknameUpdated => '✅ 暱稱已更新';

  @override
  String get colorDefaultGreen => '預設綠';

  @override
  String get colorPink => '粉紅色';

  @override
  String get colorRed => '紅色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorYellow => '黃色';

  @override
  String get colorLime => '酸橙色';

  @override
  String get colorLightGreen => '淺綠色';

  @override
  String get colorGreen => '綠色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '藍綠色';

  @override
  String get colorLightBlue => '淺藍色';

  @override
  String get colorBlue => '藍色';

  @override
  String get colorIndigo => '靛藍色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorBlueGrey => '藍灰色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorGrey => '灰色';

  @override
  String get themeColorExtracted => '已從圖片提取主題色';

  @override
  String themeColorFailed(String error) {
    return '取色失敗: $error';
  }

  @override
  String get themeImageOnly => '僅支援圖片格式';

  @override
  String get themeTitle => '主題';

  @override
  String themeColorCopied(String hex) {
    return '已複製色號: $hex';
  }

  @override
  String get themeAppearance => '外觀';

  @override
  String get themeDarkBlackened => '深色模式（已黑化）';

  @override
  String get themeOff => '已關閉';

  @override
  String get themeEnabled => '已啟用';

  @override
  String get themeColorsSection => '配色';

  @override
  String get themePaletteStyle => '調色板風格';

  @override
  String get themeFollowSystem => '跟隨系統配色';

  @override
  String get themePickColor => '選擇顏色';

  @override
  String get themeDropHint => '放開以從圖片提取主題色';

  @override
  String get themeNewTheme => '新增主題';

  @override
  String themeSwitched(String name) {
    return '已切換至 $name 主題';
  }

  @override
  String get themeDeleteTitle => '刪除主題';

  @override
  String themeDeleteConfirm(String name) {
    return '確定要刪除自訂主題「$name」嗎？';
  }

  @override
  String themeDeleted(String name) {
    return '已刪除「$name」';
  }

  @override
  String get themeCreateTitle => '建立自訂主題';

  @override
  String get themeNameLabel => '主題名稱';

  @override
  String get themeNameHint => '請輸入文字';

  @override
  String get themeHexLabel => '十六進位/RGB';

  @override
  String get themeHexHint => '例如 #FF0000 或 255,0,0';

  @override
  String themeCreated(String name) {
    return '主題「$name」已建立並儲存';
  }

  @override
  String get themeCopyColor => '複製色號';

  @override
  String get themePickFromImage => '從圖片取色';

  @override
  String get searchBack => '返回設定';

  @override
  String get searchHint => '搜尋設定項目…';

  @override
  String get searchPrompt => '輸入關鍵詞搜尋設定項目';

  @override
  String get searchExamples => '例如：更新率 / 解碼 / UA / 彈幕';

  @override
  String searchNoResults(String query) {
    return '找不到「$query」相關設定';
  }

  @override
  String get searchThemeMode => '主題模式';

  @override
  String get searchPureBlack => '純黑深色模式';

  @override
  String get searchThemeColor => '主題配色';

  @override
  String get searchFontWeight => '文字粗細';

  @override
  String get searchDisplayScale => '顯示縮放';

  @override
  String get searchDisplayMode => '顯示模式 / 螢幕更新率';

  @override
  String get searchStatusBar => '狀態列';

  @override
  String get searchKeepWindowRatio => '等比例拉伸視窗';

  @override
  String get searchLongPressSpeed => '長按鍵加速';

  @override
  String get searchScreenshot => '截圖功能';

  @override
  String get searchScreenshotDanmaku => '截圖時顯示彈幕';

  @override
  String get searchPlayProgress => '播放進度';

  @override
  String get searchHwdec => '硬件解碼';

  @override
  String get searchVideoSync => '影片同步';

  @override
  String get searchImmersiveLongPress => '沉浸模式長按加速';

  @override
  String get searchMpvLog => '記錄 mpv 日誌';

  @override
  String get searchMpvLogLevel => 'mpv 日誌細度';

  @override
  String get searchNetworkMode => '網絡模式';

  @override
  String get searchInsecureCert => '允許不安全的憑證';

  @override
  String get searchChatIpv6 => '聊天 IPv6';

  @override
  String get searchConnectivityTest => '連通性測試';

  @override
  String get searchHostOverrides => 'Host 對應';

  @override
  String get searchDohQuery => 'DoH 查詢';

  @override
  String get searchReferer => '請求頭 Referer';

  @override
  String get searchUserAgent => '請求頭 User-Agent';

  @override
  String get searchSystemSettings => '系統設定';

  @override
  String get searchUserSettings => '用戶設定';

  @override
  String get settingsDisplaySub => '主題、字型、版面配置';

  @override
  String get settingsSystem => '系統';

  @override
  String get settingsSystemSub => '語言、儲存、權限';

  @override
  String get settingsStorage => '儲存';

  @override
  String get settingsStorageSub => '圖片快取、彈幕快取';

  @override
  String get settingsNetwork => '網絡';

  @override
  String get settingsNetworkSub => 'Wi-Fi、Proxy、同步';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSub => '應用語言、B 站翻譯（AI 翻譯）';

  @override
  String get appLangSection => '應用語言';

  @override
  String get appLangFollowSystem => '跟隨系統';

  @override
  String get biliLangSection => '翻譯目標語言';

  @override
  String get biliAiSection => 'AI 翻譯';

  @override
  String get biliAiTranslateEnable => '啟用 AI 翻譯';

  @override
  String get biliAiTranslateOnDesc => '已開啟：B 站請求將攜帶翻譯頭，返回該語言內容';

  @override
  String get biliAiTranslateOffDesc => '關閉：按原始語言返回內容';

  @override
  String get langZhCn => '簡體中文';

  @override
  String get langZhHk => '繁體中文（香港）';

  @override
  String get langZhTw => '繁體中文（台灣）';

  @override
  String get langEnUs => 'English（英語）';

  @override
  String get langJaJp => '日本語';

  @override
  String get langKoKr => '한국어';

  @override
  String get settingsPlayer => '播放器';

  @override
  String get settingsPlayerSub => '狀態列、加速、截圖';

  @override
  String get settingsStartScreenSub => '開始螢幕、Charm';

  @override
  String get settingsLogs => '日誌';

  @override
  String get settingsLogsSub => '錯誤日誌、mpv 日誌';

  @override
  String get settingsAccounts => '帳號';

  @override
  String get settingsAccountsSub => 'B 站、WebDAV';

  @override
  String get settingsUser => '用戶';

  @override
  String get settingsUserSub => '帳戶、私隱、安全';

  @override
  String get settingsAboutSub => '版本、授權';

  @override
  String get settingsLicenses => '開源授權';

  @override
  String get settingsLicensesSub => '本專案引用的開源專案';

  @override
  String get settingsSearch => '搜尋設定';

  @override
  String get openSidebar => '開啟側邊欄';

  @override
  String get settingsPlaceholderEasterEgg => '唔，有咩問題點解唔問下神奇嘅芙莉蓮呢';

  @override
  String storageClearTitle(String label) {
    return '清理$label';
  }

  @override
  String storageClearConfirm(String label) {
    return '確定要清理$label嗎？清理後重新瀏覽圖片會再次下載。';
  }

  @override
  String get storageClear => '清理';

  @override
  String storageCleared(String label) {
    return '$label已清理';
  }

  @override
  String get refreshAction => '重新整理';

  @override
  String get storageCacheSection => '快取';

  @override
  String get storageImageCache => '圖片快取';

  @override
  String get storageCounting => '正在統計…';

  @override
  String storageFileCount(int count, String size) {
    return '$count 個檔案 · $size';
  }

  @override
  String get storageDanmakuCache => '彈幕快取';

  @override
  String storageVideoCount(int count, String size) {
    return '$count 個影片 · $size';
  }

  @override
  String get settingsAutoOfflineCache => '自動離線快取播放過的影片';

  @override
  String get settingsAutoOfflineCacheHint =>
      '觀看過的影片會自動下載到本機（約 2GB 上限，超出自動淘汰最舊），下次開啟直接從本機播放、不再重複拉取；關閉後不再新增快取。';

  @override
  String get storageVideoCache => '離線影片快取';

  @override
  String get storageVideoCacheDesc => '播放過的影片媒體流（容量上限內自動快取、LRU 淘汰），下次開啟直接從本機播放';

  @override
  String get storageMemoryCache => '記憶體圖片快取';

  @override
  String get storageMemoryCacheDesc => '本次執行中已解碼的圖片，結束後自動釋放';

  @override
  String get storageClearing => '正在清理…';

  @override
  String get storageClearAll => '一鍵清理全部快取';

  @override
  String get storageCacheHint =>
      '圖片快取為應用程式私有目錄（image_cache），清理後瀏覽過的評論配圖會重新下載；彈幕快取用於離線彈幕載入。';

  @override
  String get storageClearAllTitle => '清理全部快取';

  @override
  String get storageClearAllConfirm => '將清空圖片快取、彈幕快取與記憶體圖片快取，清理後重新瀏覽圖片會再次下載。';

  @override
  String get storageAllCleared => '快取已全部清理';

  @override
  String get verificationPendingRequests => '待處理請求';

  @override
  String get verificationNoPending => '暫無待處理請求';

  @override
  String verificationIpAddress(String ip) {
    return 'IP 地址：$ip';
  }

  @override
  String verificationNickname(String name) {
    return '暱稱：$name';
  }

  @override
  String verificationRequestTime(String time) {
    return '請求時間：$time';
  }

  @override
  String get verificationRejectInvalid => '無法拒絕：IP 地址無效';

  @override
  String get verificationRejected => '已拒絕連線請求';

  @override
  String get verificationReject => '拒絕';

  @override
  String get verificationAcceptInvalid => '無法接受：IP 地址無效';

  @override
  String get verificationAccepted => '已接受連線請求';

  @override
  String get verificationAccept => '同意';

  @override
  String get startScreenWarning => '我們可能不再更新此專案';

  @override
  String get startScreenTitle => '開始螢幕';

  @override
  String get startScreenGoBack => '向上瀏覽';

  @override
  String get enableStartScreen => '啟用開始螢幕';

  @override
  String get startScreenEnableSubtitle => '允許從 Charm 的 Start 按鈕進入開始螢幕';

  @override
  String get enableCharm => '啟用 Charm';

  @override
  String get charmEnableSubtitle => '在螢幕右側提供 Charm 快捷欄';

  @override
  String get charmGestureTitle => '手勢拉出 Charm';

  @override
  String get charmGestureSubtitle => '從螢幕右邊緣向左滑動或懸停右上角拉出 Charm';

  @override
  String get externalVideo => '外部影片';

  @override
  String get audioChannelName => '影片媒體播放';

  @override
  String get foregroundChannelName => 'Navi 保活';

  @override
  String get foregroundChannelDesc => '主人~保持我在背景執行~';

  @override
  String get foregroundTitle => '保活中';

  @override
  String get foregroundText => '我驗牌';

  @override
  String get drawerBilibiliSearch => 'B站搜尋';

  @override
  String get commentImageLoadFail => '圖片載入失敗';

  @override
  String get commentDetailTitle => '評論詳情';

  @override
  String get commentLikeLoginRequired => '請先登入 B 站帳號（並開啟攜帶 Cookie）後再點讚';

  @override
  String commentLikeFail(String error) {
    return '點讚失敗：$error';
  }

  @override
  String get relatedEmpty => '暫無相關推薦';

  @override
  String get biliLoadFailed => '載入失敗';

  @override
  String countWan(String count) {
    return '$count萬';
  }

  @override
  String countYi(String count) {
    return '$count億';
  }

  @override
  String get searchNoNewContent => '暫無新內容';

  @override
  String get searchNewContentRefreshed => '已為您刷新一組新內容';

  @override
  String get biliDialogNeedLogin => '需要登入';

  @override
  String get biliDialogInteractDesc => '點讚 / 投幣 / 三連等互動需要登入 B 站帳號';

  @override
  String get biliGoLogin => '去登入';

  @override
  String get biliCookieScopeHint => '請在帳號設定中開啟「攜帶 Cookie 請求」與「互動操作」範圍';

  @override
  String get videoTabRelated => '相關影片';

  @override
  String get videoTabComments => '評論';

  @override
  String videoTabCommentsCount(int count) {
    return '評論 $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return '選集 $count';
  }

  @override
  String get videoTabIntro => '簡介';

  @override
  String danmakuWatching(String count) {
    return '$count人正在看';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '已裝填$count條彈幕';
  }

  @override
  String get danmakuToggleOn => '開啟彈幕';

  @override
  String get danmakuDisable => '關閉彈幕';

  @override
  String get danmakuInputHint => '發個友善的彈幕見證當下';

  @override
  String get danmakuToastEmpty => '彈幕內容不能為空';

  @override
  String danmakuToastSendFail(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get danmakuToastSent => '彈幕已傳送';

  @override
  String get videoLikeTooltip => '點讚（長按一鍵三連）';

  @override
  String get videoUnlikeTooltip => '取消點讚';

  @override
  String get videoCoinTooltip => '投幣';

  @override
  String get videoFavTooltip => '收藏';

  @override
  String get videoUnfavTooltip => '取消收藏';

  @override
  String get videoShareLabel => '分享';

  @override
  String videoStatRating(String count) {
    return '$count人評分';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count追番';
  }

  @override
  String videoStatWatching(String count) {
    return '$count人在看';
  }

  @override
  String get videoFollowLabel => '關注';

  @override
  String get videoFollowedLabel => '已關注';

  @override
  String get commentDetailEmpty => '還沒有回覆';

  @override
  String commentDetailNoMore(int count) {
    return '沒有更多回覆了（共 $count 則）';
  }

  @override
  String get commentDetailLoadMore => '滑動載入更多';

  @override
  String get commentDetailRootBadge => '樓主';

  @override
  String get commentDetailDeleted => '(評論已刪除)';

  @override
  String get commentMenuCopy => '複製評論';

  @override
  String get commentMenuSelectText => '選取文字';

  @override
  String get commentDialogTitle => '評論內容';

  @override
  String get commentDialogEmpty => '(這裡空空的)';

  @override
  String get danmakuInputBvPrompt => '請輸入 BV 號';

  @override
  String get danmakuInputCidPrompt => '請輸入 CID';

  @override
  String get danmakuInputCidNumeric => 'CID 必須為純數字';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return '命中本機快取：$count 條彈幕 (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return '獲取成功：$count 條彈幕 (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => '取得失敗';

  @override
  String get danmakuInputTitle => 'Bilibili 彈幕';

  @override
  String get danmakuInputTypeLabel => '類型：';

  @override
  String get danmakuInputBvHint => '輸入 BV 號，將自動取得第一個分P的 CID';

  @override
  String get danmakuInputCidHint => '直接輸入 CID 純數字（例如從 API 取得）';

  @override
  String get danmakuInputFetching => '取得中...';

  @override
  String get danmakuInputFetchDanmaku => '取得彈幕';

  @override
  String get danmakuInputEmpty => '輸入不能為空';

  @override
  String get danmakuCidFetchFail => '無法取得 CID，請檢查 BV 號';

  @override
  String danmakuNoData(String oid) {
    return '未取得彈幕資料（oid=$oid）';
  }

  @override
  String get danmakuSettingsTitle => '彈幕設定';

  @override
  String get danmakuDataSource => '資料來源';

  @override
  String get danmakuDisplayControl => '顯示控制';

  @override
  String get danmakuEnable => '啟用彈幕';

  @override
  String get danmakuSmartMask => '智能防遮擋';

  @override
  String get danmakuSmartMaskDesc => '識別人物，彈幕不遮擋畫面主體';

  @override
  String get danmakuTypeFilter => '彈幕類型';

  @override
  String get danmakuTypeScroll => '滾動彈幕';

  @override
  String get danmakuTypeTop => '頂部彈幕';

  @override
  String get danmakuTypeBottom => '底部彈幕';

  @override
  String get danmakuTypeAdvanced => '進階彈幕 (BAS)';

  @override
  String get danmakuAdvancedSubtitle => '動畫彈幕，開啟可能影響效能';

  @override
  String get danmakuParameters => '參數調整';

  @override
  String get danmakuScrollSpeed => '滾動速度';

  @override
  String get danmakuOpacity => '不透明度';

  @override
  String get danmakuFontSize => '字體大小';

  @override
  String get danmakuMaxLines => '顯示行數';

  @override
  String danmakuLinesCount(int count) {
    return '$count 行';
  }

  @override
  String get danmakuQuickActions => '快速操作';

  @override
  String get danmakuResetParams => '重設參數';

  @override
  String get danmakuClearDanmaku => '清空彈幕';

  @override
  String get danmakuLoadLocalXml => '載入本機 XML 彈幕';

  @override
  String get danmakuFetchOnline => '取得 Bilibili 線上彈幕';

  @override
  String get danmakuNotLoaded => '尚未載入彈幕';

  @override
  String danmakuLoadedCount(int count) {
    return '已載入 $count 條彈幕';
  }

  @override
  String get danmakuBlockColorful => '彩色彈幕';

  @override
  String get danmakuCloudFilter => '智慧雲端遮蔽';

  @override
  String get danmakuCloudFilterOff => '關閉';

  @override
  String danmakuCloudFilterLevel(int level) {
    return '$level 級';
  }

  @override
  String get danmakuFontSizeFS => '全螢幕字型大小';

  @override
  String danmakuSeconds(int value) {
    return '$value 秒';
  }

  @override
  String get danmakuOthers => '其他';

  @override
  String get danmakuMassiveMode => '海量彈幕';

  @override
  String get danmakuStatic2Scroll => '固定轉滾動';

  @override
  String get danmakuShowArea => '顯示區域';

  @override
  String get danmakuFontWeight => '字體粗細';

  @override
  String get danmakuStrokeWidth => '描邊粗細';

  @override
  String get danmakuScrollDuration => '滾動彈幕時長';

  @override
  String get danmakuStaticDuration => '靜態彈幕時長';

  @override
  String get danmakuLineHeight => '彈幕行高';

  @override
  String danmakuResetTo(String value) {
    return '恢復默認：$value';
  }

  @override
  String get naviAddAction => '新增';

  @override
  String playlistImportAdded(int count) {
    return '已新增 $count 個檔案';
  }

  @override
  String get playlistAddEpisodeTitle => '新增集數';

  @override
  String get playlistTitleLabel => '標題';

  @override
  String get playlistEpisodeHint => '第 1 集';

  @override
  String get playlistVideoUrlLabel => '影片 URL';

  @override
  String get playlistAdd => '新增';

  @override
  String get playlistNameRequired => '請輸入播放清單名稱';

  @override
  String get playlistAtLeastOneVideo => '請至少新增一個影片';

  @override
  String get playlistEditTitle => '編輯播放清單';

  @override
  String get playlistCreateTitle => '建立播放清單';

  @override
  String get playlistNameLabel => '播放清單名稱';

  @override
  String get playlistNameHint => '我的追番清單';

  @override
  String get playlistWebdavMulti => 'WebDAV 多選';

  @override
  String playlistItemsCount(int count) {
    return '$count 集';
  }

  @override
  String get playlistNoItems => '還沒有新增任何影片';

  @override
  String get playlistImportHint => '點擊上方按鈕匯入';

  @override
  String get playlistSaveChanges => '儲存變更';

  @override
  String get playlistEpisodePanelTitle => '選集';

  @override
  String playlistEpisodeCurrent(int index) {
    return '目前：第 $index 集';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what：$message';
  }

  @override
  String get playlistSyncTwoWay => '雙向同步播放清單';

  @override
  String get playlistSyncTwoWaySubtitle => '下載雲端並合併，再上傳合併結果（含背景圖）';

  @override
  String get playlistRestoreFromCloud => '從雲端還原';

  @override
  String get playlistRestoreFromCloudSubtitle => '用雲端資料整體覆寫本機播放清單（含背景圖）';

  @override
  String get playlistUploadToCloud => '上傳到雲端';

  @override
  String get playlistUploadToCloudSubtitle => '把本機播放清單全量上傳（含背景圖，不合併）';

  @override
  String get playlistSyncDanmaku => '同步彈幕快取';

  @override
  String get playlistSyncDanmakuSubtitle => '與雲端彈幕快取互相合併（取較新）';

  @override
  String playlistCreated(String name) {
    return '已建立：$name';
  }

  @override
  String get playlistDeleteTitle => '刪除播放清單';

  @override
  String playlistDeleteConfirm(String name) {
    return '確定要刪除「$name」嗎？';
  }

  @override
  String get playlistNewTooltip => '新增播放清單';

  @override
  String get playlistListTitle => '播放清單';

  @override
  String get playlistCloudSync => '雲端同步';

  @override
  String get playlistMyLists => '我的清單';

  @override
  String get playlistNoLists => '暫無播放清單';

  @override
  String playlistListSummary(int count) {
    return '共 $count 個 · 點擊清單檢視全部劇集';
  }

  @override
  String get playlistEmptyTitle => '還沒有播放清單';

  @override
  String get playlistEmptyHint => '點擊右下角「建立」按鈕新建一個吧';

  @override
  String get playlistResume => '續播';

  @override
  String get playlistEditAction => '編輯';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total 集 · 看到第 $current 集';
  }

  @override
  String get subtitleOff => '關閉字幕';

  @override
  String subtitleTrackFallback(String id) {
    return '軌道 $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return '已載入字幕：$name';
  }

  @override
  String get subtitleWebdavNotConfigured => 'WebDAV 未設定，請先登入';

  @override
  String get subtitleWebdavFolderEmpty => 'WebDAV 字幕資料夾為空';

  @override
  String get subtitleSelectFile => '選擇字幕檔案';

  @override
  String subtitleDownloadFailed(int code) {
    return '字幕下載失敗：HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return '已載入遠端字幕：$name';
  }

  @override
  String subtitleLoadError(String error) {
    return '字幕載入異常：$error';
  }

  @override
  String get subtitlePanelTitle => '字幕 (CC)';

  @override
  String get subtitleLoadLocal => '載入本機字幕';

  @override
  String get subtitleLoadWebdav => '從 WebDAV 載入字幕';

  @override
  String get subtitleFontSize => '字號';

  @override
  String get subtitleFontColor => '字體顏色';

  @override
  String get subtitleBgColor => '背景顏色';

  @override
  String get webdavInputPath => '輸入路徑';

  @override
  String get webdavGoTo => '前往';

  @override
  String get webdavLoginRequired => '請先登入 WebDAV 帳號';

  @override
  String get webdavLoginSubtitle => '設定伺服器後可瀏覽遠端影片';

  @override
  String get webdavLoginSubtitleMulti => '登入後可多選遠端影片建立播放清單';

  @override
  String get webdavRefresh => '重新整理';

  @override
  String get webdavRoot => '根';

  @override
  String get webdavParent => '上層';

  @override
  String get webdavFolderEmpty => '此資料夾為空';

  @override
  String get webdavPullToRefresh => '下拉重新整理試試？';

  @override
  String get webdavSelectVideo => '請選擇影片檔案';

  @override
  String get webdavPlay => '播放';

  @override
  String get webdavMultiSelectTitle => '多選檔案';

  @override
  String get webdavNoSelection => '未選擇檔案';

  @override
  String webdavSelectedCount(int count) {
    return '已選 $count 個影片';
  }

  @override
  String webdavSelectionOrder(String names) {
    return '依選擇順序：$names';
  }

  @override
  String get webdavClear => '清空';

  @override
  String get webdavConfirmSelection => '確認選擇';

  @override
  String get webdavGoLogin => '去登入';

  @override
  String get profileTitle => '個人資訊';

  @override
  String get settingsAvatarTitle => '頭像';

  @override
  String get settingsAvatarSet => '已設定';

  @override
  String get settingsNotSet => '未設定';

  @override
  String get settingsAvatarChangeTooltip => '更換頭像';

  @override
  String get settingsAvatarDeleteTooltip => '刪除頭像';

  @override
  String get settingsAvatarUpdated => '頭像已更新';

  @override
  String settingsPickAvatarFailed(String error) {
    return '選擇頭像失敗：$error';
  }

  @override
  String get settingsAvatarDeleteTitle => '刪除頭像';

  @override
  String get settingsAvatarDeleteConfirm => '確定要刪除目前的頭像嗎？';

  @override
  String get settingsAvatarDeleteConfirmPermanent => '確定要刪除目前的頭像嗎？此操作無法復原。';

  @override
  String get settingsAvatarDeleted => '頭像已刪除';

  @override
  String get settingsNickname => '暱稱';

  @override
  String get settingsNicknameEditTooltip => '編輯暱稱';

  @override
  String get settingsSetNickname => '設定暱稱';

  @override
  String get settingsNicknamePrompt => '請輸入您的暱稱';

  @override
  String get settingsNicknameHint => '輸入暱稱';

  @override
  String get settingsNicknameEmpty => '暱稱不能為空';

  @override
  String get settingsNicknameTooLong => '暱稱長度不能超過 20 個字元';

  @override
  String get settingsNicknameUpdated => '暱稱已更新';

  @override
  String get settingsLockWallpaper => '鎖定螢幕桌布';

  @override
  String get settingsWallpaperCustomSet => '已設定自訂桌布';

  @override
  String get settingsWallpaperDefaultBg => '使用預設深色背景';

  @override
  String get settingsWallpaperUpdated => '桌布已更新';

  @override
  String get settingsWallpaperPickTooltip => '選擇桌布';

  @override
  String get settingsWallpaperDelete => '刪除桌布';

  @override
  String get settingsWallpaperDeleteConfirm => '確定要刪除鎖定螢幕桌布並恢復預設嗎？';

  @override
  String get settingsWallpaperDeleted => '桌布已刪除';

  @override
  String get settingsDecoImage => '右下角裝飾圖';

  @override
  String get settingsDecoImageSet => '已設定 (支援透明 PNG/WebP)';

  @override
  String get settingsDecoImageUpdated => '裝飾圖已更新';

  @override
  String settingsPickImageFailed(String error) {
    return '選擇圖片失敗：$error';
  }

  @override
  String get settingsPickImageTooltip => '選擇圖片';

  @override
  String get settingsDecoImageDelete => '刪除裝飾圖';

  @override
  String get settingsDecoImageDeleteConfirm => '確定要刪除右下角裝飾圖嗎？';

  @override
  String get settingsDecoImageDeleted => '裝飾圖已刪除';

  @override
  String get settingsSize => '大小';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => '透明度';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => '顯示';

  @override
  String get settingsDisplaySubtitle => '主題 · 配色 · 文字 · 縮放';

  @override
  String get settingsAppTheme => '應用程式主題';

  @override
  String settingsCurrentColor(String color) {
    return '目前配色：#$color';
  }

  @override
  String get settingsFontWeight => '文字粗細';

  @override
  String settingsCurrentFontWeight(int weight) {
    return '目前粗細：$weight';
  }

  @override
  String get settingsDisplayScale => '顯示縮放';

  @override
  String settingsCurrentScale(int percent) {
    return '目前比例：$percent%';
  }

  @override
  String get settingsRestrictIp => '限制內網 IP 連線';

  @override
  String get settingsRestrictIpSubtitle => '僅允許 A 類、B 類、C 類內網 IP 地址';

  @override
  String get settingsDefaultPort => '預設連接埠';

  @override
  String get settingsAdjustFontWeight => '調整文字粗細';

  @override
  String settingsFontWeightPreview(int weight) {
    return '預覽：$weight';
  }

  @override
  String get settingsWeightHairline => '極細';

  @override
  String get settingsWeightThin => '細';

  @override
  String get settingsWeightRegular => '一般';

  @override
  String get settingsWeightMedium => '中等';

  @override
  String get settingsWeightBold => '粗體';

  @override
  String get settingsWeightBlack => '極粗';

  @override
  String get settingsFontWeightUpdated => '字體粗細已更新';

  @override
  String get logTitle => '日誌';

  @override
  String get logBackTooltip => '向上瀏覽';

  @override
  String get logRefresh => '重新整理';

  @override
  String get logClearAll => '清空日誌';

  @override
  String get logClearTitle => '清空日誌';

  @override
  String get logClearConfirm => '將刪除 error/ 與 mpv/ 目錄下的全部日誌檔案，確定嗎？';

  @override
  String get logClearAction => '清空';

  @override
  String logDeletedCount(int count) {
    return '已刪除 $count 個日誌檔案';
  }

  @override
  String get logCopyContent => '複製內容';

  @override
  String get logShare => '分享日誌';

  @override
  String get logDeleteThis => '刪除此日誌';

  @override
  String get logEmptyContent => '（空日誌）';

  @override
  String logStorageLocation(String path) {
    return '儲存位置：$path';
  }

  @override
  String get logErrorSection => '錯誤日誌（當機時必寫）';

  @override
  String get logNoErrorLogs => '暫無錯誤日誌';

  @override
  String get logMpvSection => 'mpv 日誌（選用）';

  @override
  String get logNoMpvLogs => '暫無 mpv 日誌';

  @override
  String get logReadingLogs => '正在讀取日誌…';

  @override
  String get lockFollowThemeColor => '跟隨主題色 (時間)';

  @override
  String get lockShowBattery => '顯示電池';

  @override
  String get lockShowNetwork => '顯示網絡';

  @override
  String lockDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get myQrSelectIpHint => '點擊選擇二維碼使用的 IP';

  @override
  String get myQrNoIpType => '沒有此類型的 IP';

  @override
  String get myQrInUse => '使用中';

  @override
  String get myQrSetAsQr => '設為二維碼';

  @override
  String get netLanDiscoveryPort => '本機探索連接埠';

  @override
  String netDohNoRecord(String domain) {
    return '查無 $domain 的 A 紀錄';
  }

  @override
  String netDohQueryFailed(String error) {
    return '查詢失敗：$error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return '已儲存對應：$domain → $ip';
  }

  @override
  String get netAddHostMapping => '新增 Host 對應';

  @override
  String get netDomainLabel => '網域名稱';

  @override
  String get netIpLabel => 'IP 地址';

  @override
  String get netAdd => '新增';

  @override
  String netMappingAdded(String host, String ip) {
    return '已新增對應：$host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return '已移除對應：$host';
  }

  @override
  String get netTitle => '網絡';

  @override
  String get netBackTooltip => '向上瀏覽';

  @override
  String get netRetestAll => '全部重新測試';

  @override
  String get netConnectionModeSection => '連線模式';

  @override
  String get netNetworkMode => '網絡模式';

  @override
  String get netModeStandardLabel => '標準模式';

  @override
  String get netModeCompatLabel => '相容直連';

  @override
  String get netModeStandardDesc => '使用系統預設網絡堆疊';

  @override
  String get netAllowInsecureCert => '允許不安全的憑證';

  @override
  String get netAllowInsecureCertDesc => '相容直連時略過憑證驗證（IP 直連情境）';

  @override
  String get netChatIpv6 => '聊天 IPv6';

  @override
  String get netChatIpv6On => '已開啟：支援 IPv6 聊天、探索與二維碼';

  @override
  String get netChatIpv6Off => '已關閉：僅使用 IPv4 聊天';

  @override
  String get netChatIpv6EnabledSnack => '已開啟聊天 IPv6（重新啟動應用程式後生效）';

  @override
  String get netChatIpv6DisabledSnack => '已關閉聊天 IPv6（重新啟動應用程式後生效）';

  @override
  String get netLocalSendCompat => 'LocalSend 相容';

  @override
  String get netLocalSendCompatOn =>
      '已開啟：啟用 LocalSend 協定（連接埠 53317），可與 LocalSend 官方客戶端互傳檔案';

  @override
  String get netLocalSendCompatOff => '已關閉：使用 navi 原生協定方案';

  @override
  String get netLocalSendCompatEnabledSnack => '已開啟 LocalSend 相容';

  @override
  String get netLocalSendCompatDisabledSnack => '已關閉 LocalSend 相容（恢復原生方案）';

  @override
  String get lsSectionTitle => 'LocalSend 裝置';

  @override
  String get lsHintEnable => 'LocalSend 相容未開啟';

  @override
  String get lsHintEnableDesc =>
      '開啟後可與 LocalSend 官方客戶端（Android/iOS/Windows/macOS/Linux）互傳檔案';

  @override
  String get lsEnableNow => '開啟';

  @override
  String get lsEnabledSnack => '已開啟 LocalSend 相容';

  @override
  String get lsNoDevices => '未發現 LocalSend 裝置';

  @override
  String get lsHttpScan => 'HTTP 掃描';

  @override
  String get lsHttpScanning => '正在掃描區域網路（群播不通時的備援）...';

  @override
  String get lsHttpScanDone => '掃描完成';

  @override
  String get lsSendFile => '傳送檔案';

  @override
  String get lsSendFileDesc => '透過 LocalSend 協定傳送到該裝置';

  @override
  String get lsProbe => '重新探測';

  @override
  String get lsProbing => '正在探測...';

  @override
  String get lsProbeFound => '探測成功';

  @override
  String get lsProbeNotFound => '裝置無回應';

  @override
  String lsPickFailed(String error) {
    return '選擇檔案失敗：$error';
  }

  @override
  String get lsNoPath => '無法取得檔案路徑';

  @override
  String lsSendingTitle(String alias) {
    return '正在傳送到 $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '成功傳送 $count 個檔案';
  }

  @override
  String lsSendFailed(int count) {
    return '有 $count 個檔案傳送成功，其餘失敗';
  }

  @override
  String get lsReceiveRequestTitle => '接收檔案請求';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return '對方傳送了 $count 個檔案，共 $size';
  }

  @override
  String get lsAccept => '接受';

  @override
  String get lsReject => '拒絕';

  @override
  String get lsOpenFile => '開啟檔案';

  @override
  String get lsReceiveCompleteTitle => '檔案接收完成';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName 已儲存到：\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return '已接收檔案：$fileName';
  }

  @override
  String get netConnectivitySection => '連通性測試';

  @override
  String get netHostMappingSection => 'Host 對應';

  @override
  String get netMappingReset => '已恢復內建預設 IP 表';

  @override
  String get netRestoreDefaults => '恢復預設';

  @override
  String get netNoMappings => '暫無對應';

  @override
  String get netAddMapping => '新增對應';

  @override
  String get netDohQuerySection => 'DoH 查詢';

  @override
  String get netDohQueryDesc =>
      '透過 Cloudflare JSON DNS API 查詢網域名稱 A 紀錄，結果可一鍵儲存為 Host 對應';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => '儲存為對應';

  @override
  String get netHeadersSection => '請求標頭';

  @override
  String get netRefererNotSet => '未設定（範例：https://www.bilibili.com/）';

  @override
  String get netNotSet => '未設定';

  @override
  String netHeaderEditorTitle(String title) {
    return '設定 $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title 已儲存';
  }

  @override
  String get ossTitle => '開放原始碼授權';

  @override
  String get ossBackTooltip => '向上瀏覽';

  @override
  String get ossThanks => '致謝';

  @override
  String ossSummary(int count) {
    return '本項目以 Flutter 建置，共引用 $count 個開放原始碼項目，涵蓋 MIT、Apache-2.0 與 BSD-3-Clause 授權。點擊項目即可查看完整授權文字，感謝所有開放原始碼作者無私的貢獻。';
  }

  @override
  String ossGroupCount(String name, int count) {
    return '$name · $count 項';
  }

  @override
  String get ossCopyFullText => '複製全文';

  @override
  String get ossLicenseCopied => '授權文字已複製到剪貼簿';

  @override
  String get playHistoryTitle => '播放記錄';

  @override
  String get playHistoryBackTooltip => '向上瀏覽';

  @override
  String get playHistoryClearAll => '清空全部';

  @override
  String get playHistoryEmpty => '這裡空空的';

  @override
  String get playHistoryEmptySub => '嗯，今天真是寂寞如雪啊';

  @override
  String get playHistoryClearTitle => '清空播放記錄';

  @override
  String get playHistoryClearConfirm => '您確定要刪除所有已儲存的播放進度嗎？此操作無法復原。';

  @override
  String get playHistoryClearAction => '清空';

  @override
  String get playHistoryResume => '繼續播放';

  @override
  String get playHistoryDeleteRecord => '刪除記錄';

  @override
  String playHistoryDeleted(String title) {
    return '已刪除「$title」的播放記錄';
  }

  @override
  String get timeJustNow => '剛剛';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get playerArtistVideo => '影片播放';

  @override
  String get playerArtistPlaylist => '播放清單';

  @override
  String get playerArtistWebdav => 'WebDAV 影片';

  @override
  String get playerWebdavSubtitle => 'WebDAV 字幕';

  @override
  String playerResumeFrom(String position) {
    return '已從 $position 繼續播放';
  }

  @override
  String playerNowPlaying(String title) {
    return '正在播放：$title';
  }

  @override
  String playerDanmakuCache(int count) {
    return '彈幕快取（$count 條）';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili 彈幕（$count 條）';
  }

  @override
  String get playerDanmakuNoData => '未解析到彈幕資料';

  @override
  String playerDanmakuLoaded(int count) {
    return '已載入 $count 條彈幕';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili 在線彈幕（$count 條）';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return '已從本機快取載入 $count 條彈幕';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return '已載入 $count 條在線彈幕';
  }

  @override
  String playerScreenshotFailed(String error) {
    return '截圖失敗：$error';
  }

  @override
  String get playerSavedToAlbum => '已儲存到相簿';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return '截圖 $fileName 已儲存到相簿';
  }

  @override
  String playerSaveFailed(String error) {
    return '儲存失敗：$error';
  }

  @override
  String playerPipFailed(String error) {
    return '畫中畫呼叫失敗：$error';
  }

  @override
  String get playerFitAdapt => '適配';

  @override
  String get playerFitStretch => '拉伸';

  @override
  String get playerFitFill => '填滿';

  @override
  String get playerEndPause => '播完暫停';

  @override
  String get playerEndLoop => '循環播放';

  @override
  String get playerEndExit => '播完結束';

  @override
  String get playerSubtitleSettings => '字幕設定';

  @override
  String get playerAdvancedSettings => '進階設定';

  @override
  String get playerFlipHorizontal => '水平鏡像';

  @override
  String get playerFlipHorizontalDesc => '左右翻轉畫面';

  @override
  String get playerFlipVertical => '垂直翻轉';

  @override
  String get playerFlipVerticalDesc => '上下翻轉畫面';

  @override
  String get playerShowStats => '顯示影片統計資訊';

  @override
  String get playerShowStatsDesc => '編碼/解析度/碼率/幀率';

  @override
  String get playerAutoPip => '回到桌面自動畫中畫';

  @override
  String get playerLoadDanmakuOnResume => '恢復播放時載入彈幕';

  @override
  String get playerLoadDanmakuOnResumeDesc => '從播放記錄繼續時自動讀取/取得彈幕';

  @override
  String get playerDefaultRate => '預設播放速度';

  @override
  String get playerDefaultEndBehavior => '預設結束行為';

  @override
  String get playerBuffering => '緩衝中…';

  @override
  String get playerHwdecSoftware => '軟解（SW）';

  @override
  String playerHwdecHardware(String mode) {
    return '硬解（$mode）';
  }

  @override
  String get playerSourceLocal => '本機檔案';

  @override
  String get playerStatResolution => '解析度';

  @override
  String get playerStatVideoCodec => '影片編碼';

  @override
  String get playerStatAudioCodec => '音訊編碼';

  @override
  String get playerStatBitrate => '碼率';

  @override
  String get playerStatFps => '幀率';

  @override
  String get playerStatDecode => '解碼';

  @override
  String get playerStatSubtitle => '字幕';

  @override
  String get playerOn => '開啟';

  @override
  String get playerOff => '關閉';

  @override
  String get playerStatDanmaku => '彈幕';

  @override
  String get playerStatDownload => '下載';

  @override
  String get playerStatSource => '來源';

  @override
  String get playerStatPosition => '進度';

  @override
  String get playerStatDuration => '時長';

  @override
  String get playerCopyLink => '複製影片連結';

  @override
  String playerCopyLinkAt(String time) {
    return '複製空降連結（$time）';
  }

  @override
  String get playerCopyLinkAt0 => '複製空降連結';

  @override
  String playerCopyLinkDone(String url) {
    return '已複製：$url';
  }

  @override
  String get playerCopyLinkNotBili => '僅 B 站影片支援複製連結';

  @override
  String get playerColorAdjust => '影片色彩調整';

  @override
  String get playerColorBrightness => '亮度';

  @override
  String get playerColorContrast => '對比度';

  @override
  String get playerColorSaturation => '飽和度';

  @override
  String get playerColorHue => '色相';

  @override
  String get playerColorGamma => '伽馬';

  @override
  String get playerColorReset => '重設';

  @override
  String get playerColorUnavailable => '目前播放器不支援色彩調整';

  @override
  String get playerStats => '統計資訊';

  @override
  String get playerAlignAspectRatio => '對齊寬高比';

  @override
  String get playerAlignAspectRatioDone => '視窗已對齊影片比例';

  @override
  String get playerAlignAspectRatioFailed => '無法取得影片尺寸';

  @override
  String get commonClose => '關閉';

  @override
  String get playerPlaybackError => '播放錯誤';

  @override
  String playerAllEpisodesPlayed(int count) {
    return '已播放完全部 $count 集';
  }

  @override
  String playerFastForwarding(String rate) {
    return '$rate 倍速播放中';
  }

  @override
  String get playerTapToSave => '點我儲存';

  @override
  String get playerResetScreen => '還原螢幕';

  @override
  String get playerBackTooltip => '向上瀏覽';

  @override
  String get playerRotate90 => '旋轉90度';

  @override
  String get playerQuality => '畫質';

  @override
  String get playerQualityLocked => '該畫質不可用（需登入或大會員）';

  @override
  String get playerFullscreen => '全螢幕';

  @override
  String get playerBiliSubtitle => 'B站字幕';

  @override
  String get playerDecodeFormat => '解碼格式';

  @override
  String get playerDecodeFormatSwitchFailed => '切換解碼格式失敗';

  @override
  String get playerDecodeAuto => '自動';

  @override
  String get playerDecodeAutoShort => '自動';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => '字幕載入失敗';

  @override
  String get playerPortraitMode => '直屏模式';

  @override
  String get playerLandscapeMode => '橫屏模式';

  @override
  String get playerDescription => '簡介';

  @override
  String get playerWebdavSource => 'WebDAV 影片來源';

  @override
  String get playerCast => '投屏';

  @override
  String get playerWatchTogether => '一齊睇';

  @override
  String get watchInviteTitle => '邀請你一齊睇影片';

  @override
  String get watchWaitingAccept => '等待對方接受…';

  @override
  String get watchSelectPeer => '選擇一齊睇嘅好友';

  @override
  String get watchNoOnlinePeer => '沒有在線嘅聯絡人';

  @override
  String watchInviteSent(String name) {
    return '已發送一齊睇邀請畀 $name';
  }

  @override
  String watchActiveWith(String name) {
    return '正在同 $name 一齊睇';
  }

  @override
  String get watchPeerRejected => '對方拒絕咗你嘅邀請';

  @override
  String get watchPeerNoAnswer => '對方冇接受邀請';

  @override
  String get watchPeerLeft => '對方已退出一齊睇';

  @override
  String get watchTcpFailed => '無法建立連線，一齊睇失敗';

  @override
  String get watchConnectionDropped => '連線已中斷，一齊睇失敗';

  @override
  String get watchUrlInvalid => '影片地址不可用，無法發起一齊睇';

  @override
  String get rcInviteTitle => '請求遠端控制你的裝置';

  @override
  String get rcInviteHint => '同意後對方可以睇到你嘅螢幕並操作你嘅裝置';

  @override
  String get rcPeerRejected => '對方拒絕咗遠端控制請求';

  @override
  String get rcTcpFailed => '無法建立連線，遠端控制失敗';

  @override
  String get rcConnectionDropped => '連線已中斷，遠端控制失敗';

  @override
  String get rcTimeout => '等待對方回應超時';

  @override
  String get rcShizukuNotInstalled => '對方裝置未安裝 Shizuku';

  @override
  String get rcShizukuNotInstalledHint =>
      '被控端需要安裝並啟動 Shizuku 服務（shizuku.rikka.app）';

  @override
  String get rcShizukuGrantTitle => '需要 Shizuku 授權';

  @override
  String get rcShizukuGrantHint => '被控端授予 Navi Shizuku 權限後，對方先可以遠端操作螢幕';

  @override
  String get rcShizukuGrant => '授權 Shizuku';

  @override
  String get rcRequesting => '請求中…';

  @override
  String get rcShizukuNotGranted => 'Shizuku 未授權';

  @override
  String rcScreenCaptureFailed(String error) {
    return '螢幕擷取失敗：$error';
  }

  @override
  String get rcShareFailed => '螢幕分享失敗';

  @override
  String get rcRetry => '重試';

  @override
  String get rcClose => '關閉';

  @override
  String get rcCancel => '取消';

  @override
  String get rcSend => '傳送';

  @override
  String get rcConnecting => '正在連接…';

  @override
  String rcControlling(String name) {
    return '正在遠端控制 $name';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name 正在遠端控制你嘅裝置';
  }

  @override
  String get rcEnd => '結束遠端控制';

  @override
  String get rcConnectionLost => '遠端控制連線已中斷';

  @override
  String get rcSessionEnded => '遠端控制已結束';

  @override
  String get rcInputText => '輸入文字';

  @override
  String get rcInputTextHint => '要傳送到對方裝置上嘅文字';

  @override
  String get rcKeyBack => '返回';

  @override
  String get rcKeyHome => '主頁';

  @override
  String get rcKeyRecents => '最近工作';

  @override
  String get rcKeyVolumeUp => '音量+';

  @override
  String get rcKeyVolumeDown => '音量-';

  @override
  String get dlnaPageTitle => '投屏';

  @override
  String get dlnaRefresh => '重新搜尋';

  @override
  String get dlnaSearching => '正在搜尋區域網絡投屏裝置…';

  @override
  String get dlnaNoDevice => '未發現可投屏裝置';

  @override
  String get dlnaNoDeviceHint => '請確認電視/盒子與本機處於同一區域網絡，且已開啟 DLNA/投屏功能';

  @override
  String get dlnaSearchAgain => '重新搜尋';

  @override
  String get dlnaFoundDevices => '發現裝置';

  @override
  String dlnaCastStarted(String device) {
    return '已投屏到 $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return '投屏失敗：$device';
  }

  @override
  String dlnaCastingTo(String device) {
    return '正在投屏到 $device';
  }

  @override
  String get dlnaStopCast => '停止投屏';

  @override
  String get dlnaPlay => '播放';

  @override
  String get dlnaPause => '暫停';

  @override
  String get dlnaVolumeUp => '增大音量';

  @override
  String get dlnaVolumeDown => '減小音量';

  @override
  String get dlnaFileMissing => '影片檔案不存在';

  @override
  String dlnaServerStartFailed(String error) {
    return '本地檔案服務啟動失敗：$error';
  }

  @override
  String get playerEpisodeSelect => '選集';

  @override
  String get playerDanmakuSettings => '彈幕設定';

  @override
  String get psTitle => '播放器';

  @override
  String get psBackTooltip => '向上瀏覽';

  @override
  String get psStaffEntrance => '員工通道';

  @override
  String get psDisplaySection => '顯示';

  @override
  String get psStatusBar => '狀態列';

  @override
  String get psStatusBarDesc => '在播放器頂端顯示時間、電量與網絡圖示';

  @override
  String get psKeepWindowRatio => '等比例鎖定視窗';

  @override
  String get psKeepWindowRatioDesc => '播放時視窗僅允許按目前比例縮放';

  @override
  String get psKeepWindowRatioDesktopOnly => '僅 Windows / macOS / Linux 桌面平台生效';

  @override
  String get psInteractionSection => '互動';

  @override
  String get psLongPressSpeed => '長按加速';

  @override
  String get psLongPressSpeedDesc => '長按螢幕或鍵盤 D 鍵以 2× 倍速快轉';

  @override
  String get psScreenshot => '截圖功能';

  @override
  String get psScreenshotDesc => '允許在播放器中擷取目前畫面並儲存至相簿';

  @override
  String get psScreenshotDanmaku => '截圖時顯示彈幕';

  @override
  String get psScreenshotDanmakuDesc => '截圖時將目前彈幕一併擷入畫面';

  @override
  String get psProgressSection => '進度';

  @override
  String get psPlayProgress => '播放進度';

  @override
  String get psNoHistory => '暫無已儲存的播放記錄';

  @override
  String psHistoryCount(int count) {
    return '您有 $count 筆記錄';
  }

  @override
  String get psMiscSection => '其他';

  @override
  String get psHwdec => '硬體解碼';

  @override
  String get psHwdecAuto => '自動選擇最佳解碼器';

  @override
  String get psHwdecSoftware => '強制使用 CPU 軟體解碼';

  @override
  String get psHwdecAutoShort => '自動';

  @override
  String get psHwdecPureSoftware => '純軟解';

  @override
  String get psVideoSync => '影片同步';

  @override
  String get psVsyncAudioDefault => '以音訊時鐘為基準（預設）';

  @override
  String get psVsyncResample => '重新取樣音訊以符合顯示更新率';

  @override
  String get psVsyncAdrop => '丟棄 / 重複音訊影格以符合顯示';

  @override
  String get psVsyncVdrop => '丟棄 / 重複影片影格以符合顯示';

  @override
  String get psVsyncAudio => '音訊';

  @override
  String get psVsyncDisplayResample => '顯示重取樣';

  @override
  String get psVsyncDisplayAdrop => '顯示音訊丟棄';

  @override
  String get psVsyncDisplayVdrop => '顯示影片丟棄';

  @override
  String get psImmersiveLongPress => '沉浸模式長按加速';

  @override
  String get psImmersiveLongPressDesc => '控制列隱藏時仍可透過長按觸發 2× 倍速';

  @override
  String get psLogSection => '日誌';

  @override
  String get psMpvLog => '記錄 mpv 日誌';

  @override
  String psMpvLogEnabled(String level) {
    return '已開啟，下次播放生效（細度：$level）';
  }

  @override
  String get psMpvLogDisabled => '關閉。當機日誌始終記錄，不受此開關影響';

  @override
  String get psMpvLogLevel => 'mpv 日誌細度';

  @override
  String get psMpvLogLevelDesc => '細度越高日誌越詳細，佔用空間也越大';

  @override
  String get psMpvLogError => '僅錯誤';

  @override
  String get psMpvLogWarn => '警告';

  @override
  String get psMpvLogWarnDefault => '警告（預設）';

  @override
  String get psMpvLogInfo => '資訊';

  @override
  String get psMpvLogVerbose => '詳細';

  @override
  String get psMpvLogDebug => '偵錯';

  @override
  String get psMpvLogTrace => '全部（極詳細）';

  @override
  String get psViewLogs => '檢視日誌';

  @override
  String get psViewLogsDesc => '瀏覽錯誤日誌與 mpv 日誌，支援分享與清除';

  @override
  String testPlaylistCreated(String name) {
    return '已建立：$name';
  }

  @override
  String get testPageTitle => '測試頁';

  @override
  String get testVideoSourceSection => '影片來源';

  @override
  String get testVideoSourceSubtitle => '選擇一個來源開始播放';

  @override
  String get testWebdavVideo => 'WebDAV 影片';

  @override
  String get testWebdavVideoDesc => '從 WebDAV 伺服器瀏覽並播放';

  @override
  String get testLocalVideo => '本機影片';

  @override
  String get testLocalVideoDesc => '從裝置儲存空間選擇影片檔案';

  @override
  String get testRecentSection => '最近播放';

  @override
  String get testLastPlayedSubtitle => '上次播放記錄';

  @override
  String get testNoRecords => '暫無播放記錄';

  @override
  String get testPlaylistSection => '播放清單';

  @override
  String get testPlaylistSectionSubtitle => '建立、管理播放清單，選集播放';

  @override
  String get testPlaylistManage => '播放清單管理';

  @override
  String get testPlaylistManageDesc => '檢視 / 編輯 / 刪除播放清單，點擊直接播放';

  @override
  String get testPlaylistCreate => '新增播放清單';

  @override
  String get testPlaylistCreateDesc => 'WebDAV 多選檔案建表 / 手動逐集匯入';

  @override
  String get testQuickActionsSection => '快速操作';

  @override
  String get testQuickActionsSubtitle => '常用測試入口';

  @override
  String get testUrlDirectPlay => 'URL 直接播放';

  @override
  String get testUrlDirectPlayDesc => '輸入影片 URL 直接播放';

  @override
  String get testVideoWithSubtitle => '影片 + 字幕';

  @override
  String get testVideoWithSubtitleDesc => '同時選擇影片和字幕檔案';

  @override
  String get testNoVideoPlayed => '還沒有播放過任何影片';

  @override
  String get testEnterUrlTitle => '輸入影片 URL';

  @override
  String get testPlay => '播放';

  @override
  String get testAddSubtitleTitle => '新增字幕？';

  @override
  String testAddSubtitlePrompt(String name) {
    return '已選擇影片：$name\n是否要載入外掛字幕？';
  }

  @override
  String get testSkip => '略過';

  @override
  String get testSelectSubtitle => '選擇字幕';

  @override
  String get testAboutLegalese => '播放器前端測試頁面';

  @override
  String get testAboutBody =>
      '此頁面用於測試 MpvPlayerPage 的各種入口：\n• WebDAV 遠端影片\n• 本機影片檔案\n• URL 直接播放\n• 影片 + 外掛字幕';

  @override
  String get testSourceLocal => '本機檔案';

  @override
  String get testSourceLocalSubtitle => '本機 + 字幕';

  @override
  String get accountsBiliLoginSuccess => 'B 站登入成功';

  @override
  String get accountsBiliLogoutTitle => '登出 B 站？';

  @override
  String get accountsBiliLogoutHint => '登出後將不再攜帶 Cookie 請求 B 站 API。';

  @override
  String get accountsClearWebviewCookieTitle => '同時清除內置瀏覽器 Cookie';

  @override
  String get accountsClearWebviewCookieSubtitle => '不勾選也沒關係，之後可在帳號設定中手動清除';

  @override
  String get accountsLogout => '登出';

  @override
  String get accountsLoggedOutWithCookie => '已登出並清除瀏覽器 Cookie';

  @override
  String get accountsLoggedOut => '已登出';

  @override
  String get accountsClearCookieTitle => '清除內置瀏覽器 Cookie？';

  @override
  String get accountsClearCookieContent => '將清除內置瀏覽器儲存的所有 Cookie，包括網頁端的登入狀態。';

  @override
  String get accountsClearAction => '清除';

  @override
  String get accountsCookieCleared => '已清除內置瀏覽器 Cookie';

  @override
  String get accountsCookieEmpty => '暫無內置瀏覽器 Cookie 可清除（瀏覽器未使用過）';

  @override
  String get accountsBiliLoginTitle => '登入 B 站帳號';

  @override
  String get accountsBiliLoginSubtitle => '掃碼 / 貼上 Cookie / 密碼登入';

  @override
  String get accountsClearBrowserCookie => '清除內置瀏覽器 Cookie';

  @override
  String get accountsClearBrowserCookieSubtitle => '清除網頁端殘留登入狀態';

  @override
  String get accountsLoggedIn => '已登入';

  @override
  String accountsLoggedInUid(int mid) {
    return '已登入 · UID $mid';
  }

  @override
  String get accountsCarryCookie => '攜帶 Cookie 請求';

  @override
  String get accountsCarryCookieOn => '已開啟：B 站 API 以登入身份請求';

  @override
  String get accountsCarryCookieOff => '已關閉：B 站 API 以訪客身份請求';

  @override
  String get accountsCookieScope => 'Cookie 使用範圍';

  @override
  String get accountsCookieScopeSubtitle => '選擇哪些請求使用帳號 Cookie';

  @override
  String get cookieScopeTitle => 'Cookie 使用範圍';

  @override
  String get cookieScopeHint =>
      '僅影響以下請求類型；「攜帶 Cookie 請求」總開關關閉時，下列設定不生效。B 站在線收藏夾操作始終攜帶登入 Cookie。';

  @override
  String get cookieScopeVideo => '影片詳情與播放';

  @override
  String get cookieScopeVideoDesc => '影片詳情、播放位址與歷史進度回報';

  @override
  String get cookieScopeComments => '評論';

  @override
  String get cookieScopeCommentsDesc => '評論區列表請求';

  @override
  String get cookieScopeSearch => '搜尋';

  @override
  String get cookieScopeSearchDesc => '搜尋建議與搜尋結果請求';

  @override
  String get cookieScopeArticle => '專欄與動態';

  @override
  String get cookieScopeArticleDesc => '專欄文章與動態內容請求';

  @override
  String get cookieScopeUserSpace => '使用者空間';

  @override
  String get cookieScopeUserSpaceDesc => 'UP 主空間、投稿與粉絲列表請求';

  @override
  String get cookieScopeSeason => '番劇與劇集';

  @override
  String get cookieScopeSeasonDesc => '番劇詳情與劇集列表請求';

  @override
  String get cookieScopeInteractions => '互動操作';

  @override
  String get cookieScopeInteractionsDesc => '按讚、投幣、收藏、追蹤、發送彈幕等；關閉後無法互動';

  @override
  String get cookieScopeEnableAll => '全部開啟';

  @override
  String get cookieScopeDisableAll => '全部關閉';

  @override
  String get accountsWebdavCloud => 'WebDAV 雲端硬碟';

  @override
  String get accountsWebdavConfiguredOn => '已設定 · 自動備份已開啟';

  @override
  String get accountsWebdavConfiguredOff => '已設定 · 自動備份未開啟';

  @override
  String get accountsWebdavNotConfigured => '未設定 · 點擊進入設定';

  @override
  String get accountsTitle => '帳號';

  @override
  String get accountsSectionBili => 'B 站帳號';

  @override
  String get commonBackTooltip => '向上瀏覽';

  @override
  String get biliLoginFetchingQr => '正在取得 QR Code…';

  @override
  String get biliLoginQrFetchFailed => '取得 QR Code 失敗，請檢查網絡';

  @override
  String get biliLoginScanWithApp => '請使用 B 站 App 掃碼登入';

  @override
  String get biliLoginInputAccountPwd => '請輸入帳號和密碼';

  @override
  String get biliLoginFailedRetry => '登入失敗，請重試';

  @override
  String get biliLoginTitle => 'B 站登入';

  @override
  String get biliLoginScanMode => '掃碼登入';

  @override
  String get biliLoginCookieMode => '貼上 Cookie';

  @override
  String get biliLoginPwdMode => '密碼登入';

  @override
  String get biliLoginViaBrowser => '使用內置瀏覽器登入';

  @override
  String get biliLoginCookieHint => '登入後「攜帶 Cookie 請求」預設開啟，可在 設定 → 帳號 中關閉';

  @override
  String get biliLoginWebTitle => '網頁版登入';

  @override
  String get biliLoginCookieImportFailed => '網頁登入 Cookie 匯入失敗，請重試或改用其他方式';

  @override
  String get biliLoginRefetch => '重新取得';

  @override
  String get biliLoginRefreshQr => '重新整理 QR Code';

  @override
  String get biliLoginScanTip => '提示：開啟 B 站 App → 掃一掃，或使用「嗶哩嗶哩」小程式掃碼';

  @override
  String get biliLoginCookieInstruction =>
      '在電腦瀏覽器登入 bilibili.com，按 F12 開啟開發者工具 → Application → Cookies → bilibili.com，複製全部 Cookie（以 SESSDATA= 開頭的一串），貼到下方輸入框';

  @override
  String get biliLoginVerifying => '驗證中…';

  @override
  String get biliLoginVerifyAndLogin => '登入並驗證';

  @override
  String get biliLoginAccountLabel => '帳號（手機號碼 / 信箱 / 用戶名稱）';

  @override
  String get biliLoginPasswordLabel => '密碼';

  @override
  String get biliLoginLoggingIn => '登入中…';

  @override
  String get biliLoginLoginAction => '登入';

  @override
  String get biliLoginSliderHint => '帳號密碼登入可能觸發滑塊驗證碼，完成驗證後會自動重試';

  @override
  String get searchFilterAny => '不限';

  @override
  String get searchFilterLastDay => '最近一天';

  @override
  String get searchFilterLastWeek => '最近一週';

  @override
  String get searchFilterHalfYear => '最近半年';

  @override
  String get searchFilterAllDuration => '全部時長';

  @override
  String get searchFilterDur0to10 => '0-10 分鐘';

  @override
  String get searchFilterDur10to30 => '10-30 分鐘';

  @override
  String get searchFilterDur30to60 => '30-60 分鐘';

  @override
  String get searchFilterDur60plus => '60 分鐘以上';

  @override
  String get searchZoneAll => '全部';

  @override
  String get searchZoneAnime => '動畫';

  @override
  String get searchZoneGuochuang => '國創';

  @override
  String get searchZoneMusic => '音樂';

  @override
  String get searchZoneDance => '舞蹈';

  @override
  String get searchZoneGame => '遊戲';

  @override
  String get searchZoneKnowledge => '知識';

  @override
  String get searchZoneTech => '科技';

  @override
  String get searchZoneSports => '運動';

  @override
  String get searchZoneCar => '汽車';

  @override
  String get searchZoneLife => '生活';

  @override
  String get searchZoneFood => '美食';

  @override
  String get searchZoneAnimal => '動物';

  @override
  String get searchZoneKichiku => '鬼畜';

  @override
  String get searchZoneFashion => '時尚';

  @override
  String get searchZoneInfo => '資訊';

  @override
  String get searchZoneEnt => '娛樂';

  @override
  String get searchZoneDoc => '紀錄';

  @override
  String get searchZoneFilm => '電影';

  @override
  String get searchZoneTv => '電視';

  @override
  String get searchCaptchaInitFailed => '驗證碼初始化失敗';

  @override
  String get searchCaptchaIncomplete => '未完成滑塊驗證';

  @override
  String get searchCaptchaValidateFailed => '驗證碼校驗失敗';

  @override
  String get searchCaptchaValidateFailedRetry => '驗證碼校驗失敗，請重試';

  @override
  String get searchCaptchaPassed => '驗證通過，正在重新搜尋';

  @override
  String get searchBiliHint => '搜尋 B 站…';

  @override
  String get searchHistoryTitle => '搜尋歷史';

  @override
  String get searchHistoryClear => '清空';

  @override
  String get searchHistoryClearConfirm => '確定清空目前分區的搜尋歷史？';

  @override
  String get searchHistoryEmpty => '暫無搜尋歷史';

  @override
  String get searchVideoFilter => '影片搜尋篩選';

  @override
  String searchFilterWithCount(int count) {
    return '篩選 · $count';
  }

  @override
  String get searchFilter => '篩選';

  @override
  String get searchSwitchSingleCol => '單欄';

  @override
  String get searchSwitchMulti => '多欄';

  @override
  String get searchLayoutMulti => '多欄';

  @override
  String get searchLayoutSingle => '單欄';

  @override
  String get searchPickStartDate => '選擇開始日期';

  @override
  String get searchPickEndDate => '選擇結束日期';

  @override
  String get searchPubTimeSection => '發佈時間';

  @override
  String get searchDateBegin => '開始';

  @override
  String get searchDateTo => '至';

  @override
  String get searchDateEnd => '結束';

  @override
  String get searchDurationSection => '內容時長';

  @override
  String get searchZoneSection => '內容分區';

  @override
  String get searchAntiFuzzy => '防模糊搜尋';

  @override
  String get searchAntiFuzzyHint => '限定 2009-06-26 至今的結果，避免異常早期數據干擾';

  @override
  String get searchFilterReset => '重設';

  @override
  String get searchAllLoaded => '— 已全部載入 —';

  @override
  String get searchKeywordHint => '輸入關鍵字搜尋 B 站';

  @override
  String get searchPressToSearch => '點擊「搜尋」或按 Enter 開始搜尋';

  @override
  String searchNoResultInType(String keyword, String type) {
    return '「$keyword」在$type中暫無結果';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · 共 $count 個結果';
  }

  @override
  String get userSpaceLoadFailed => '載入失敗';

  @override
  String get userSpaceAvatarLoadFailed => '頭像載入失敗';

  @override
  String get userSpaceTitle => 'UP 主空間';

  @override
  String get userSpaceLoading => '正在載入 UP 主空間…';

  @override
  String get userSpaceLoadingName => '載入中…';

  @override
  String get userSpaceStatFans => '粉絲';

  @override
  String get userSpaceStatFollowing => '關注';

  @override
  String get userSpaceStatVideos => '影片';

  @override
  String get userSpaceStatLikes => '獲讚';

  @override
  String userSpaceVideoCount(int count) {
    return '共 $count 部影片';
  }

  @override
  String get userSpaceSectionAllVideos => '全部影片';

  @override
  String get userSpaceNoVideos => '暫無投稿';

  @override
  String get userSpaceDynLoadFailed => '動態載入失敗';

  @override
  String get userSpaceNoDynamics => '暫無動態';

  @override
  String get userSpaceBangumiLoadFailed => '追番清單載入失敗';

  @override
  String get userSpaceNoBangumi => '暫無追番';

  @override
  String userSpaceBangumiCount(int count) {
    return '追番 · 共 $count 部';
  }

  @override
  String get userSpaceLazySign => '這個人很懶，什麼都沒有留下';

  @override
  String get userSpaceTabHome => '主頁';

  @override
  String get userSpaceTabDynamic => '動態';

  @override
  String get userSpaceTabBangumi => '追番';

  @override
  String get userSpaceToday => '今天';

  @override
  String get userSpaceBangumiFinished => '完結';

  @override
  String get userSpaceBangumiSerializing => '連載中';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return '開播 $date';
  }

  @override
  String get browserApp => '應用程式';

  @override
  String browserOpenAppAttempt(String app) {
    return '網頁嘗試開啟: $app';
  }

  @override
  String get browserNoAppForLink => '找不到可開啟此連結的應用程式';

  @override
  String get browserOpenFailedSystem => '開啟失敗: 未安裝對應應用程式或受系統限制';

  @override
  String get browserEmptyCookieHint => '這裡空空的';

  @override
  String get browserCopyAll => '複製全部';

  @override
  String get browserCookieCopied => 'Cookie 已複製';

  @override
  String get browserCookieEmpty => 'Cookie 空空如也';

  @override
  String get browserSetUaTitle => '設定 User-Agent';

  @override
  String get browserUaHint => '輸入自訂 User-Agent';

  @override
  String get browserApplyAndReload => '套用並重新整理';

  @override
  String get browserUaUpdated => 'UA 已更新並重新整理頁面';

  @override
  String browserUaSetFailed(String error) {
    return '設定 UA 失敗: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView 初始化失敗，請檢查是否已安裝 WebView2';

  @override
  String get browserBiliCookieReadFailed =>
      '無法讀取完整的登入 Cookie（SESSDATA 為 HttpOnly，目前平台無法自動讀取），請改用掃碼登入或貼上 Cookie';

  @override
  String get browserCookieImportFailed => 'Cookie 匯入失敗，請重試';

  @override
  String get browserStoppedLoading => '已停止載入';

  @override
  String get browserClipboardAllowed => '已允許網頁寫入剪貼簿';

  @override
  String get browserClipboardBlocked => '已禁止網頁自動寫入剪貼簿';

  @override
  String get browserNoCurrentUrl => '無法取得目前連結';

  @override
  String get browserTroubleshootFailed => '開啟失敗，請檢查「取得說明」是否存在';

  @override
  String get browserSystemBrowserMissing => '系統瀏覽器不見了(';

  @override
  String get browserQrTitle => '掃我';

  @override
  String get browserSaveToDevice => '儲存到裝置';

  @override
  String get browserQrSaved => 'QR Code 已儲存到相簿/圖片庫';

  @override
  String browserSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get browserStopLoading => '停止載入';

  @override
  String get browserImporting => '匯入中…';

  @override
  String get browserLoginDoneImport => '登入完成，匯入';

  @override
  String get browserClipboardAccess => '剪貼簿存取';

  @override
  String get browserShareQr => '分享 QR Code';

  @override
  String get browserCopyLink => '複製連結';

  @override
  String get browserViewCookies => '檢視 Cookies';

  @override
  String get browserSetUa => '設定 UA';

  @override
  String get browserUaModeAuto => '自動（跟隨系統）';

  @override
  String get browserUaModeDesktop => '電腦端';

  @override
  String get browserUaModeMobile => '手機端';

  @override
  String get browserRefresh => '重新整理';

  @override
  String get browserSystemBrowser => '系統瀏覽器';

  @override
  String get browserTroubleshootNetwork => '偵測連線問題';

  @override
  String get browserUnsupportedPlatform => '目前平台不支援內置瀏覽器';

  @override
  String get browserOpenedInSystem => '已嘗試在系統瀏覽器中開啟';

  @override
  String get browserReopenInSystem => '重新用系統瀏覽器開啟';

  @override
  String get browserAndroidErrorTitle => '沒有指令';

  @override
  String get browserAndroidErrorCause => '原因';

  @override
  String get browserAndroidErrorDetail =>
      'WebView 元件初始化失敗\n可能是系統 WebView 未更新或已停用';

  @override
  String get browserUpdateWebview => '前往 Google Play 更新 Android System WebView';

  @override
  String get browserOpenDevOptions => '開啟開發者選項檢視 WebView 實作';

  @override
  String get browserAppleErrorTitle => '應用程式未預期的結束';

  @override
  String get browserAppleErrorReport => '問題報告';

  @override
  String get browserAppleErrorDetail => '無法在此裝置上初始化內嵌瀏覽器。請確認作業系統已更新至最新版本。';

  @override
  String get browserBsodMessage =>
      '你的 Webview2 發生問題，我們需要收集一些錯誤資訊，然後為你重新啟動應用程式。';

  @override
  String get browserBsodNoRestart => '（其實不用重新啟動，安裝完元件即可）';

  @override
  String get browserBsodComplete => '100% 完成';

  @override
  String get browserBsodSolutions => '檢視解決方案：';

  @override
  String get browserBsodDownload => '下載 Webview2 執行階段';

  @override
  String get browserBsodWinUpdate => '開啟 Windows 更新設定';

  @override
  String get browserBsodScanQr => '掃描此 QR Code 取得解決方案';

  @override
  String get browserBsodStopCode => '終止代碼：WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => '無法開啟外部連結';

  @override
  String get callOutgoing => '正在撥打...';

  @override
  String get callIncoming => '來電...';

  @override
  String get callConnecting => '連線中...';

  @override
  String get chatConnectionNotEstablishedImage => '連線未建立，無法傳送圖片';

  @override
  String get chatImageSent => '✅ 圖片已傳送';

  @override
  String get chatImageSendFailed => '傳送圖片失敗';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return '處理剪貼簿圖片失敗：$error';
  }

  @override
  String get chatImageStaged => '🖼️ 圖片已加入輸入框';

  @override
  String get chatClipboardNoImage => '剪貼簿沒有圖片資料';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return '取得剪貼簿圖片失敗：$error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported => '剪貼簿為空或格式不支援';

  @override
  String get chatConnectionNotEstablishedFile => '連線未建立，無法傳送檔案';

  @override
  String get chatFileNotExist => '檔案不存在';

  @override
  String get chatFileSendFailed => '傳送檔案失敗';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName 傳送成功';
  }

  @override
  String chatFileSendError(String error) {
    return '傳送檔案失敗：$error';
  }

  @override
  String get chatIpUnknown => 'IP 未知';

  @override
  String get chatReconnecting => '正在重新建立連線...';

  @override
  String get chatReconnectFailed => '重新連線失敗，請檢查網絡或對方是否在線';

  @override
  String get chatStatusUnknown => '狀態未知';

  @override
  String get chatStatusWaiting => '等待連線';

  @override
  String get chatMe => '我';

  @override
  String get chatFileInfoLost => '（檔案資訊遺失）';

  @override
  String chatOpenFileFailed(String message) {
    return '無法開啟檔案：$message';
  }

  @override
  String get chatFileNotDownloaded => '檔案尚未下載';

  @override
  String chatOpenFileError(String error) {
    return '開啟檔案失敗：$error';
  }

  @override
  String get chatFilePathUnavailable => '無法取得檔案路徑（Android 權限限制？）';

  @override
  String chatPickFileFailed(String error) {
    return '選擇檔案失敗：$error';
  }

  @override
  String get chatImagePathUnavailable => '無法取得圖片路徑';

  @override
  String chatPickImageFailed(String error) {
    return '選擇圖片失敗：$error';
  }

  @override
  String get chatCopyText => '複製文字';

  @override
  String get chatSelectText => '選取文字';

  @override
  String get chatOpenFile => '開啟檔案';

  @override
  String get chatCopyImage => '複製圖片';

  @override
  String get chatSaveImage => '儲存圖片';

  @override
  String get chatCopyingImage => '正在複製圖片...';

  @override
  String get chatImageCopied => '✅ 圖片已複製到剪貼簿';

  @override
  String get chatCopyFailed => '複製失敗';

  @override
  String chatCopyImageFailed(String error) {
    return '複製圖片失敗: $error';
  }

  @override
  String get chatSaving => '正在儲存...';

  @override
  String get chatSaveSuccess => '✅ 儲存成功';

  @override
  String chatSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get chatMessageContent => '訊息內容';

  @override
  String get chatEmptyContent => '（這裡空空的）';

  @override
  String get chatDeleteMessageConfirm => '確定要刪除這則訊息嗎？';

  @override
  String get chatMessageDeleted => '訊息已刪除';

  @override
  String get chatOpenLinkTitle => '開啟連結';

  @override
  String chatWillOpen(String url) {
    return '將開啟：$url';
  }

  @override
  String get chatBrowserTitle => '內置網頁瀏覽器';

  @override
  String get chatCantOpenLink => '無法開啟連結';

  @override
  String chatOpenLinkFailed(String error) {
    return '開啟連結失敗：$error';
  }

  @override
  String get chatPlusImage => '圖片';

  @override
  String get chatPlusFile => '檔案';

  @override
  String get chatImageReady => '圖片已就緒';

  @override
  String get chatMore => '更多';

  @override
  String get chatPasteImage => '貼上圖片';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get chatEmoji => '表情符號';

  @override
  String get chatSend => '傳送';

  @override
  String get chatInvalidAddress => '連線地址無效，無法傳送';

  @override
  String get chatImageSendError => '圖片傳送失敗';

  @override
  String chatSendFailed(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get chatConnStatusUnknown => '連線狀態未知，無法傳送訊息';

  @override
  String get chatPendingCannotSend => '等待對方驗證，無法傳送訊息';

  @override
  String get chatConnRejected => '連線已被拒絕';

  @override
  String get chatConnDisconnected => '對方已中斷連線';

  @override
  String get chatConnNotEstablished => '連線尚未建立，無法傳送訊息';

  @override
  String get chatNoMessages => '暫無訊息，開始聊天吧';

  @override
  String get chatDisconnectedRetry => '連線已中斷，點擊嘗試重新連線';

  @override
  String get chatRejectedRetry => '連線被拒絕，點擊重試';

  @override
  String get chatExpandInput => '展開輸入欄';

  @override
  String get discoverMyLanIps => '我的區域網絡 IP';

  @override
  String get discoverNoIpOfType => '找不到此類型的有效 IP，請檢查網絡連線。';

  @override
  String discoverIpCopied(String ip) {
    return '已複製 $ip';
  }

  @override
  String get discoverTitle => '發現附近裝置';

  @override
  String get discoverMyIp => '我的 IP';

  @override
  String get discoverRefreshBroadcast => '重新整理/廣播';

  @override
  String get discoverLanDevices => '區域網絡裝置';

  @override
  String get discoverSearching => '正在尋找附近的裝置...';

  @override
  String get discoverSendRequest => '點擊傳送連線請求';

  @override
  String get discoverPendingVerify => '等待對方驗證...';

  @override
  String get discoverRejectedRetry => '已被拒絕，點擊重試';

  @override
  String get discoverDisconnectedRetry => '已中斷，點擊重新連線';

  @override
  String get discoverUnknownDevice => '未知裝置';

  @override
  String get discoverAlreadyConnected => '此裝置已連線';

  @override
  String get discoverAlreadyPending => '正在等待對方驗證，請勿重複傳送';

  @override
  String get discoverConnectFailed => '連線失敗，請檢查網絡或對方是否在線';

  @override
  String get discoverManualConnect => '手動連線到對等端';

  @override
  String get discoverConnectIpHint => '輸入 IP 地址（例如：192.168.1.100 / fe80::1）';

  @override
  String get displayScaleCompact => '緊湊模式 · 顯示更多內容';

  @override
  String get displayScaleSmall => '略小 · 適合大螢幕';

  @override
  String get displayScaleDefault => '預設';

  @override
  String get displayScaleLarge => '略大 · 更容易閱讀';

  @override
  String get displayScaleLargeFont => '大字體 · 無障礙友善';

  @override
  String get displayScaleHuge => '超大 · 輔助功能';

  @override
  String get displayScaleMin => '最小 · 資訊密度最高';

  @override
  String get displayScaleCompactBig => '緊湊 · 適合大螢幕';

  @override
  String get displayScaleSystemDefault => '系統預設';

  @override
  String get displayScaleLargeFontShort => '大字體 · 無障礙';

  @override
  String get displayScaleTitle => '顯示縮放';

  @override
  String get displayHeroTransitionBlur => '使用新版動畫';

  @override
  String get displayIosPushTransition => 'iOS 風格頁面切換';

  @override
  String get displayIosPushTransitionCorner => '轉場圓角';

  @override
  String get searchIosPushTransition => 'iOS 頁面切換動畫';

  @override
  String get pageBgTitle => '頁面背景圖';

  @override
  String get pageBgSubtitle => '設定類頁面共用的背景圖，選擇後可裁剪';

  @override
  String get pageBgEnabled => '顯示頁面背景圖';

  @override
  String get pageBgOpacity => '背景強度';

  @override
  String get pageBgBlur => '背景模糊';

  @override
  String get pageBgNotSet => '未設置';

  @override
  String get pageBgPick => '選擇並裁剪圖片';

  @override
  String get pageBgClear => '清除背景圖';

  @override
  String get pageBgSaved => '背景圖已更新';

  @override
  String get pageBgCleared => '背景圖已清除';

  @override
  String get pageBgPickFailed => '選擇圖片失敗';

  @override
  String get cropTitle => '裁剪背景圖';

  @override
  String get cropAspectFree => '自由';

  @override
  String get cropApply => '應用';

  @override
  String get cropReset => '重置';

  @override
  String get displayAdvancedGlass => '高級渲染';

  @override
  String get displayDisableLiquidGlassMenus => '減弱效果';

  @override
  String get displayLiquidGlassTuner => '液態玻璃調校';

  @override
  String get displayLiquidGlassTunerSubtitle => '調整玻璃厚度、模糊、著色、折射率等材質參數';

  @override
  String get lgTunerPreview => '即時預覽';

  @override
  String get lgTunerSectionMaterial => '材質參數';

  @override
  String get lgTunerThickness => '玻璃厚度';

  @override
  String get lgTunerBlur => '背景模糊';

  @override
  String get lgTunerTint => '著色強度';

  @override
  String get lgTunerSaturation => '飽和度';

  @override
  String get lgTunerRefractiveIndex => '折射率';

  @override
  String get lgTunerLightIntensity => '高光強度';

  @override
  String get lgTunerAmbient => '環境光';

  @override
  String get lgTunerLightAngle => '光源角度';

  @override
  String get lgTunerAberration => '色散';

  @override
  String get lgTunerReset => '恢復預設';

  @override
  String get lgTunerNote =>
      '調整即時生效並全域套用：未單獨指定參數的玻璃表面（下拉選單、彈窗等）都會跟隨；聊天頁頂欄等顯式設定的表面保持獨立樣式。';

  @override
  String get lgTunerFallbackNote =>
      '目前平台不支援進階玻璃渲染（Impeller），預覽為 FakeGlass 效果；厚度、折射率、飽和度等參數僅行動端生效。';

  @override
  String get displayScaleReset => '重設為 100%';

  @override
  String get displayScaleFineTune => '精細調整';

  @override
  String get displayScalePresets => '快捷預設';

  @override
  String get displayScaleNote =>
      '縮放比例會全域套用於文字與部分版面尺寸。設為 100% 可恢復預設。修改立即生效，無需重新啟動。';

  @override
  String displayScaleConnCount(int count) {
    return '$count 個連線';
  }

  @override
  String get displayThemeLight => '淺色';

  @override
  String get displayThemeDark => '深色';

  @override
  String get displaySettingsTitle => '顯示';

  @override
  String get displaySectionAppearance => '外觀';

  @override
  String get displayThemeMode => '主題模式';

  @override
  String get displayPureBlack => '純黑深色模式';

  @override
  String get displayPureBlackOn => '深色模式（已黑化）';

  @override
  String get displayOff => '已關閉';

  @override
  String get displaySectionPersonalize => '個人化';

  @override
  String get displayThemeColor => '主題配色';

  @override
  String get displayFollowSystemColor => '跟隨系統配色';

  @override
  String get displayFontWeight => '文字粗細';

  @override
  String get displaySeedDefaultGreen => '預設綠';

  @override
  String get displaySeedPink => '粉紅色';

  @override
  String get displaySeedRed => '紅色';

  @override
  String get displaySeedOrange => '橙色';

  @override
  String get displaySeedAmber => '琥珀色';

  @override
  String get displaySeedYellow => '黃色';

  @override
  String get displaySeedLime => '酸橙色';

  @override
  String get displaySeedLightGreen => '淺綠色';

  @override
  String get displaySeedGreen => '綠色';

  @override
  String get displaySeedCyan => '青色';

  @override
  String get displaySeedTeal => '藍綠色';

  @override
  String get displaySeedLightBlue => '淺藍色';

  @override
  String get displaySeedBlue => '藍色';

  @override
  String get displaySeedIndigo => '靛藍色';

  @override
  String get displaySeedPurple => '紫色';

  @override
  String get displaySeedDeepPurple => '深紫色';

  @override
  String get displaySeedBlueGrey => '藍灰色';

  @override
  String get displaySeedBrown => '棕色';

  @override
  String get displaySeedGrey => '灰色';

  @override
  String get displaySeedCustom => '自訂';

  @override
  String displayWeightThin(int weight) {
    return '極細 ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return '細 ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return '標準 ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return '中等 ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return '粗 ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return '極粗 ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return '自訂 ($weight)';
  }

  @override
  String get fontWeightThin => '極細';

  @override
  String get fontWeightLight => '細';

  @override
  String get fontWeightRegular => '標準';

  @override
  String get fontWeightMedium => '中等';

  @override
  String get fontWeightBold => '粗';

  @override
  String get fontWeightBlack => '極粗';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\n敏捷的棕色狐狸跳過懶惰的狗。';

  @override
  String get fontWeightSaveApply => '儲存並套用';

  @override
  String get geetestTitle => '完成滑塊驗證';

  @override
  String get geetestInitFailed => '驗證碼元件初始化失敗，請重試或改用其他登入方式';

  @override
  String get geetestUnsupported => '目前平台不支援內置驗證碼，請使用掃碼或 Cookie 登入';

  @override
  String get slicerPickImageFirst => '請先選擇圖片';

  @override
  String get slicerRowColInvalid => '行數與列數必須大於 0';

  @override
  String get slicerSuccess => '切割成功，已加入開始畫面';

  @override
  String slicerSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get slicerTitle => '圖片切割磁貼';

  @override
  String get slicerTileSize => '磁貼尺寸（所有碎片皆相同）';

  @override
  String get slicerColsLabel => '列數 (Cols)';

  @override
  String get slicerRowsLabel => '行數 (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return '預覽：將切割為 $count 個 $type 磁貼';
  }

  @override
  String get slicerProcessing => '處理中...';

  @override
  String get slicerSaveToStart => '儲存到開始畫面';

  @override
  String get viewerSaving => '正在儲存...';

  @override
  String get viewerSaveSuccess => '儲存成功';

  @override
  String viewerSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get viewerShareImage => '分享圖片';

  @override
  String viewerShareFailed(String error) {
    return '分享失敗: $error';
  }

  @override
  String get viewerCopying => '正在複製...';

  @override
  String viewerCopyFailed(String error) {
    return '複製失敗: $error';
  }

  @override
  String get viewerSaveToAlbum => '儲存到相簿';

  @override
  String get viewerCopyToClipboard => '複製到剪貼簿';

  @override
  String get viewerImageLoadFailed => '圖片載入失敗';

  @override
  String get viewerImageDataNotFound => '找不到圖片資料';

  @override
  String get userSpaceMidInvalid => 'mid 無效';

  @override
  String get userSpaceNoCard => '回應缺少 card';

  @override
  String get userSpaceNoList => '回應缺少 list';

  @override
  String get searchTypeVideo => '影片';

  @override
  String get searchTypeBangumi => '番劇';

  @override
  String get searchTypeFt => '影視';

  @override
  String get searchTypeLive => '直播間';

  @override
  String get searchTypeUser => '用戶';

  @override
  String get searchTypeArticle => '專欄';

  @override
  String get tenThousandUnit => '萬';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play播放 · $danmaku彈幕';
  }

  @override
  String searchScore(String score) {
    return '評分 $score';
  }

  @override
  String searchOnline(String count) {
    return '$count人在線';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans粉絲 · $videos影片';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views閱讀 · $replies評論';
  }

  @override
  String get searchBadgeCourse => '課堂';

  @override
  String get searchBadgeLive => '直播';

  @override
  String get searchBadgeCoop => '合作';

  @override
  String get searchBadgeLiveNow => '直播中';

  @override
  String get searchKeywordEmpty => '關鍵詞為空';

  @override
  String get searchBadResponse => '回應格式異常';

  @override
  String get searchFailed => '搜尋失敗';

  @override
  String get searchGaiaParamMissing => 'gaia register 參數缺失';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register 異常: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate 未通過 (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate 異常: $error';
  }

  @override
  String get commentOidEmpty => 'oid 為空';

  @override
  String commentException(String error) {
    return '異常: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return '樓中樓 HTTP $code';
  }

  @override
  String get commentSubNoData => '樓中樓回應缺少 data';

  @override
  String commentSubException(String error) {
    return '樓中樓異常: $error';
  }

  @override
  String get commentNotLoggedIn => '未登入或未開啟「攜帶 Cookie 請求」';

  @override
  String get commentMissingJct => 'Cookie 缺少 bili_jct，請重新登入';

  @override
  String commentNetworkError(String error) {
    return '網絡異常: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message（code=$code）';
  }

  @override
  String get deviceOs => '作業系統';

  @override
  String get deviceBuild => '內部建置編號';

  @override
  String get deviceSecurityPatch => '安全性修補程式';

  @override
  String get deviceOem => 'OEM 廠商';

  @override
  String get deviceBrand => '品牌';

  @override
  String get deviceModel => '型號';

  @override
  String get deviceRomVersion => 'ROM/顯示版本';

  @override
  String get deviceFingerprint => '裝置指紋';

  @override
  String get deviceName => '裝置名稱';

  @override
  String get deviceComputerName => '電腦名稱';

  @override
  String get deviceHardwareModel => '硬件型號';

  @override
  String get deviceKernel => '核心版本';

  @override
  String get deviceDistro => '發行版';

  @override
  String get deviceVersion => '版本';

  @override
  String get devicePlatform => '平台';

  @override
  String deviceInfoFailed(String error) {
    return '取得資訊失敗: $error';
  }

  @override
  String get logWebUnsupported => '（Web 不支援檔案日誌）';

  @override
  String get logNotInitialized => '（未初始化）';

  @override
  String logAppDataDir(String path) {
    return '應用程式資料目錄\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData（Roaming）\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return '本機資料目錄\n$path';
  }

  @override
  String get nowPlayingVideo => '正在播放影片';

  @override
  String get commonUnknown => '未知';

  @override
  String get unnamedPlaylist => '未命名的播放清單';

  @override
  String get unknownVideo => '未知影片';

  @override
  String dohQueryFailed(int code) {
    return 'DoH 查詢失敗: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP 連線成功';

  @override
  String get netModeCompat => 'Host 映射 IP 直連，繞過 SNI 干擾';

  @override
  String get netModeStandard => '系統預設網絡堆疊';

  @override
  String netHostResolveFailed(String host) {
    return '無法解析主機 $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie 為空';

  @override
  String get biliCookieIncomplete =>
      'Cookie 不完整，請從瀏覽器複製全部 Cookie（需包含 SESSDATA）';

  @override
  String get biliCookieMissingJct =>
      'Cookie 缺少 bili_jct，請重新從瀏覽器複製完整 Cookie（點讚/發評論等操作依賴它）';

  @override
  String get biliCookieInvalid => 'Cookie 無效或已過期，請重新從瀏覽器複製';

  @override
  String get biliLoginSuccess => '登入成功';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked => '請求被風控攔截(-412)，請稍後重試';

  @override
  String get biliQrExpired => 'QR Code 已失效';

  @override
  String get biliQrScanned => '已掃描，請在手機上確認';

  @override
  String get biliQrWaiting => '等待掃描';

  @override
  String get biliRequestFailed => '請求失敗';

  @override
  String get biliResponseNoData => '回應缺少 data';

  @override
  String get biliQrNoSessionCookie => '未取得工作階段 Cookie，請重新整理 QR Code 後重試';

  @override
  String get biliQrMissingJct =>
      'QR Code 登入未取得完整工作階段（缺少 bili_jct），請改用「貼上 Cookie」或「瀏覽器登入」方式';

  @override
  String get biliNoSessionCookie => '未取得工作階段 Cookie';

  @override
  String get biliWebKeyFailed => '取得登入公鑰失敗，請檢查網絡';

  @override
  String get biliPwdEncryptFailed => '密碼加密失敗';

  @override
  String get biliNeedGeetest => '需要完成滑塊驗證';

  @override
  String get biliUnknownError => '未知錯誤';

  @override
  String get csPlaylists => '播放清單';

  @override
  String get csDanmaku => '彈幕';

  @override
  String get csCloudEncrypted => '雲端數據已加密，請先在 WebDAV 設定中填寫同步密碼';

  @override
  String get csCloudPassMismatch => '雲端數據已加密且同步密碼不匹配，無法同步';

  @override
  String get csCloudNoFile => '雲端沒有播放清單檔案，無法還原';

  @override
  String get csRestoredFromCloud => '已從雲端還原';

  @override
  String get csSyncDone => '同步完成';

  @override
  String csUploadBgCount(int count) {
    return '上傳背景圖 $count 張';
  }

  @override
  String csDownloadBgCount(int count) {
    return '下載背景圖 $count 張';
  }

  @override
  String csUploadedFileCount(int count) {
    return '上傳 $count 個檔案';
  }

  @override
  String csDownloadedFileCount(int count) {
    return '下載 $count 個檔案';
  }

  @override
  String csMergedListsCount(int count) {
    return '合併 $count 個清單';
  }

  @override
  String get csEncrypted => '已加密';

  @override
  String csSyncFailed(String error) {
    return '同步失敗: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return '已上傳 $count 個播放清單到雲端';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return '上傳 $uploaded 個，下載 $downloaded 個';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return '，失敗 $failed 個（$details）';
  }

  @override
  String get unknownUser => '未知用戶';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => '傳送檔案';

  @override
  String receivingFile(String fileName) {
    return '接收: $fileName';
  }

  @override
  String get notificationChannelName => '聊天訊息';

  @override
  String get notificationChannelDesc => '接收聊天訊息和快速回覆';

  @override
  String get notificationReply => '回覆';

  @override
  String get screenshotSavedTitle => '截圖已儲存';

  @override
  String get screenshotSavedToAlbum => '截圖已儲存到相簿';

  @override
  String get notificationConfirm => '確認';

  @override
  String get callInProgressError => '目前有未結束的通話，請先掛斷';

  @override
  String get callTcpFailed => '無法連線對方（TCP 建立失敗），請確認對方在線';

  @override
  String get callConnectionDropped => '連線建立後立即中斷，請檢查網絡或對方狀態';

  @override
  String callInitFailed(String error) {
    return '發起通話失敗：$error';
  }

  @override
  String callAcceptFailed(String error) {
    return '接聽通話失敗：$error';
  }

  @override
  String get callRecordVoice => '語音通話';

  @override
  String get callRecordMissedOutgoing => '未接通話';

  @override
  String get callRecordRejected => '已拒絕來電';

  @override
  String get callRecordMissedIncoming => '未接來電';

  @override
  String get callPeerNoAnswer => '對方未接聽';

  @override
  String get callUnknown => '未知';

  @override
  String get callInProgress => '通話中';

  @override
  String get webdavHttpWarning => '警告：使用 HTTP 連線，憑證將以明文傳輸。建議使用 HTTPS。';

  @override
  String get webdavConfigRequired => '請先填寫伺服器地址和使用者名稱';

  @override
  String get webdavAuthFailed => '認證失敗：使用者名稱或密碼錯誤';

  @override
  String webdavConnectFailed(int code) {
    return '連線失敗：HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return '網絡錯誤：無法連線到伺服器 ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return '未知錯誤：$error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV 未設定';

  @override
  String webdavLocalFileMissing(String path) {
    return '本機檔案不存在: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return '上傳失敗：HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return '上傳異常：$error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return '下載失敗: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return '下載異常: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return '刪除失敗: $error';
  }

  @override
  String webdavListFailed(String error) {
    return '列出檔案失敗: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND 失敗: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return '網絡錯誤：$msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return '準備備份 $count 個檔案...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return '正在備份 ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return '備份完成：$success 成功，$fail 失敗';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '確定';

  @override
  String get commonConnect => '連線';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCreate => '建立';

  @override
  String get commonDelete => '刪除';

  @override
  String get drawerHome => '主頁';

  @override
  String get drawerVerificationRequests => '驗證請求';

  @override
  String get drawerSettings => '設定';

  @override
  String get drawerAbout => '關於';

  @override
  String get drawerCloseMenu => '關閉選單';

  @override
  String get drawerLockNow => '立即鎖定';

  @override
  String get drawerNoNickname => '未設定暱稱';

  @override
  String get drawerSwitchToDark => '切換到深色模式';

  @override
  String get drawerSwitchToLight => '切換到淺色模式';

  @override
  String get drawerLightMode => '淺色模式';

  @override
  String get drawerDarkMode => '深色模式';

  @override
  String get drawerSystemMode => '跟隨系統';

  @override
  String drawerThemeSwitched(String mode) {
    return '已切換到 $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return '獲取失敗: $error';
  }

  @override
  String get drawerNoDeviceInfo => '暫無裝置資料';

  @override
  String get drawerBackgroundTitle => '側邊欄背景';

  @override
  String get drawerBackgroundHasCustom => '目前已設定自訂背景，您可以更換或移除。';

  @override
  String get drawerBackgroundNoCustom => '為側邊欄設定一張個人化背景圖片。';

  @override
  String get drawerBackgroundUpdated => '✅ 側邊欄背景已更新';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '❌ 設定失敗: $error';
  }

  @override
  String get drawerBackgroundChange => '更換背景';

  @override
  String get drawerBackgroundSelect => '選擇背景圖片';

  @override
  String get drawerBackgroundRestored => '已還原預設背景';

  @override
  String get drawerBackgroundRemove => '移除背景';

  @override
  String get homeOpenMenu => '開啟選單';

  @override
  String get homeAddConnection => '新增連線';

  @override
  String get homeMessages => '訊息';

  @override
  String get homeNoConnections => '暫無連線';

  @override
  String get homePullToRefreshHint => '下拉重新整理或點擊右上角新增';

  @override
  String get homeLoadFailed => '聊天記錄載入失敗，請重試';

  @override
  String get homeRetryLoad => '重新載入';

  @override
  String get homeUnknownAddress => '未知地址';

  @override
  String get homeNoMessages => '暫無訊息';

  @override
  String homeFileMessage(String fileName) {
    return '[檔案] $fileName';
  }

  @override
  String get homeFileFallbackName => '檔案';

  @override
  String get homeMessagePlaceholder => '[訊息]';

  @override
  String get connectionLost => '連線已失效';

  @override
  String get openVideoFailed => '無法開啟該影片';

  @override
  String get connectDialogTitle => '連線到對等端';

  @override
  String get connectIpHint => '輸入 IP 地址 (例如：192.168.1.100 或 fe80::1)';

  @override
  String get connectIpEmpty => '請輸入 IP 地址';

  @override
  String get connectIpInvalid => 'IP 地址格式不正確';

  @override
  String get connectIpNotLan => '僅允許內聯網 IP 地址';

  @override
  String get connectRequestSent => '已傳送連線請求，等待對方驗證';

  @override
  String get connectFailed => '連線失敗，請檢查 IP 地址是否正確或對方是否在線';

  @override
  String get homeScanQr => '掃一掃';

  @override
  String get homeMyQrCode => '我的 QR Code';

  @override
  String get homeManualAdd => '手動新增';

  @override
  String get scannedFriends => '透過掃描新增的好友';

  @override
  String get scanTitle => '掃一掃';

  @override
  String get scanTitleWebdav => '掃描 WebDAV 地址';

  @override
  String get scanHint => '將 QR Code / 條碼對準框內';

  @override
  String get scanHintWebdav => '將 WebDAV 伺服器地址 QR Code 對準框內';

  @override
  String get scanHintAddFriend => '將好友的裝置 QR Code 對準框內';

  @override
  String get scanPreparing => '正在準備相機...';

  @override
  String get scanPermissionNeeded => '需要相機權限';

  @override
  String get scanPermissionNeededMsg => '請在權限彈窗中允許使用相機，才能掃描。';

  @override
  String get scanPermissionDenied => '相機權限被拒絕';

  @override
  String get scanPermissionDeniedMsg => '權限已被永久拒絕，請前往系統設定手動開啟。';

  @override
  String get scanCameraUnavailable => '相機無法使用';

  @override
  String get scanRetry => '重試';

  @override
  String get scanOpenSettings => '前往系統設定';

  @override
  String get scanTorch => '閃光燈';

  @override
  String get scanDetectedLink => '偵測到連結';

  @override
  String get scanOpenLinkPrompt => '是否在內置瀏覽器中開啟以下連結？';

  @override
  String get scanCopy => '複製';

  @override
  String get scanOpen => '開啟';

  @override
  String get scanLinkCopied => '連結已複製';

  @override
  String get scanDetectedBiliVideo => '偵測到 B 站影片連結';

  @override
  String get scanBiliVideoPrompt => '是否用內置播放器開啟該影片？';

  @override
  String scanBiliVideoAt(String time) {
    return '空降至 $time';
  }

  @override
  String get scanOpenVideo => '開啟影片';

  @override
  String get scanDetectedWebdav => '偵測到 WebDAV 地址';

  @override
  String get scanWebdavPrompt => '該連結看起來是 WebDAV 伺服器地址，是否自動填入設定？';

  @override
  String get scanOpenInBrowser => '瀏覽器開啟';

  @override
  String get scanFillConfig => '填入設定';

  @override
  String get scanDetectedText => '辨識到文字';

  @override
  String get scanCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get scanClose => '關閉';

  @override
  String get scanResultTitle => '掃描結果';

  @override
  String get scanErrorPermission => '相機權限被拒絕';

  @override
  String get scanErrorUnsupported => '目前裝置不支援掃描';

  @override
  String get scanErrorDisposed => '掃描器已釋放，請重試';

  @override
  String scanErrorGeneric(String code) {
    return '相機無法使用（$code）';
  }

  @override
  String scanInitFailed(String error) {
    return '掃描器初始化失敗：$error';
  }

  @override
  String get scanDetectedDevice => '偵測到裝置 QR Code';

  @override
  String get scanAddFriendPrompt => '是否將該裝置新增為好友？';

  @override
  String get scanAddFriend => '新增好友';

  @override
  String get scanFriendAdded => '已傳送好友請求，等待對方驗證';

  @override
  String get scanFriendAddFailed => '新增好友失敗，請檢查網絡或對方是否在線';

  @override
  String get myQrTitle => '我的 QR Code';

  @override
  String get myQrHint => '讓好友掃描此 QR Code 來新增您';

  @override
  String get myQrEmbedIp => 'QR Code 中已嵌入第一個內聯網 IP';

  @override
  String get myQrLocalIps => '目前內聯網 IP';

  @override
  String get myQrCopyContent => '複製 QR Code 內容';

  @override
  String get myQrCopied => '已複製到剪貼簿';

  @override
  String get myQrNoIp => '找不到有效的內聯網 IP，請檢查網絡連線。';

  @override
  String get displayModeSectionTitle => '螢幕';

  @override
  String get displayModeTitle => '螢幕更新率';

  @override
  String get displayModeAuto => '自動';

  @override
  String get displayModeSystemTag => '[系統]';

  @override
  String get displayModeHint => '沒有生效？重新啟動應用程式試試';

  @override
  String get displayModeUnsupported => '目前平台不支援設定螢幕更新率（僅 Android）';

  @override
  String get displayModeAndroidOnly => '僅 Android';

  @override
  String get displayModeLoading => '正在取得螢幕更新率...';

  @override
  String get displayModeEmpty => '未取得可用的螢幕更新率';

  @override
  String get playerSectionEnhance => '畫面增強';

  @override
  String get superResolutionTitle => '超高解析度';

  @override
  String get superResolutionOff => '關閉';

  @override
  String get superResolutionEfficiency => '效率（低耗電）';

  @override
  String get superResolutionQuality => '畫質（最佳效果）';

  @override
  String get superResolutionHint => '透過 mpv 著色器即時增強畫面，建議配合硬件解碼；對動畫內容效果最佳';

  @override
  String get skipIntroOutroTitle => '跳過片頭/片尾';

  @override
  String get skipIntroOutroHint => '透過社區共享數據辨識片頭片尾，僅在影片有 BV+CID 時提示';

  @override
  String get skipIntro => '跳過片頭';

  @override
  String get skipOutro => '跳過片尾';

  @override
  String playlistDetailEpisodes(int count) {
    return '共 $count 集';
  }

  @override
  String get playlistDetailEmpty => '該播放清單為空，請先編輯新增影片';

  @override
  String playlistDetailEpisodeOf(int index) {
    return '第 $index 集';
  }

  @override
  String playlistDetailResume(String position) {
    return '看到這集 · $position';
  }

  @override
  String get playlistDetailBgTitle => '背景圖';

  @override
  String get playlistDetailBgPick => '選擇背景圖片';

  @override
  String get playlistDetailBgChange => '更換背景';

  @override
  String get playlistDetailBgRemove => '移除背景';

  @override
  String get playlistDetailBgUpdated => '✅ 背景圖已更新';

  @override
  String get playlistDetailBgRemoved => '已還原預設背景';

  @override
  String playlistDetailBgFail(String error) {
    return '設定失敗：$error';
  }

  @override
  String get playlistFabRestart => '從頭開始';

  @override
  String get playlistMenuMore => '更多操作';

  @override
  String get playlistMenuRename => '編輯名稱';

  @override
  String get playlistMenuMultiSelect => '多選';

  @override
  String get playlistMenuDanmaku => '彈幕';

  @override
  String get playlistRenameTitle => '重新命名播放清單';

  @override
  String get playlistRenameHint => '輸入新的清單名稱';

  @override
  String get playlistRenameSaved => '已重新命名';

  @override
  String get playlistSelectDone => '完成';

  @override
  String get playlistSelectEmpty => '請先選擇劇集';

  @override
  String playlistSelectDelete(int count) {
    return '刪除選取（$count）';
  }

  @override
  String playlistSelectDeleted(int count) {
    return '已刪除 $count 集';
  }

  @override
  String get playlistDanmakuTitle => '匯入番劇彈幕';

  @override
  String get playlistDanmakuSsHint => '輸入番劇 SS 號（season_id）';

  @override
  String get playlistDanmakuFetchFail => '獲取劇集失敗，請檢查 SS 號';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return '選擇劇集（共 $count 集）';
  }

  @override
  String get playlistDanmakuSelectAll => '全選';

  @override
  String get playlistDanmakuImport => '匯入並附加彈幕';

  @override
  String playlistDanmakuAttached(int count) {
    return '已為 $count 集附加彈幕';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '所選 $selected 集超過清單 $total 集，超出部分已忽略';
  }

  @override
  String get splitSelectChat => '選擇一個聊天';

  @override
  String get statusPending => '待對方驗證';

  @override
  String get statusConnected => '已連線';

  @override
  String get statusRejected => '已拒絕';

  @override
  String get statusDisconnected => '已中斷連線';

  @override
  String get homeStart => '開始';

  @override
  String get homeDone => '完成';

  @override
  String get homeBack => '返回';

  @override
  String get homeOverview => '鳥瞰視圖';

  @override
  String get homeLocalUser => '本機使用者';

  @override
  String get homeDefaultGroup => '預設群組';

  @override
  String get homeNewGroup => '新群組';

  @override
  String get homeUnnamedGroup => '（未命名群組）';

  @override
  String get homeDeleteGroupTitle => '確認刪除';

  @override
  String get homeDeleteGroupMessage => '刪除該組將同時刪除組內的所有磁貼，是否繼續？';

  @override
  String get homeNewGroupTitle => '新增群組';

  @override
  String get homeGroupNameHint => '輸入群組名稱';

  @override
  String get homeRenameGroupTitle => '為該組命名';

  @override
  String get homeNewGroupNameHint => '輸入新組名';

  @override
  String get homeImageSlice => '圖片碎片';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (小)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (寬)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (大)';
  }

  @override
  String get homeGroupOne => '分組1';

  @override
  String get homeGroupTwo => '分組2';

  @override
  String get homeGroupProductivity => '生產力工具';

  @override
  String get homeGroupLegacy => '舊版';

  @override
  String get tileImageSlicer => '圖片切割';

  @override
  String get tileSystemSettings => '系統設定';

  @override
  String get tileDatabase => '資料庫';

  @override
  String get tileLcdDisplay => 'LCD 顯示器';

  @override
  String get tileLedDynamic => 'LED 動態';

  @override
  String get tileLedStatic => 'LED 靜態';

  @override
  String get tilePisScreen => 'PIS 螢幕';

  @override
  String get tileRoutePreview => '路線預覽';

  @override
  String get tileStationEntranceDesign => '出入口設計';

  @override
  String get tileStationEntrancePillar => '出入口立柱';

  @override
  String get tileStationEntranceSideName => '出入口側名';

  @override
  String get tilePlatformSideName => '側邊站名';

  @override
  String get tileScreenDoorCover => '月台幕門蓋板';

  @override
  String get tileStationNameSign => '站名牌';

  @override
  String get tileGeneralSign => '通用標誌';

  @override
  String get tileLineSymbol => '路線符號';

  @override
  String get tileBusLcd => '巴士 LCD';

  @override
  String get tileJsonEditor => 'JSON 編輯器';

  @override
  String get tileNamingRule => '命名規範';

  @override
  String get tilePlatformText => '月台文字';

  @override
  String get tileDepartureText => '出發文字';

  @override
  String get tileArrivalText => '到站文字';

  @override
  String get tileOperationDirectionLegacy => '營運方向(舊)';

  @override
  String get tileLegacyLcdWarning => '舊版 LCD（警告）';

  @override
  String get tileLinearRoute => '線性路線';

  @override
  String get tileRoadSign => '路牌';

  @override
  String get commentPanelTitle => '留言區';

  @override
  String commentTotalCount(int count) {
    return '共 $count 則';
  }

  @override
  String get commentSortHeat => '按熱門程度';

  @override
  String get commentSortTime => '按時間';

  @override
  String get commentLoading => '正在載入留言...';

  @override
  String get commentLoadFail => '留言載入失敗，請檢查網絡';

  @override
  String get commentLoadMoreFail => '載入更多留言失敗';

  @override
  String get commentNoMore => '沒有更多留言了';

  @override
  String get commentLoadingMore => '載入中...';

  @override
  String get commentEmpty => '還沒有留言';

  @override
  String get commentPinned => '置頂';

  @override
  String get commentDeleted => '留言已刪除';

  @override
  String get commentExpand => '展開';

  @override
  String get commentCollapse => '收起';

  @override
  String get commentTranslateNeedEnable => '請先在語言設定中開啟 AI 翻譯';

  @override
  String get commentTranslateNone => '沒有可用翻譯';

  @override
  String commentSubCount(int count) {
    return '共 $count 則回覆';
  }

  @override
  String commentSubLoadMore(String hint) {
    return '載入更多回覆（$hint）';
  }

  @override
  String get commentYesterday => '昨天';

  @override
  String get articleLoadFailed => '文章載入失敗';

  @override
  String get articleNoContent => '文章正文為空或暫不支援渲染';

  @override
  String get articleOpenBrowser => '瀏覽器開啟';

  @override
  String get articleShare => '分享';

  @override
  String get articleAuthorUnknown => '未知作者';

  @override
  String get browserLinkPageTitle => '網頁連結';

  @override
  String articleViews(String count) {
    return '$count 閱讀';
  }

  @override
  String get contactPickerTitle => '傳送給聯絡人';

  @override
  String get contactPickerContentLabel => '傳送內容';

  @override
  String get contactPickerContentHint => '輸入要傳送的內容';

  @override
  String get contactPickerContentEmpty => '內容不能為空';

  @override
  String get contactPickerSearchHint => '搜尋聯絡人';

  @override
  String get contactPickerEmpty => '暫無聯絡人';

  @override
  String get contactPickerNoMatch => '未找到符合的聯絡人';

  @override
  String get contactPickerSelectAll => '全選';

  @override
  String contactPickerSendToCount(int count) {
    return '傳送給 $count 個聯絡人';
  }

  @override
  String contactPickerSent(int count) {
    return '已傳送給 $count 個聯絡人';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '「$name」未連接，無法傳送';
  }

  @override
  String contactPickerSendFailed(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get contactPickerOnline => '在線';

  @override
  String get contactPickerOffline => '離線';

  @override
  String get articleShareToContact => '私訊分享';

  @override
  String get playerDanmakuList => '彈幕列表';

  @override
  String playerDanmakuListCount(int count) {
    return '彈幕列表 · 共 $count 條';
  }

  @override
  String get playerDanmakuListEmpty => '暫無彈幕';

  @override
  String get playerDanmakuListNoMatch => '無符合的彈幕';

  @override
  String get playerDanmakuListSearchHint => '搜尋彈幕內容';

  @override
  String get playerDanmakuListJumpCurrent => '定位到目前播放';

  @override
  String get playerViewNotes => '查看筆記';

  @override
  String get playerNotesTitle => '筆記';

  @override
  String playerNotesCount(int count) {
    return '筆記（$count）';
  }

  @override
  String get playerNotesEmpty => '該影片暫無公開筆記';

  @override
  String get playerNotesNoMore => '沒有更多了';

  @override
  String get playerNotesLoadFailed => '筆記載入失敗';

  @override
  String get playerNotesViewFull => '查看全部';

  @override
  String get playerWriteNote => '寫筆記';

  @override
  String get noteEditorWrite => '寫筆記';

  @override
  String get noteEditorTitle => '寫筆記';

  @override
  String get noteEditorTitleHint => '標題（選填）';

  @override
  String get noteEditorContentHint => '開始記筆記…';

  @override
  String get noteEditorEmoji => '表情';

  @override
  String get noteEditorPublish => '發布';

  @override
  String get noteEditorEmptyContent => '筆記內容不能為空';

  @override
  String get noteEditorContentTooShort => '內容至少 10 個字元才能發布';

  @override
  String get noteEditorNotLoggedIn => '未登入：筆記已儲存為本機草稿，登入後可發布';

  @override
  String get noteEditorPublished => '筆記已發布';

  @override
  String get noteEditorPublishNetworkError => '發布失敗（網路異常），草稿已儲存';

  @override
  String get noteEditorPublishRejected => '發布被伺服器拒絕，草稿已保留';

  @override
  String get noteEditorDraftSaved => '已自動儲存草稿';

  @override
  String get noteEditorLoggedInHint => '已登入，可發布公開筆記';

  @override
  String get noteEditorGuestHint => '未登入：僅儲存本機草稿，不能發布';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return '草稿已儲存 $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count 字';
  }

  @override
  String get noteEditorMyDraft => '我的草稿';

  @override
  String get noteEditorDeleteDraft => '刪除草稿';

  @override
  String get playerMoreTooltip => '更多操作';

  @override
  String get commentComposerBarHint => '說點什麼…';

  @override
  String get commentComposerHint => '輸入評論內容…';

  @override
  String commentComposerReplyHint(String name) {
    return '回覆 @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return '回覆 @$name';
  }

  @override
  String get commentComposerEmote => '表情';

  @override
  String get commentComposerSend => '發送';

  @override
  String get commentComposerEmpty => '評論內容不能為空';

  @override
  String get commentComposerEmoteUnavailable => '表情面板不可用（可能未登入）';

  @override
  String get commentComposerPickImage => '選擇圖片';

  @override
  String get commentComposerMore => '更多';

  @override
  String get commentComposerVideoProgress => '影片進度';

  @override
  String get commentComposerVideoScreenshot => '影片截圖';

  @override
  String commentComposerImageLimit(int count) {
    return '最多選擇 $count 張圖片';
  }

  @override
  String get commentComposerCaptureFailed => '截圖失敗，請先開始播放';

  @override
  String get commentComposerUploadFailed => '圖片上傳失敗，請重試';

  @override
  String get commentComposerFabLabel => '發評論';

  @override
  String get commentComposerFabReply => '發回覆';

  @override
  String get danmakuSendTitle => '發彈幕';

  @override
  String get danmakuSendModeLabel => '模式';

  @override
  String get danmakuSendFontSizeLabel => '字號';

  @override
  String get danmakuSendColorLabel => '顏色';

  @override
  String get danmakuFontSizeSmall => '小';

  @override
  String get danmakuFontSizeStandard => '標準';

  @override
  String get danmakuFontSizeLarge => '大';

  @override
  String get danmakuSendCustomColor => '自訂顏色';

  @override
  String get danmakuSendColorOk => '確定';

  @override
  String get danmakuSendPreviewPlaceholder => '發個友善的彈幕見證當下';

  @override
  String get drawerHistory => '历史记录';

  @override
  String get drawerWatchLater => '稍后再看';

  @override
  String get drawerMyCache => '我的缓存';

  @override
  String get historyCenterTitle => '历史记录';

  @override
  String get historyTabWatch => '观看历史';

  @override
  String get historyTabPlay => '播放进度';

  @override
  String get historySearchHint => '搜索历史...';

  @override
  String get historyPauseHistory => '暂停记录历史';

  @override
  String get historyResumeHistory => '恢复记录历史';

  @override
  String get historyPausedTip => '历史记录已暂停';

  @override
  String get historyPausedTipAction => '点击恢复';

  @override
  String get historyClearWatchHistory => '清空观看历史';

  @override
  String get historyClearPlayHistory => '清空播放记录';

  @override
  String get historyClearAllTitle => '清空历史';

  @override
  String historyClearAllConfirm(String label) {
    return '确定要清空全部$label吗？此操作不可恢复。';
  }

  @override
  String get historyNoWatchHistory => '暂无观看历史';

  @override
  String get historyNoPlayHistory => '暂无播放记录';

  @override
  String get historyDeleteSelected => '删除选中';

  @override
  String historySelectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get historySearchNoResult => '无匹配结果';

  @override
  String get historyPauseOnSnack => '已暂停历史记录';

  @override
  String get historyResumeOnSnack => '已恢复历史记录';

  @override
  String historyDeleteToast(int count) {
    return '已删除 $count 条记录';
  }

  @override
  String get myCacheTitle => '我的缓存';

  @override
  String get myCacheSearchHint => '搜索缓存视频...';

  @override
  String get myCacheDownloading => '正在缓存';

  @override
  String get myCacheCached => '已缓存';

  @override
  String get myCacheNoCache => '暂无缓存视频';

  @override
  String myCacheGroupCount(int count) {
    return '$count个视频';
  }

  @override
  String get myCacheDeleteGroup => '删除整组';

  @override
  String get myCacheUpdateDanmaku => '更新弹幕';

  @override
  String get myCacheClearAllTitle => '清空全部缓存';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return '将删除全部已缓存视频（$count个视频 · $size），确定吗？';
  }

  @override
  String get cacheActionDownload => '缓存';

  @override
  String get cacheActionCached => '已缓存';

  @override
  String get cacheActionCaching => '缓存中';

  @override
  String get cacheToastSuccess => '已加入缓存队列';

  @override
  String get cacheToastCached => '该视频已缓存';

  @override
  String cacheToastFailed(String error) {
    return '缓存失败：$error';
  }

  @override
  String get drawerRecommend => '推荐';

  @override
  String get recommendSourceWeb => 'Web端';

  @override
  String get recommendSourceApp => 'APP端';

  @override
  String get recommendEmpty => '暂无推荐内容';

  @override
  String get recommendSwitchList => '切换为单列';

  @override
  String get recommendSwitchGrid => '切换为多列';

  @override
  String get sideBarExpand => '展开侧边栏';

  @override
  String get sideBarCollapse => '收起侧边栏';

  @override
  String get sideBarMore => '更多';

  @override
  String get recommendTabHot => '热门';

  @override
  String get recommendTabBangumi => '番剧';

  @override
  String get recommendSourceTitle => '推荐数据来源';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String metroDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get metroSunday => '星期日';

  @override
  String get metroMonday => '星期一';

  @override
  String get metroTuesday => '星期二';

  @override
  String get metroWednesday => '星期三';

  @override
  String get metroThursday => '星期四';

  @override
  String get metroFriday => '星期五';

  @override
  String get metroSaturday => '星期六';

  @override
  String get metroLogin => '登入';

  @override
  String get metroWelcome => '歡迎';

  @override
  String get imageViewerNoFile => '找不到圖片檔案';

  @override
  String get syncPassphraseEmpty => '同步口令不能為空';

  @override
  String get imageBytesRequired => 'imageUrl 或 imageBytes 必須提供其一';

  @override
  String get webdavConnectSuccess => '✅ 連線成功！';

  @override
  String get webdavConfigSaved => '設定已儲存';

  @override
  String get webdavConfigureFirst => '請先設定並測試 WebDAV 連線';

  @override
  String get webdavSelectContactsFirst => '請先在下方面選要備份的聯絡人';

  @override
  String get webdavNoFiles => '選中的聯絡人沒有可備份的檔案';

  @override
  String get webdavConfirmBackup => '確認備份';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return '將備份 $contacts 位聯絡人的 $files 個檔案到 WebDAV 伺服器。\n遠端路徑：$path/chats/<暱稱>/';
  }

  @override
  String get webdavStartBackup => '開始備份';

  @override
  String get webdavBackingUpTitle => '正在備份';

  @override
  String get webdavBackupDoneTitle => '備份完成';

  @override
  String webdavTotalFiles(int count) {
    return '總計：$count 個檔案';
  }

  @override
  String webdavSuccessCount(int count) {
    return '成功：$count';
  }

  @override
  String webdavFailCount(int count) {
    return '失敗：$count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...還有 $count 個錯誤';
  }

  @override
  String get webdavBackupFab => '備份';

  @override
  String get webdavShowInfo => '顯示我的資訊';

  @override
  String get webdavHideInfo => '隱藏我的資訊';

  @override
  String get webdavScanToFill => '掃碼填入伺服器位址';

  @override
  String get webdavScanFilled => '已透過掃碼填入位址';

  @override
  String get webdavServerConfig => '伺服器設定';

  @override
  String get webdavServerUrlLabel => '伺服器位址';

  @override
  String get webdavUsernameLabel => '使用者名稱';

  @override
  String get webdavPasswordLabel => '密碼';

  @override
  String get webdavRemotePathLabel => '遠端備份路徑';

  @override
  String get webdavTesting => '測試中...';

  @override
  String get webdavSaveAndTest => '儲存並測試連線';

  @override
  String get webdavSaveOnly => '僅儲存';

  @override
  String get webdavConnectVerified => '連線驗證通過';

  @override
  String get webdavAutoBackup => '自動備份';

  @override
  String get webdavAutoBackupOnReceive => '接收檔案時自動備份';

  @override
  String get webdavAutoBackupSubtitle => '僅對下方面選的聯絡人生效';

  @override
  String get webdavMediaSync => '媒體同步';

  @override
  String get webdavSyncPlaylists => '同步播放清單';

  @override
  String get webdavSyncDanmaku => '同步彈幕';

  @override
  String get webdavPassphraseEncrypted => '同步密碼（AES-256 加密）';

  @override
  String get webdavPassphrasePlain => '同步密碼（留空 = 明文上傳）';

  @override
  String get webdavPassphraseHint => '填寫密碼後播放清單將加密上傳';

  @override
  String get webdavGeneratePassphrase => '產生隨機密碼';

  @override
  String get webdavMediaSyncHint =>
      '播放清單（含背景圖）與彈幕儲存到雲端的獨立目錄（playlists/、danmaku/），不會與聊天備份混在一起。多台裝置共用同一遠端路徑即可互相合併；播放清單可在播放清單頁手動同步或從雲端還原。';

  @override
  String get webdavEncryptionOn =>
      '已啟用加密：播放清單將以 AES-256-GCM 加密後上傳（含內嵌的 WebDAV 鑑權資訊），伺服器無法讀取內容。多台裝置需填寫相同密碼才能解密。';

  @override
  String get webdavEncryptionOff =>
      '未加密：播放清單（含內嵌的 WebDAV 鑑權資訊）將明文上傳，任何能讀取伺服器檔案的人都能看到，不推薦。';

  @override
  String get webdavBackupContacts => '備份聯絡人';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '已選 $selected / $total 位聯絡人';
  }

  @override
  String get webdavSearchContacts => '搜尋聯絡人或 IP...';

  @override
  String get webdavDeselectAll => '取消全選';

  @override
  String webdavFileCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get webdavNoContacts => '暫無聯絡人';

  @override
  String get webdavNoMatch => '無相符結果';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count 個檔案';
  }

  @override
  String get webdavManage => '管理';

  @override
  String get webdavLastSync => '上次同步';

  @override
  String get webdavLastError => '最近錯誤';

  @override
  String get webdavClearConfig => '清除 WebDAV 設定';

  @override
  String get webdavClearConfigSubtitle => '刪除所有伺服器資訊和憑證';

  @override
  String get webdavUserLabel => '使用者';

  @override
  String webdavStatusActive(String name) {
    return '$name已啟用';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name已設定';
  }

  @override
  String get webdavStatusNotConfigured => '未設定';

  @override
  String get webdavNotSynced => '尚未同步';

  @override
  String get webdavJustNow => '上次同步：剛剛';

  @override
  String webdavMinutesAgo(int minutes) {
    return '上次同步：$minutes 分鐘前';
  }

  @override
  String webdavHoursAgo(int hours) {
    return '上次同步：$hours 小時前';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return '上次同步：$month月$day日 $time';
  }

  @override
  String get webdavPassphraseGenerated => '已產生同步密碼並複製到剪貼簿，請在其他裝置上填入相同密碼';

  @override
  String get webdavConfirmClear => '確認清除';

  @override
  String get webdavClearConfirmText =>
      '將刪除所有 WebDAV 設定（伺服器、憑證、聯絡人選取）。\n已上傳的檔案不受影響。';

  @override
  String get profileEditProfile => '編輯資料';

  @override
  String get profileAccountSection => '帳戶管理';

  @override
  String get profileWebdavBackup => 'WebDAV 備份';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username 已登入';
  }

  @override
  String get profileNotLoggedIn => '未登入';

  @override
  String get profileAvatarSection => '頭像';

  @override
  String get profileChangeAvatar => '更換頭像';

  @override
  String get profileRemoveAvatar => '移除頭像';

  @override
  String get profilePickFromGallery => '從相簿選擇圖片';

  @override
  String get profileRestoreDefaultAvatar => '恢復預設頭像';

  @override
  String get profileSetBackground => '設定背景';

  @override
  String get profileBgSubtitle => '為側邊欄選擇一張背景圖';

  @override
  String get profileRestoreDefault => '恢復預設';

  @override
  String get profileBgRemoveSubtitle => '移除自訂背景，使用主題色漸層';

  @override
  String get profileInfoSection => '個人資訊';

  @override
  String get profileNicknameLabel => '暱稱';

  @override
  String get profileNotSet => '未設定';

  @override
  String get profileBgTitle => '個人資料背景';

  @override
  String get profileAvatarUpdated => '✅ 頭像已更新';

  @override
  String profileAvatarFailed(String error) {
    return '❌ 選擇頭像失敗: $error';
  }

  @override
  String get profileRemoveAvatarConfirm => '確定要刪除目前頭像嗎？此操作無法復原。';

  @override
  String get profileAvatarRemoved => '頭像已移除';

  @override
  String get profileSetNickname => '設定暱稱';

  @override
  String get profileNicknameHint => '輸入暱稱';

  @override
  String get profileNicknameEmpty => '暱稱不能為空';

  @override
  String get profileNicknameUpdated => '✅ 暱稱已更新';

  @override
  String get colorDefaultGreen => '預設綠';

  @override
  String get colorPink => '粉紅色';

  @override
  String get colorRed => '紅色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorYellow => '黃色';

  @override
  String get colorLime => '酸橙色';

  @override
  String get colorLightGreen => '淺綠色';

  @override
  String get colorGreen => '綠色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '藍綠色';

  @override
  String get colorLightBlue => '淺藍色';

  @override
  String get colorBlue => '藍色';

  @override
  String get colorIndigo => '靛藍色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorBlueGrey => '藍灰色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorGrey => '灰色';

  @override
  String get themeColorExtracted => '已從圖片提取主題色';

  @override
  String themeColorFailed(String error) {
    return '取色失敗: $error';
  }

  @override
  String get themeImageOnly => '僅支援圖片格式';

  @override
  String get themeTitle => '主題';

  @override
  String themeColorCopied(String hex) {
    return '已複製色號: $hex';
  }

  @override
  String get themeAppearance => '外觀';

  @override
  String get themeDarkBlackened => '深色模式（已黑化）';

  @override
  String get themeOff => '已關閉';

  @override
  String get themeEnabled => '已啟用';

  @override
  String get themeColorsSection => '配色';

  @override
  String get themePaletteStyle => '調色板風格';

  @override
  String get themeFollowSystem => '跟隨系統配色';

  @override
  String get themePickColor => '選擇顏色';

  @override
  String get themeDropHint => '放開以從圖片提取主題色';

  @override
  String get themeNewTheme => '新增主題';

  @override
  String themeSwitched(String name) {
    return '已切換至 $name 主題';
  }

  @override
  String get themeDeleteTitle => '刪除主題';

  @override
  String themeDeleteConfirm(String name) {
    return '確定要刪除自訂主題「$name」嗎？';
  }

  @override
  String themeDeleted(String name) {
    return '已刪除「$name」';
  }

  @override
  String get themeCreateTitle => '建立自訂主題';

  @override
  String get themeNameLabel => '主題名稱';

  @override
  String get themeNameHint => '請輸入文字';

  @override
  String get themeHexLabel => '十六進位/RGB';

  @override
  String get themeHexHint => '例如 #FF0000 或 255,0,0';

  @override
  String themeCreated(String name) {
    return '主題「$name」已建立並儲存';
  }

  @override
  String get themeCopyColor => '複製色號';

  @override
  String get themePickFromImage => '從圖片取色';

  @override
  String get searchBack => '返回設定';

  @override
  String get searchHint => '搜尋設定項目…';

  @override
  String get searchPrompt => '輸入關鍵詞搜尋設定項目';

  @override
  String get searchExamples => '例如：更新率 / 解碼 / UA / 彈幕';

  @override
  String searchNoResults(String query) {
    return '找不到「$query」相關設定';
  }

  @override
  String get searchThemeMode => '主題模式';

  @override
  String get searchPureBlack => '純黑深色模式';

  @override
  String get searchThemeColor => '主題配色';

  @override
  String get searchFontWeight => '文字粗細';

  @override
  String get searchDisplayScale => '顯示縮放';

  @override
  String get searchDisplayMode => '顯示模式 / 螢幕更新率';

  @override
  String get searchStatusBar => '狀態列';

  @override
  String get searchKeepWindowRatio => '等比例拉伸視窗';

  @override
  String get searchLongPressSpeed => '長按鍵加速';

  @override
  String get searchScreenshot => '截圖功能';

  @override
  String get searchScreenshotDanmaku => '截圖時顯示彈幕';

  @override
  String get searchPlayProgress => '播放進度';

  @override
  String get searchHwdec => '硬體解碼';

  @override
  String get searchVideoSync => '影片同步';

  @override
  String get searchImmersiveLongPress => '沉浸模式長按加速';

  @override
  String get searchMpvLog => '記錄 mpv 日誌';

  @override
  String get searchMpvLogLevel => 'mpv 日誌細度';

  @override
  String get searchNetworkMode => '網路模式';

  @override
  String get searchInsecureCert => '允許不安全的憑證';

  @override
  String get searchChatIpv6 => '聊天 IPv6';

  @override
  String get searchConnectivityTest => '連通性測試';

  @override
  String get searchHostOverrides => 'Host 對應';

  @override
  String get searchDohQuery => 'DoH 查詢';

  @override
  String get searchReferer => '請求頭 Referer';

  @override
  String get searchUserAgent => '請求頭 User-Agent';

  @override
  String get searchSystemSettings => '系統設定';

  @override
  String get searchUserSettings => '使用者設定';

  @override
  String get settingsDisplaySub => '主題、字型、版面配置';

  @override
  String get settingsSystem => '系統';

  @override
  String get settingsSystemSub => '語言、儲存、權限';

  @override
  String get settingsStorage => '儲存';

  @override
  String get settingsStorageSub => '圖片快取、彈幕快取';

  @override
  String get settingsNetwork => '網路';

  @override
  String get settingsNetworkSub => 'Wi-Fi、Proxy、同步';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSub => '應用語言、B 站翻譯（AI 翻譯）';

  @override
  String get appLangSection => '應用語言';

  @override
  String get appLangFollowSystem => '跟隨系統';

  @override
  String get biliLangSection => '翻譯目標語言';

  @override
  String get biliAiSection => 'AI 翻譯';

  @override
  String get biliAiTranslateEnable => '啟用 AI 翻譯';

  @override
  String get biliAiTranslateOnDesc => '已開啟：B 站請求將攜帶翻譯頭，返回該語言內容';

  @override
  String get biliAiTranslateOffDesc => '關閉：按原始語言返回內容';

  @override
  String get langZhCn => '簡體中文';

  @override
  String get langZhHk => '繁體中文（香港）';

  @override
  String get langZhTw => '繁體中文（台灣）';

  @override
  String get langEnUs => 'English（英語）';

  @override
  String get langJaJp => '日本語';

  @override
  String get langKoKr => '한국어';

  @override
  String get settingsPlayer => '播放器';

  @override
  String get settingsPlayerSub => '狀態列、加速、截圖';

  @override
  String get settingsStartScreenSub => '開始螢幕、Charm';

  @override
  String get settingsLogs => '日誌';

  @override
  String get settingsLogsSub => '錯誤日誌、mpv 日誌';

  @override
  String get settingsAccounts => '帳號';

  @override
  String get settingsAccountsSub => 'B 站、WebDAV';

  @override
  String get settingsUser => '使用者';

  @override
  String get settingsUserSub => '帳戶、隱私、安全';

  @override
  String get settingsAboutSub => '版本、授權';

  @override
  String get settingsLicenses => '開源授權';

  @override
  String get settingsLicensesSub => '本專案引用的開源專案';

  @override
  String get settingsSearch => '搜尋設定';

  @override
  String get openSidebar => '開啟側邊欄';

  @override
  String get settingsPlaceholderEasterEgg => '唔，有什麼問題為什麼不問問神奇的芙莉蓮呢';

  @override
  String storageClearTitle(String label) {
    return '清理$label';
  }

  @override
  String storageClearConfirm(String label) {
    return '確定要清理$label嗎？清理後重新瀏覽圖片會再次下載。';
  }

  @override
  String get storageClear => '清理';

  @override
  String storageCleared(String label) {
    return '$label已清理';
  }

  @override
  String get refreshAction => '重新整理';

  @override
  String get storageCacheSection => '快取';

  @override
  String get storageImageCache => '圖片快取';

  @override
  String get storageCounting => '正在統計…';

  @override
  String storageFileCount(int count, String size) {
    return '$count 個檔案 · $size';
  }

  @override
  String get storageDanmakuCache => '彈幕快取';

  @override
  String storageVideoCount(int count, String size) {
    return '$count 個影片 · $size';
  }

  @override
  String get settingsAutoOfflineCache => '自動離線快取播放過的影片';

  @override
  String get settingsAutoOfflineCacheHint =>
      '觀看過的影片會自動下載到本機（約 2GB 上限，超出自動淘汰最舊），下次開啟直接從本機播放、不再重複拉取；關閉後不再新增快取。';

  @override
  String get storageVideoCache => '離線影片快取';

  @override
  String get storageVideoCacheDesc => '播放過的影片媒體流（容量上限內自動快取、LRU 淘汰），下次開啟直接從本機播放';

  @override
  String get storageMemoryCache => '記憶體圖片快取';

  @override
  String get storageMemoryCacheDesc => '本次執行中已解碼的圖片，結束後自動釋放';

  @override
  String get storageClearing => '正在清理…';

  @override
  String get storageClearAll => '一鍵清理全部快取';

  @override
  String get storageCacheHint =>
      '圖片快取為應用程式私有目錄（image_cache），清理後瀏覽過的評論配圖會重新下載；彈幕快取用於離線彈幕載入。';

  @override
  String get storageClearAllTitle => '清理全部快取';

  @override
  String get storageClearAllConfirm => '將清空圖片快取、彈幕快取與記憶體圖片快取，清理後重新瀏覽圖片會再次下載。';

  @override
  String get storageAllCleared => '快取已全部清理';

  @override
  String get verificationPendingRequests => '待處理請求';

  @override
  String get verificationNoPending => '暫無待處理請求';

  @override
  String verificationIpAddress(String ip) {
    return 'IP 位址：$ip';
  }

  @override
  String verificationNickname(String name) {
    return '暱稱：$name';
  }

  @override
  String verificationRequestTime(String time) {
    return '請求時間：$time';
  }

  @override
  String get verificationRejectInvalid => '無法拒絕：IP 位址無效';

  @override
  String get verificationRejected => '已拒絕連線請求';

  @override
  String get verificationReject => '拒絕';

  @override
  String get verificationAcceptInvalid => '無法接受：IP 位址無效';

  @override
  String get verificationAccepted => '已接受連線請求';

  @override
  String get verificationAccept => '同意';

  @override
  String get startScreenWarning => '我們可能不再更新此專案';

  @override
  String get startScreenTitle => '開始螢幕';

  @override
  String get startScreenGoBack => '向上瀏覽';

  @override
  String get enableStartScreen => '啟用開始螢幕';

  @override
  String get startScreenEnableSubtitle => '允許從 Charm 的 Start 按鈕進入開始螢幕';

  @override
  String get enableCharm => '啟用 Charm';

  @override
  String get charmEnableSubtitle => '在螢幕右側提供 Charm 快捷欄';

  @override
  String get charmGestureTitle => '手勢拉出 Charm';

  @override
  String get charmGestureSubtitle => '從螢幕右邊緣向左滑動或懸停右上角拉出 Charm';

  @override
  String get externalVideo => '外部影片';

  @override
  String get audioChannelName => '影片媒體播放';

  @override
  String get foregroundChannelName => 'Navi 保活';

  @override
  String get foregroundChannelDesc => '主人~保持我在背景執行~';

  @override
  String get foregroundTitle => '保活中';

  @override
  String get foregroundText => '我驗牌';

  @override
  String get drawerBilibiliSearch => 'B站搜尋';

  @override
  String get commentImageLoadFail => '圖片載入失敗';

  @override
  String get commentDetailTitle => '評論詳情';

  @override
  String get commentLikeLoginRequired => '請先登入 B 站帳號（並開啟攜帶 Cookie）後再點讚';

  @override
  String commentLikeFail(String error) {
    return '點讚失敗：$error';
  }

  @override
  String get relatedEmpty => '暫無相關推薦';

  @override
  String get biliLoadFailed => '載入失敗';

  @override
  String countWan(String count) {
    return '$count萬';
  }

  @override
  String countYi(String count) {
    return '$count億';
  }

  @override
  String get searchNoNewContent => '暫無新內容';

  @override
  String get searchNewContentRefreshed => '已為您刷新一組新內容';

  @override
  String get biliDialogNeedLogin => '需要登入';

  @override
  String get biliDialogInteractDesc => '點讚 / 投幣 / 三連等互動需要登入 B 站帳號';

  @override
  String get biliGoLogin => '去登入';

  @override
  String get biliCookieScopeHint => '請在帳號設定中開啟「攜帶 Cookie 請求」與「互動操作」範圍';

  @override
  String get videoTabRelated => '相關影片';

  @override
  String get videoTabComments => '評論';

  @override
  String videoTabCommentsCount(int count) {
    return '評論 $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return '選集 $count';
  }

  @override
  String get videoTabIntro => '簡介';

  @override
  String danmakuWatching(String count) {
    return '$count人正在看';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '已裝填$count條彈幕';
  }

  @override
  String get danmakuToggleOn => '開啟彈幕';

  @override
  String get danmakuDisable => '關閉彈幕';

  @override
  String get danmakuInputHint => '發個友善的彈幕見證當下';

  @override
  String get danmakuToastEmpty => '彈幕內容不能為空';

  @override
  String danmakuToastSendFail(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get danmakuToastSent => '彈幕已傳送';

  @override
  String get videoLikeTooltip => '點讚（長按一鍵三連）';

  @override
  String get videoUnlikeTooltip => '取消點讚';

  @override
  String get videoCoinTooltip => '投幣';

  @override
  String get videoFavTooltip => '收藏';

  @override
  String get videoUnfavTooltip => '取消收藏';

  @override
  String get videoShareLabel => '分享';

  @override
  String videoStatRating(String count) {
    return '$count人評分';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count追番';
  }

  @override
  String videoStatWatching(String count) {
    return '$count人在看';
  }

  @override
  String get videoFollowLabel => '關注';

  @override
  String get videoFollowedLabel => '已關注';

  @override
  String get commentDetailEmpty => '還沒有回覆';

  @override
  String commentDetailNoMore(int count) {
    return '沒有更多回覆了（共 $count 則）';
  }

  @override
  String get commentDetailLoadMore => '滑動載入更多';

  @override
  String get commentDetailRootBadge => '樓主';

  @override
  String get commentDetailDeleted => '(評論已刪除)';

  @override
  String get commentMenuCopy => '複製評論';

  @override
  String get commentMenuSelectText => '選取文字';

  @override
  String get commentDialogTitle => '評論內容';

  @override
  String get commentDialogEmpty => '(這裡空空的)';

  @override
  String get danmakuInputBvPrompt => '請輸入 BV 號';

  @override
  String get danmakuInputCidPrompt => '請輸入 CID';

  @override
  String get danmakuInputCidNumeric => 'CID 必須為純數字';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return '命中本機快取：$count 條彈幕 (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return '獲取成功：$count 條彈幕 (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => '取得失敗';

  @override
  String get danmakuInputTitle => 'Bilibili 彈幕';

  @override
  String get danmakuInputTypeLabel => '類型：';

  @override
  String get danmakuInputBvHint => '輸入 BV 號，將自動取得第一個分P的 CID';

  @override
  String get danmakuInputCidHint => '直接輸入 CID 純數字（例如從 API 取得）';

  @override
  String get danmakuInputFetching => '取得中...';

  @override
  String get danmakuInputFetchDanmaku => '取得彈幕';

  @override
  String get danmakuInputEmpty => '輸入不能為空';

  @override
  String get danmakuCidFetchFail => '無法取得 CID，請檢查 BV 號';

  @override
  String danmakuNoData(String oid) {
    return '未取得彈幕資料（oid=$oid）';
  }

  @override
  String get danmakuSettingsTitle => '彈幕設定';

  @override
  String get danmakuDataSource => '資料來源';

  @override
  String get danmakuDisplayControl => '顯示控制';

  @override
  String get danmakuEnable => '啟用彈幕';

  @override
  String get danmakuSmartMask => '智慧防遮擋';

  @override
  String get danmakuSmartMaskDesc => '識別人物，彈幕不遮擋畫面主體';

  @override
  String get danmakuTypeFilter => '彈幕類型';

  @override
  String get danmakuTypeScroll => '滾動彈幕';

  @override
  String get danmakuTypeTop => '頂部彈幕';

  @override
  String get danmakuTypeBottom => '底部彈幕';

  @override
  String get danmakuTypeAdvanced => '進階彈幕 (BAS)';

  @override
  String get danmakuAdvancedSubtitle => '動畫彈幕，開啟可能影響效能';

  @override
  String get danmakuParameters => '參數調整';

  @override
  String get danmakuScrollSpeed => '滾動速度';

  @override
  String get danmakuOpacity => '不透明度';

  @override
  String get danmakuFontSize => '字體大小';

  @override
  String get danmakuMaxLines => '顯示行數';

  @override
  String danmakuLinesCount(int count) {
    return '$count 行';
  }

  @override
  String get danmakuQuickActions => '快速操作';

  @override
  String get danmakuResetParams => '重設參數';

  @override
  String get danmakuClearDanmaku => '清空彈幕';

  @override
  String get danmakuLoadLocalXml => '載入本機 XML 彈幕';

  @override
  String get danmakuFetchOnline => '取得 Bilibili 線上彈幕';

  @override
  String get danmakuNotLoaded => '尚未載入彈幕';

  @override
  String danmakuLoadedCount(int count) {
    return '已載入 $count 條彈幕';
  }

  @override
  String get danmakuBlockColorful => '彩色彈幕';

  @override
  String get danmakuCloudFilter => '智慧雲端遮蔽';

  @override
  String get danmakuCloudFilterOff => '關閉';

  @override
  String danmakuCloudFilterLevel(int level) {
    return '$level 級';
  }

  @override
  String get danmakuFontSizeFS => '全螢幕字型大小';

  @override
  String danmakuSeconds(int value) {
    return '$value 秒';
  }

  @override
  String get danmakuOthers => '其他';

  @override
  String get danmakuMassiveMode => '海量彈幕';

  @override
  String get danmakuStatic2Scroll => '固定轉滾動';

  @override
  String get danmakuShowArea => '顯示區域';

  @override
  String get danmakuFontWeight => '字體粗細';

  @override
  String get danmakuStrokeWidth => '描邊粗細';

  @override
  String get danmakuScrollDuration => '滾動彈幕時長';

  @override
  String get danmakuStaticDuration => '靜態彈幕時長';

  @override
  String get danmakuLineHeight => '彈幕行高';

  @override
  String danmakuResetTo(String value) {
    return '恢復默認：$value';
  }

  @override
  String get naviAddAction => '新增';

  @override
  String playlistImportAdded(int count) {
    return '已新增 $count 個檔案';
  }

  @override
  String get playlistAddEpisodeTitle => '新增集數';

  @override
  String get playlistTitleLabel => '標題';

  @override
  String get playlistEpisodeHint => '第 1 集';

  @override
  String get playlistVideoUrlLabel => '影片 URL';

  @override
  String get playlistAdd => '新增';

  @override
  String get playlistNameRequired => '請輸入播放清單名稱';

  @override
  String get playlistAtLeastOneVideo => '請至少新增一個影片';

  @override
  String get playlistEditTitle => '編輯播放清單';

  @override
  String get playlistCreateTitle => '建立播放清單';

  @override
  String get playlistNameLabel => '播放清單名稱';

  @override
  String get playlistNameHint => '我的追番清單';

  @override
  String get playlistWebdavMulti => 'WebDAV 多選';

  @override
  String playlistItemsCount(int count) {
    return '$count 集';
  }

  @override
  String get playlistNoItems => '還沒有新增任何影片';

  @override
  String get playlistImportHint => '點擊上方按鈕匯入';

  @override
  String get playlistSaveChanges => '儲存變更';

  @override
  String get playlistEpisodePanelTitle => '選集';

  @override
  String playlistEpisodeCurrent(int index) {
    return '目前：第 $index 集';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what：$message';
  }

  @override
  String get playlistSyncTwoWay => '雙向同步播放清單';

  @override
  String get playlistSyncTwoWaySubtitle => '下載雲端並合併，再上傳合併結果（含背景圖）';

  @override
  String get playlistRestoreFromCloud => '從雲端還原';

  @override
  String get playlistRestoreFromCloudSubtitle => '用雲端資料整體覆寫本機播放清單（含背景圖）';

  @override
  String get playlistUploadToCloud => '上傳到雲端';

  @override
  String get playlistUploadToCloudSubtitle => '把本機播放清單全量上傳（含背景圖，不合併）';

  @override
  String get playlistSyncDanmaku => '同步彈幕快取';

  @override
  String get playlistSyncDanmakuSubtitle => '與雲端彈幕快取互相合併（取較新）';

  @override
  String playlistCreated(String name) {
    return '已建立：$name';
  }

  @override
  String get playlistDeleteTitle => '刪除播放清單';

  @override
  String playlistDeleteConfirm(String name) {
    return '確定要刪除「$name」嗎？';
  }

  @override
  String get playlistNewTooltip => '新增播放清單';

  @override
  String get playlistListTitle => '播放清單';

  @override
  String get playlistCloudSync => '雲端同步';

  @override
  String get playlistMyLists => '我的清單';

  @override
  String get playlistNoLists => '暫無播放清單';

  @override
  String playlistListSummary(int count) {
    return '共 $count 個 · 點擊清單檢視全部劇集';
  }

  @override
  String get playlistEmptyTitle => '還沒有播放清單';

  @override
  String get playlistEmptyHint => '點擊右下角「建立」按鈕新建一個吧';

  @override
  String get playlistResume => '續播';

  @override
  String get playlistEditAction => '編輯';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total 集 · 看到第 $current 集';
  }

  @override
  String get subtitleOff => '關閉字幕';

  @override
  String subtitleTrackFallback(String id) {
    return '軌道 $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return '已載入字幕：$name';
  }

  @override
  String get subtitleWebdavNotConfigured => 'WebDAV 未設定，請先登入';

  @override
  String get subtitleWebdavFolderEmpty => 'WebDAV 字幕資料夾為空';

  @override
  String get subtitleSelectFile => '選擇字幕檔案';

  @override
  String subtitleDownloadFailed(int code) {
    return '字幕下載失敗：HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return '已載入遠端字幕：$name';
  }

  @override
  String subtitleLoadError(String error) {
    return '字幕載入異常：$error';
  }

  @override
  String get subtitlePanelTitle => '字幕 (CC)';

  @override
  String get subtitleLoadLocal => '載入本機字幕';

  @override
  String get subtitleLoadWebdav => '從 WebDAV 載入字幕';

  @override
  String get subtitleFontSize => '字號';

  @override
  String get subtitleFontColor => '字體顏色';

  @override
  String get subtitleBgColor => '背景顏色';

  @override
  String get webdavInputPath => '輸入路徑';

  @override
  String get webdavGoTo => '前往';

  @override
  String get webdavLoginRequired => '請先登入 WebDAV 帳號';

  @override
  String get webdavLoginSubtitle => '設定伺服器後可瀏覽遠端影片';

  @override
  String get webdavLoginSubtitleMulti => '登入後可多選遠端影片建立播放清單';

  @override
  String get webdavRefresh => '重新整理';

  @override
  String get webdavRoot => '根';

  @override
  String get webdavParent => '上層';

  @override
  String get webdavFolderEmpty => '此資料夾為空';

  @override
  String get webdavPullToRefresh => '下拉重新整理試試？';

  @override
  String get webdavSelectVideo => '請選擇影片檔案';

  @override
  String get webdavPlay => '播放';

  @override
  String get webdavMultiSelectTitle => '多選檔案';

  @override
  String get webdavNoSelection => '未選擇檔案';

  @override
  String webdavSelectedCount(int count) {
    return '已選 $count 個影片';
  }

  @override
  String webdavSelectionOrder(String names) {
    return '依選擇順序：$names';
  }

  @override
  String get webdavClear => '清空';

  @override
  String get webdavConfirmSelection => '確認選擇';

  @override
  String get webdavGoLogin => '去登入';

  @override
  String get profileTitle => '個人資訊';

  @override
  String get settingsAvatarTitle => '頭像';

  @override
  String get settingsAvatarSet => '已設定';

  @override
  String get settingsNotSet => '未設定';

  @override
  String get settingsAvatarChangeTooltip => '更換頭像';

  @override
  String get settingsAvatarDeleteTooltip => '刪除頭像';

  @override
  String get settingsAvatarUpdated => '頭像已更新';

  @override
  String settingsPickAvatarFailed(String error) {
    return '選擇頭像失敗：$error';
  }

  @override
  String get settingsAvatarDeleteTitle => '刪除頭像';

  @override
  String get settingsAvatarDeleteConfirm => '確定要刪除目前的頭像嗎？';

  @override
  String get settingsAvatarDeleteConfirmPermanent => '確定要刪除目前的頭像嗎？此操作無法復原。';

  @override
  String get settingsAvatarDeleted => '頭像已刪除';

  @override
  String get settingsNickname => '暱稱';

  @override
  String get settingsNicknameEditTooltip => '編輯暱稱';

  @override
  String get settingsSetNickname => '設定暱稱';

  @override
  String get settingsNicknamePrompt => '請輸入您的暱稱';

  @override
  String get settingsNicknameHint => '輸入暱稱';

  @override
  String get settingsNicknameEmpty => '暱稱不能為空';

  @override
  String get settingsNicknameTooLong => '暱稱長度不能超過 20 個字元';

  @override
  String get settingsNicknameUpdated => '暱稱已更新';

  @override
  String get settingsLockWallpaper => '鎖定螢幕桌布';

  @override
  String get settingsWallpaperCustomSet => '已設定自訂桌布';

  @override
  String get settingsWallpaperDefaultBg => '使用預設深色背景';

  @override
  String get settingsWallpaperUpdated => '桌布已更新';

  @override
  String get settingsWallpaperPickTooltip => '選擇桌布';

  @override
  String get settingsWallpaperDelete => '刪除桌布';

  @override
  String get settingsWallpaperDeleteConfirm => '確定要刪除鎖定螢幕桌布並恢復預設嗎？';

  @override
  String get settingsWallpaperDeleted => '桌布已刪除';

  @override
  String get settingsDecoImage => '右下角裝飾圖';

  @override
  String get settingsDecoImageSet => '已設定 (支援透明 PNG/WebP)';

  @override
  String get settingsDecoImageUpdated => '裝飾圖已更新';

  @override
  String settingsPickImageFailed(String error) {
    return '選擇圖片失敗：$error';
  }

  @override
  String get settingsPickImageTooltip => '選擇圖片';

  @override
  String get settingsDecoImageDelete => '刪除裝飾圖';

  @override
  String get settingsDecoImageDeleteConfirm => '確定要刪除右下角裝飾圖嗎？';

  @override
  String get settingsDecoImageDeleted => '裝飾圖已刪除';

  @override
  String get settingsSize => '大小';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => '透明度';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => '顯示';

  @override
  String get settingsDisplaySubtitle => '主題 · 配色 · 文字 · 縮放';

  @override
  String get settingsAppTheme => '應用程式主題';

  @override
  String settingsCurrentColor(String color) {
    return '目前配色：#$color';
  }

  @override
  String get settingsFontWeight => '文字粗細';

  @override
  String settingsCurrentFontWeight(int weight) {
    return '目前粗細：$weight';
  }

  @override
  String get settingsDisplayScale => '顯示縮放';

  @override
  String settingsCurrentScale(int percent) {
    return '目前比例：$percent%';
  }

  @override
  String get settingsRestrictIp => '限制內網 IP 連線';

  @override
  String get settingsRestrictIpSubtitle => '僅允許 A 類、B 類、C 類內網 IP 位址';

  @override
  String get settingsDefaultPort => '預設連接埠';

  @override
  String get settingsAdjustFontWeight => '調整文字粗細';

  @override
  String settingsFontWeightPreview(int weight) {
    return '預覽：$weight';
  }

  @override
  String get settingsWeightHairline => '極細';

  @override
  String get settingsWeightThin => '細';

  @override
  String get settingsWeightRegular => '一般';

  @override
  String get settingsWeightMedium => '中等';

  @override
  String get settingsWeightBold => '粗體';

  @override
  String get settingsWeightBlack => '極粗';

  @override
  String get settingsFontWeightUpdated => '字體粗細已更新';

  @override
  String get logTitle => '日誌';

  @override
  String get logBackTooltip => '向上瀏覽';

  @override
  String get logRefresh => '重新整理';

  @override
  String get logClearAll => '清空日誌';

  @override
  String get logClearTitle => '清空日誌';

  @override
  String get logClearConfirm => '將刪除 error/ 與 mpv/ 目錄下的全部日誌檔案，確定嗎？';

  @override
  String get logClearAction => '清空';

  @override
  String logDeletedCount(int count) {
    return '已刪除 $count 個日誌檔案';
  }

  @override
  String get logCopyContent => '複製內容';

  @override
  String get logShare => '分享日誌';

  @override
  String get logDeleteThis => '刪除此日誌';

  @override
  String get logEmptyContent => '（空日誌）';

  @override
  String logStorageLocation(String path) {
    return '儲存位置：$path';
  }

  @override
  String get logErrorSection => '錯誤日誌（當機時必寫）';

  @override
  String get logNoErrorLogs => '暫無錯誤日誌';

  @override
  String get logMpvSection => 'mpv 日誌（選用）';

  @override
  String get logNoMpvLogs => '暫無 mpv 日誌';

  @override
  String get logReadingLogs => '正在讀取日誌…';

  @override
  String get lockFollowThemeColor => '跟隨主題色 (時間)';

  @override
  String get lockShowBattery => '顯示電池';

  @override
  String get lockShowNetwork => '顯示網路';

  @override
  String lockDate(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get weekdaySunday => '星期日';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get myQrSelectIpHint => '點擊選擇二維碼使用的 IP';

  @override
  String get myQrNoIpType => '沒有此類型的 IP';

  @override
  String get myQrInUse => '使用中';

  @override
  String get myQrSetAsQr => '設為二維碼';

  @override
  String get netLanDiscoveryPort => '本機探索連接埠';

  @override
  String netDohNoRecord(String domain) {
    return '查無 $domain 的 A 紀錄';
  }

  @override
  String netDohQueryFailed(String error) {
    return '查詢失敗：$error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return '已儲存對應：$domain → $ip';
  }

  @override
  String get netAddHostMapping => '新增 Host 對應';

  @override
  String get netDomainLabel => '網域名稱';

  @override
  String get netIpLabel => 'IP 位址';

  @override
  String get netAdd => '新增';

  @override
  String netMappingAdded(String host, String ip) {
    return '已新增對應：$host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return '已移除對應：$host';
  }

  @override
  String get netTitle => '網路';

  @override
  String get netBackTooltip => '向上瀏覽';

  @override
  String get netRetestAll => '全部重新測試';

  @override
  String get netConnectionModeSection => '連線模式';

  @override
  String get netNetworkMode => '網路模式';

  @override
  String get netModeStandardLabel => '標準模式';

  @override
  String get netModeCompatLabel => '相容直連';

  @override
  String get netModeStandardDesc => '使用系統預設網路堆疊';

  @override
  String get netAllowInsecureCert => '允許不安全的憑證';

  @override
  String get netAllowInsecureCertDesc => '相容直連時略過憑證驗證（IP 直連情境）';

  @override
  String get netChatIpv6 => '聊天 IPv6';

  @override
  String get netChatIpv6On => '已開啟：支援 IPv6 聊天、探索與二維碼';

  @override
  String get netChatIpv6Off => '已關閉：僅使用 IPv4 聊天';

  @override
  String get netChatIpv6EnabledSnack => '已開啟聊天 IPv6（重新啟動應用程式後生效）';

  @override
  String get netChatIpv6DisabledSnack => '已關閉聊天 IPv6（重新啟動應用程式後生效）';

  @override
  String get netLocalSendCompat => 'LocalSend 相容';

  @override
  String get netLocalSendCompatOn =>
      '已開啟：啟用 LocalSend 協定（連接埠 53317），可與 LocalSend 官方客戶端互傳檔案';

  @override
  String get netLocalSendCompatOff => '已關閉：使用 navi 原生協定方案';

  @override
  String get netLocalSendCompatEnabledSnack => '已開啟 LocalSend 相容';

  @override
  String get netLocalSendCompatDisabledSnack => '已關閉 LocalSend 相容（恢復原生方案）';

  @override
  String get lsSectionTitle => 'LocalSend 裝置';

  @override
  String get lsHintEnable => 'LocalSend 相容未開啟';

  @override
  String get lsHintEnableDesc =>
      '開啟後可與 LocalSend 官方客戶端（Android/iOS/Windows/macOS/Linux）互傳檔案';

  @override
  String get lsEnableNow => '開啟';

  @override
  String get lsEnabledSnack => '已開啟 LocalSend 相容';

  @override
  String get lsNoDevices => '未發現 LocalSend 裝置';

  @override
  String get lsHttpScan => 'HTTP 掃描';

  @override
  String get lsHttpScanning => '正在掃描區域網路（群播不通時的備援）...';

  @override
  String get lsHttpScanDone => '掃描完成';

  @override
  String get lsSendFile => '傳送檔案';

  @override
  String get lsSendFileDesc => '透過 LocalSend 協定傳送到該裝置';

  @override
  String get lsProbe => '重新探測';

  @override
  String get lsProbing => '正在探測...';

  @override
  String get lsProbeFound => '探測成功';

  @override
  String get lsProbeNotFound => '裝置無回應';

  @override
  String lsPickFailed(String error) {
    return '選擇檔案失敗：$error';
  }

  @override
  String get lsNoPath => '無法取得檔案路徑';

  @override
  String lsSendingTitle(String alias) {
    return '正在傳送到 $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '成功傳送 $count 個檔案';
  }

  @override
  String lsSendFailed(int count) {
    return '有 $count 個檔案傳送成功，其餘失敗';
  }

  @override
  String get lsReceiveRequestTitle => '接收檔案請求';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return '對方傳送了 $count 個檔案，共 $size';
  }

  @override
  String get lsAccept => '接受';

  @override
  String get lsReject => '拒絕';

  @override
  String get lsOpenFile => '開啟檔案';

  @override
  String get lsReceiveCompleteTitle => '檔案接收完成';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName 已儲存到：\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return '已接收檔案：$fileName';
  }

  @override
  String get netConnectivitySection => '連通性測試';

  @override
  String get netHostMappingSection => 'Host 對應';

  @override
  String get netMappingReset => '已恢復內建預設 IP 表';

  @override
  String get netRestoreDefaults => '恢復預設';

  @override
  String get netNoMappings => '暫無對應';

  @override
  String get netAddMapping => '新增對應';

  @override
  String get netDohQuerySection => 'DoH 查詢';

  @override
  String get netDohQueryDesc =>
      '透過 Cloudflare JSON DNS API 查詢網域名稱 A 紀錄，結果可一鍵儲存為 Host 對應';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => '儲存為對應';

  @override
  String get netHeadersSection => '要求標頭';

  @override
  String get netRefererNotSet => '未設定（範例：https://www.bilibili.com/）';

  @override
  String get netNotSet => '未設定';

  @override
  String netHeaderEditorTitle(String title) {
    return '設定 $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title 已儲存';
  }

  @override
  String get ossTitle => '開放原始碼授權';

  @override
  String get ossBackTooltip => '向上瀏覽';

  @override
  String get ossThanks => '致謝';

  @override
  String ossSummary(int count) {
    return '本專案以 Flutter 建置，共引用 $count 個開放原始碼專案，涵蓋 MIT、Apache-2.0 與 BSD-3-Clause 授權。點擊項目即可查看完整授權文字，感謝所有開放原始碼作者無私的貢獻。';
  }

  @override
  String ossGroupCount(String name, int count) {
    return '$name · $count 項';
  }

  @override
  String get ossCopyFullText => '複製全文';

  @override
  String get ossLicenseCopied => '授權文字已複製到剪貼簿';

  @override
  String get playHistoryTitle => '播放記錄';

  @override
  String get playHistoryBackTooltip => '向上瀏覽';

  @override
  String get playHistoryClearAll => '清空全部';

  @override
  String get playHistoryEmpty => '這裡空空的';

  @override
  String get playHistoryEmptySub => '嗯，今天真是寂寞如雪啊';

  @override
  String get playHistoryClearTitle => '清空播放記錄';

  @override
  String get playHistoryClearConfirm => '您確定要刪除所有已儲存的播放進度嗎？此操作無法復原。';

  @override
  String get playHistoryClearAction => '清空';

  @override
  String get playHistoryResume => '繼續播放';

  @override
  String get playHistoryDeleteRecord => '刪除記錄';

  @override
  String playHistoryDeleted(String title) {
    return '已刪除「$title」的播放記錄';
  }

  @override
  String get timeJustNow => '剛剛';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get playerArtistVideo => '影片播放';

  @override
  String get playerArtistPlaylist => '播放清單';

  @override
  String get playerArtistWebdav => 'WebDAV 影片';

  @override
  String get playerWebdavSubtitle => 'WebDAV 字幕';

  @override
  String playerResumeFrom(String position) {
    return '已從 $position 繼續播放';
  }

  @override
  String playerNowPlaying(String title) {
    return '正在播放：$title';
  }

  @override
  String playerDanmakuCache(int count) {
    return '彈幕快取（$count 條）';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili 彈幕（$count 條）';
  }

  @override
  String get playerDanmakuNoData => '未解析到彈幕資料';

  @override
  String playerDanmakuLoaded(int count) {
    return '已載入 $count 條彈幕';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili 線上彈幕（$count 條）';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return '已從本機快取載入 $count 條彈幕';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return '已載入 $count 條線上彈幕';
  }

  @override
  String playerScreenshotFailed(String error) {
    return '截圖失敗：$error';
  }

  @override
  String get playerSavedToAlbum => '已儲存到相簿';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return '截圖 $fileName 已儲存到相簿';
  }

  @override
  String playerSaveFailed(String error) {
    return '儲存失敗：$error';
  }

  @override
  String playerPipFailed(String error) {
    return '子母畫面呼叫失敗：$error';
  }

  @override
  String get playerFitAdapt => '適配';

  @override
  String get playerFitStretch => '拉伸';

  @override
  String get playerFitFill => '填滿';

  @override
  String get playerEndPause => '播完暫停';

  @override
  String get playerEndLoop => '循環播放';

  @override
  String get playerEndExit => '播完結束';

  @override
  String get playerSubtitleSettings => '字幕設定';

  @override
  String get playerAdvancedSettings => '進階設定';

  @override
  String get playerFlipHorizontal => '水平鏡像';

  @override
  String get playerFlipHorizontalDesc => '左右翻轉畫面';

  @override
  String get playerFlipVertical => '垂直翻轉';

  @override
  String get playerFlipVerticalDesc => '上下翻轉畫面';

  @override
  String get playerShowStats => '顯示影片統計資訊';

  @override
  String get playerShowStatsDesc => '編碼/解析度/位元率/幀率';

  @override
  String get playerAutoPip => '回到桌面自動子母畫面';

  @override
  String get playerLoadDanmakuOnResume => '恢復播放時載入彈幕';

  @override
  String get playerLoadDanmakuOnResumeDesc => '從播放記錄繼續時自動讀取/取得彈幕';

  @override
  String get playerDefaultRate => '預設播放速度';

  @override
  String get playerDefaultEndBehavior => '預設結束行為';

  @override
  String get playerBuffering => '緩衝中…';

  @override
  String get playerHwdecSoftware => '軟解（SW）';

  @override
  String playerHwdecHardware(String mode) {
    return '硬解（$mode）';
  }

  @override
  String get playerSourceLocal => '本機檔案';

  @override
  String get playerStatResolution => '解析度';

  @override
  String get playerStatVideoCodec => '影片編碼';

  @override
  String get playerStatAudioCodec => '音訊編碼';

  @override
  String get playerStatBitrate => '位元率';

  @override
  String get playerStatFps => '幀率';

  @override
  String get playerStatDecode => '解碼';

  @override
  String get playerStatSubtitle => '字幕';

  @override
  String get playerOn => '開啟';

  @override
  String get playerOff => '關閉';

  @override
  String get playerStatDanmaku => '彈幕';

  @override
  String get playerStatDownload => '下載';

  @override
  String get playerStatSource => '來源';

  @override
  String get playerStatPosition => '進度';

  @override
  String get playerStatDuration => '時長';

  @override
  String get playerCopyLink => '複製影片連結';

  @override
  String playerCopyLinkAt(String time) {
    return '複製空降連結（$time）';
  }

  @override
  String get playerCopyLinkAt0 => '複製空降連結';

  @override
  String playerCopyLinkDone(String url) {
    return '已複製：$url';
  }

  @override
  String get playerCopyLinkNotBili => '僅 B 站影片支援複製連結';

  @override
  String get playerColorAdjust => '影片色彩調整';

  @override
  String get playerColorBrightness => '亮度';

  @override
  String get playerColorContrast => '對比度';

  @override
  String get playerColorSaturation => '飽和度';

  @override
  String get playerColorHue => '色相';

  @override
  String get playerColorGamma => '伽馬';

  @override
  String get playerColorReset => '重設';

  @override
  String get playerColorUnavailable => '目前播放器不支援色彩調整';

  @override
  String get playerStats => '統計資訊';

  @override
  String get playerAlignAspectRatio => '對齊寬高比';

  @override
  String get playerAlignAspectRatioDone => '視窗已對齊影片比例';

  @override
  String get playerAlignAspectRatioFailed => '無法取得影片尺寸';

  @override
  String get commonClose => '關閉';

  @override
  String get playerPlaybackError => '播放錯誤';

  @override
  String playerAllEpisodesPlayed(int count) {
    return '已播放完全部 $count 集';
  }

  @override
  String playerFastForwarding(String rate) {
    return '$rate 倍速播放中';
  }

  @override
  String get playerTapToSave => '點我儲存';

  @override
  String get playerResetScreen => '還原螢幕';

  @override
  String get playerBackTooltip => '向上瀏覽';

  @override
  String get playerRotate90 => '旋轉90度';

  @override
  String get playerQuality => '畫質';

  @override
  String get playerQualityLocked => '該畫質不可用（需登入或大會員）';

  @override
  String get playerFullscreen => '全螢幕';

  @override
  String get playerBiliSubtitle => 'B站字幕';

  @override
  String get playerDecodeFormat => '解碼格式';

  @override
  String get playerDecodeFormatSwitchFailed => '切換解碼格式失敗';

  @override
  String get playerDecodeAuto => '自動';

  @override
  String get playerDecodeAutoShort => '自動';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => '字幕載入失敗';

  @override
  String get playerPortraitMode => '直屏模式';

  @override
  String get playerLandscapeMode => '橫屏模式';

  @override
  String get playerDescription => '簡介';

  @override
  String get playerWebdavSource => 'WebDAV 影片來源';

  @override
  String get playerCast => '投屏';

  @override
  String get playerWatchTogether => '一起看';

  @override
  String get watchInviteTitle => '邀請你一起看影片';

  @override
  String get watchWaitingAccept => '等待對方接受…';

  @override
  String get watchSelectPeer => '選擇一起看的好友';

  @override
  String get watchNoOnlinePeer => '沒有線上的聯絡人';

  @override
  String watchInviteSent(String name) {
    return '已發送一起看邀請給 $name';
  }

  @override
  String watchActiveWith(String name) {
    return '正在與 $name 一起看';
  }

  @override
  String get watchPeerRejected => '對方拒絕了你的邀請';

  @override
  String get watchPeerNoAnswer => '對方沒有接受邀請';

  @override
  String get watchPeerLeft => '對方已退出一起看';

  @override
  String get watchTcpFailed => '無法建立連線，一起看失敗';

  @override
  String get watchConnectionDropped => '連線已中斷，一起看失敗';

  @override
  String get watchUrlInvalid => '影片位址不可用，無法發起一起看';

  @override
  String get rcInviteTitle => '請求遠端控制你的裝置';

  @override
  String get rcInviteHint => '同意後對方可以看到你的螢幕並操作你的裝置';

  @override
  String get rcPeerRejected => '對方拒絕了遠端控制請求';

  @override
  String get rcTcpFailed => '無法建立連線，遠端控制失敗';

  @override
  String get rcConnectionDropped => '連線已中斷，遠端控制失敗';

  @override
  String get rcTimeout => '等待對方回應超時';

  @override
  String get rcShizukuNotInstalled => '對方裝置未安裝 Shizuku';

  @override
  String get rcShizukuNotInstalledHint =>
      '被控端需要安裝並啟動 Shizuku 服務（shizuku.rikka.app）';

  @override
  String get rcShizukuGrantTitle => '需要 Shizuku 授權';

  @override
  String get rcShizukuGrantHint => '被控端授予 Navi Shizuku 權限後，對方才能遠端操作螢幕';

  @override
  String get rcShizukuGrant => '授權 Shizuku';

  @override
  String get rcRequesting => '請求中…';

  @override
  String get rcShizukuNotGranted => 'Shizuku 未授權';

  @override
  String rcScreenCaptureFailed(String error) {
    return '螢幕擷取失敗：$error';
  }

  @override
  String get rcShareFailed => '螢幕分享失敗';

  @override
  String get rcRetry => '重試';

  @override
  String get rcClose => '關閉';

  @override
  String get rcCancel => '取消';

  @override
  String get rcSend => '傳送';

  @override
  String get rcConnecting => '正在連接…';

  @override
  String rcControlling(String name) {
    return '正在遠端控制 $name';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name 正在遠端控制你的裝置';
  }

  @override
  String get rcEnd => '結束遠端控制';

  @override
  String get rcConnectionLost => '遠端控制連線已中斷';

  @override
  String get rcSessionEnded => '遠端控制已結束';

  @override
  String get rcInputText => '輸入文字';

  @override
  String get rcInputTextHint => '要傳送到對方裝置上的文字';

  @override
  String get rcKeyBack => '返回';

  @override
  String get rcKeyHome => '主頁';

  @override
  String get rcKeyRecents => '最近工作';

  @override
  String get rcKeyVolumeUp => '音量+';

  @override
  String get rcKeyVolumeDown => '音量-';

  @override
  String get dlnaPageTitle => '投屏';

  @override
  String get dlnaRefresh => '重新搜尋';

  @override
  String get dlnaSearching => '正在搜尋區域網路投屏裝置…';

  @override
  String get dlnaNoDevice => '未發現可投屏裝置';

  @override
  String get dlnaNoDeviceHint => '請確認電視/盒子與本機處於同一區域網路，且已開啟 DLNA/投屏功能';

  @override
  String get dlnaSearchAgain => '重新搜尋';

  @override
  String get dlnaFoundDevices => '發現裝置';

  @override
  String dlnaCastStarted(String device) {
    return '已投屏到 $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return '投屏失敗：$device';
  }

  @override
  String dlnaCastingTo(String device) {
    return '正在投屏到 $device';
  }

  @override
  String get dlnaStopCast => '停止投屏';

  @override
  String get dlnaPlay => '播放';

  @override
  String get dlnaPause => '暫停';

  @override
  String get dlnaVolumeUp => '增大音量';

  @override
  String get dlnaVolumeDown => '減小音量';

  @override
  String get dlnaFileMissing => '影片檔案不存在';

  @override
  String dlnaServerStartFailed(String error) {
    return '本地檔案服務啟動失敗：$error';
  }

  @override
  String get playerEpisodeSelect => '選集';

  @override
  String get playerDanmakuSettings => '彈幕設定';

  @override
  String get psTitle => '播放器';

  @override
  String get psBackTooltip => '向上瀏覽';

  @override
  String get psStaffEntrance => '員工通道';

  @override
  String get psDisplaySection => '顯示';

  @override
  String get psStatusBar => '狀態列';

  @override
  String get psStatusBarDesc => '在播放器頂端顯示時間、電量與網路圖示';

  @override
  String get psKeepWindowRatio => '等比例鎖定視窗';

  @override
  String get psKeepWindowRatioDesc => '播放時視窗僅允許依目前比例縮放';

  @override
  String get psKeepWindowRatioDesktopOnly => '僅 Windows / macOS / Linux 桌面平台生效';

  @override
  String get psInteractionSection => '互動';

  @override
  String get psLongPressSpeed => '長按加速';

  @override
  String get psLongPressSpeedDesc => '長按螢幕或鍵盤 D 鍵以 2× 倍速快轉';

  @override
  String get psScreenshot => '截圖功能';

  @override
  String get psScreenshotDesc => '允許在播放器中擷取目前畫面並儲存至相簿';

  @override
  String get psScreenshotDanmaku => '截圖時顯示彈幕';

  @override
  String get psScreenshotDanmakuDesc => '截圖時將目前彈幕一併擷入畫面';

  @override
  String get psProgressSection => '進度';

  @override
  String get psPlayProgress => '播放進度';

  @override
  String get psNoHistory => '暫無已儲存的播放記錄';

  @override
  String psHistoryCount(int count) {
    return '您有 $count 筆記錄';
  }

  @override
  String get psMiscSection => '其他';

  @override
  String get psHwdec => '硬體解碼';

  @override
  String get psHwdecAuto => '自動選擇最佳解碼器';

  @override
  String get psHwdecSoftware => '強制使用 CPU 軟體解碼';

  @override
  String get psHwdecAutoShort => '自動';

  @override
  String get psHwdecPureSoftware => '純軟解';

  @override
  String get psVideoSync => '影片同步';

  @override
  String get psVsyncAudioDefault => '以音訊時鐘為基準（預設）';

  @override
  String get psVsyncResample => '重新取樣音訊以符合顯示更新率';

  @override
  String get psVsyncAdrop => '丟棄 / 重複音訊影格以符合顯示';

  @override
  String get psVsyncVdrop => '丟棄 / 重複影片影格以符合顯示';

  @override
  String get psVsyncAudio => '音訊';

  @override
  String get psVsyncDisplayResample => '顯示重取樣';

  @override
  String get psVsyncDisplayAdrop => '顯示音訊丟棄';

  @override
  String get psVsyncDisplayVdrop => '顯示影片丟棄';

  @override
  String get psImmersiveLongPress => '沉浸模式長按加速';

  @override
  String get psImmersiveLongPressDesc => '控制列隱藏時仍可透過長按觸發 2× 倍速';

  @override
  String get psLogSection => '日誌';

  @override
  String get psMpvLog => '記錄 mpv 日誌';

  @override
  String psMpvLogEnabled(String level) {
    return '已開啟，下次播放生效（細度：$level）';
  }

  @override
  String get psMpvLogDisabled => '關閉。當機日誌始終記錄，不受此開關影響';

  @override
  String get psMpvLogLevel => 'mpv 日誌細度';

  @override
  String get psMpvLogLevelDesc => '細度越高日誌越詳細，佔用空間也越大';

  @override
  String get psMpvLogError => '僅錯誤';

  @override
  String get psMpvLogWarn => '警告';

  @override
  String get psMpvLogWarnDefault => '警告（預設）';

  @override
  String get psMpvLogInfo => '資訊';

  @override
  String get psMpvLogVerbose => '詳細';

  @override
  String get psMpvLogDebug => '除錯';

  @override
  String get psMpvLogTrace => '全部（極詳細）';

  @override
  String get psViewLogs => '檢視日誌';

  @override
  String get psViewLogsDesc => '瀏覽錯誤日誌與 mpv 日誌，支援分享與清除';

  @override
  String testPlaylistCreated(String name) {
    return '已建立：$name';
  }

  @override
  String get testPageTitle => '測試頁';

  @override
  String get testVideoSourceSection => '影片來源';

  @override
  String get testVideoSourceSubtitle => '選擇一個來源開始播放';

  @override
  String get testWebdavVideo => 'WebDAV 影片';

  @override
  String get testWebdavVideoDesc => '從 WebDAV 伺服器瀏覽並播放';

  @override
  String get testLocalVideo => '本機影片';

  @override
  String get testLocalVideoDesc => '從裝置儲存空間選擇影片檔案';

  @override
  String get testRecentSection => '最近播放';

  @override
  String get testLastPlayedSubtitle => '上次播放記錄';

  @override
  String get testNoRecords => '暫無播放記錄';

  @override
  String get testPlaylistSection => '播放清單';

  @override
  String get testPlaylistSectionSubtitle => '建立、管理播放清單，選集播放';

  @override
  String get testPlaylistManage => '播放清單管理';

  @override
  String get testPlaylistManageDesc => '檢視 / 編輯 / 刪除播放清單，點擊直接播放';

  @override
  String get testPlaylistCreate => '新增播放清單';

  @override
  String get testPlaylistCreateDesc => 'WebDAV 多選檔案建表 / 手動逐集匯入';

  @override
  String get testQuickActionsSection => '快速操作';

  @override
  String get testQuickActionsSubtitle => '常用測試入口';

  @override
  String get testUrlDirectPlay => 'URL 直接播放';

  @override
  String get testUrlDirectPlayDesc => '輸入影片 URL 直接播放';

  @override
  String get testVideoWithSubtitle => '影片 + 字幕';

  @override
  String get testVideoWithSubtitleDesc => '同時選擇影片和字幕檔案';

  @override
  String get testNoVideoPlayed => '還沒有播放過任何影片';

  @override
  String get testEnterUrlTitle => '輸入影片 URL';

  @override
  String get testPlay => '播放';

  @override
  String get testAddSubtitleTitle => '新增字幕？';

  @override
  String testAddSubtitlePrompt(String name) {
    return '已選擇影片：$name\n是否要載入外掛字幕？';
  }

  @override
  String get testSkip => '略過';

  @override
  String get testSelectSubtitle => '選擇字幕';

  @override
  String get testAboutLegalese => '播放器前端測試頁面';

  @override
  String get testAboutBody =>
      '此頁面用於測試 MpvPlayerPage 的各種入口：\n• WebDAV 遠端影片\n• 本機影片檔案\n• URL 直接播放\n• 影片 + 外掛字幕';

  @override
  String get testSourceLocal => '本機檔案';

  @override
  String get testSourceLocalSubtitle => '本機 + 字幕';

  @override
  String get accountsBiliLoginSuccess => 'B 站登入成功';

  @override
  String get accountsBiliLogoutTitle => '退出 B 站登入？';

  @override
  String get accountsBiliLogoutHint => '登出後將不再攜帶 Cookie 請求 B 站 API。';

  @override
  String get accountsClearWebviewCookieTitle => '同時清除內建瀏覽器 Cookie';

  @override
  String get accountsClearWebviewCookieSubtitle => '不勾選也沒關係，之後可在帳號設定中手動清除';

  @override
  String get accountsLogout => '登出';

  @override
  String get accountsLoggedOutWithCookie => '已登出並清除瀏覽器 Cookie';

  @override
  String get accountsLoggedOut => '已登出';

  @override
  String get accountsClearCookieTitle => '清除內建瀏覽器 Cookie？';

  @override
  String get accountsClearCookieContent => '將清除內建瀏覽器儲存的全部 Cookie，包含網頁端的登入狀態。';

  @override
  String get accountsClearAction => '清除';

  @override
  String get accountsCookieCleared => '已清除內建瀏覽器 Cookie';

  @override
  String get accountsCookieEmpty => '暫無內建瀏覽器 Cookie 可清除（瀏覽器未使用過）';

  @override
  String get accountsBiliLoginTitle => '登入 B 站帳號';

  @override
  String get accountsBiliLoginSubtitle => '掃碼 / 貼上 Cookie / 密碼登入';

  @override
  String get accountsClearBrowserCookie => '清除內建瀏覽器 Cookie';

  @override
  String get accountsClearBrowserCookieSubtitle => '清除網頁端殘留登入狀態';

  @override
  String get accountsLoggedIn => '已登入';

  @override
  String accountsLoggedInUid(int mid) {
    return '已登入 · UID $mid';
  }

  @override
  String get accountsCarryCookie => '攜帶 Cookie 請求';

  @override
  String get accountsCarryCookieOn => '已開啟：B 站 API 以登入身份請求';

  @override
  String get accountsCarryCookieOff => '已關閉：B 站 API 以訪客身份請求';

  @override
  String get accountsCookieScope => 'Cookie 使用範圍';

  @override
  String get accountsCookieScopeSubtitle => '選擇哪些請求使用帳號 Cookie';

  @override
  String get cookieScopeTitle => 'Cookie 使用範圍';

  @override
  String get cookieScopeHint =>
      '僅影響以下請求類型；「攜帶 Cookie 請求」總開關關閉時，下列設定不生效。B 站在線收藏夾操作始終攜帶登入 Cookie。';

  @override
  String get cookieScopeVideo => '影片詳情與播放';

  @override
  String get cookieScopeVideoDesc => '影片詳情、播放位址與歷史進度回報';

  @override
  String get cookieScopeComments => '評論';

  @override
  String get cookieScopeCommentsDesc => '評論區列表請求';

  @override
  String get cookieScopeSearch => '搜尋';

  @override
  String get cookieScopeSearchDesc => '搜尋建議與搜尋結果請求';

  @override
  String get cookieScopeArticle => '專欄與動態';

  @override
  String get cookieScopeArticleDesc => '專欄文章與動態內容請求';

  @override
  String get cookieScopeUserSpace => '使用者空間';

  @override
  String get cookieScopeUserSpaceDesc => 'UP 主空間、投稿與粉絲列表請求';

  @override
  String get cookieScopeSeason => '番劇與劇集';

  @override
  String get cookieScopeSeasonDesc => '番劇詳情與劇集列表請求';

  @override
  String get cookieScopeInteractions => '互動操作';

  @override
  String get cookieScopeInteractionsDesc => '按讚、投幣、收藏、追蹤、發送彈幕等；關閉後無法互動';

  @override
  String get cookieScopeEnableAll => '全部開啟';

  @override
  String get cookieScopeDisableAll => '全部關閉';

  @override
  String get accountsWebdavCloud => 'WebDAV 雲端硬碟';

  @override
  String get accountsWebdavConfiguredOn => '已設定 · 自動備份已開啟';

  @override
  String get accountsWebdavConfiguredOff => '已設定 · 自動備份未開啟';

  @override
  String get accountsWebdavNotConfigured => '未設定 · 點擊進入設定';

  @override
  String get accountsTitle => '帳號';

  @override
  String get accountsSectionBili => 'B 站帳號';

  @override
  String get commonBackTooltip => '向上瀏覽';

  @override
  String get biliLoginFetchingQr => '正在取得 QR Code…';

  @override
  String get biliLoginQrFetchFailed => '取得 QR Code 失敗，請檢查網路';

  @override
  String get biliLoginScanWithApp => '請使用 B 站 App 掃碼登入';

  @override
  String get biliLoginInputAccountPwd => '請輸入帳號和密碼';

  @override
  String get biliLoginFailedRetry => '登入失敗，請重試';

  @override
  String get biliLoginTitle => 'B 站登入';

  @override
  String get biliLoginScanMode => '掃碼登入';

  @override
  String get biliLoginCookieMode => '貼上 Cookie';

  @override
  String get biliLoginPwdMode => '密碼登入';

  @override
  String get biliLoginViaBrowser => '使用內建瀏覽器登入';

  @override
  String get biliLoginCookieHint => '登入後「攜帶 Cookie 請求」預設開啟，可在 設定 → 帳號 中關閉';

  @override
  String get biliLoginWebTitle => '網頁版登入';

  @override
  String get biliLoginCookieImportFailed => '網頁登入 Cookie 匯入失敗，請重試或改用其他方式';

  @override
  String get biliLoginRefetch => '重新取得';

  @override
  String get biliLoginRefreshQr => '重新整理 QR Code';

  @override
  String get biliLoginScanTip => '提示：開啟 B 站 App → 掃一掃，或使用「嗶哩嗶哩」小程式掃碼';

  @override
  String get biliLoginCookieInstruction =>
      '在電腦瀏覽器登入 bilibili.com，按 F12 開啟開發者工具 → Application → Cookies → bilibili.com，複製全部 Cookie（以 SESSDATA= 開頭的一串），貼到下方輸入框';

  @override
  String get biliLoginVerifying => '驗證中…';

  @override
  String get biliLoginVerifyAndLogin => '登入並驗證';

  @override
  String get biliLoginAccountLabel => '帳號（手機號碼 / 信箱 / 使用者名稱）';

  @override
  String get biliLoginPasswordLabel => '密碼';

  @override
  String get biliLoginLoggingIn => '登入中…';

  @override
  String get biliLoginLoginAction => '登入';

  @override
  String get biliLoginSliderHint => '帳號密碼登入可能觸發滑塊驗證碼，完成驗證後會自動重試';

  @override
  String get searchFilterAny => '不限';

  @override
  String get searchFilterLastDay => '最近一天';

  @override
  String get searchFilterLastWeek => '最近一週';

  @override
  String get searchFilterHalfYear => '最近半年';

  @override
  String get searchFilterAllDuration => '全部時長';

  @override
  String get searchFilterDur0to10 => '0-10 分鐘';

  @override
  String get searchFilterDur10to30 => '10-30 分鐘';

  @override
  String get searchFilterDur30to60 => '30-60 分鐘';

  @override
  String get searchFilterDur60plus => '60 分鐘以上';

  @override
  String get searchZoneAll => '全部';

  @override
  String get searchZoneAnime => '動畫';

  @override
  String get searchZoneGuochuang => '國創';

  @override
  String get searchZoneMusic => '音樂';

  @override
  String get searchZoneDance => '舞蹈';

  @override
  String get searchZoneGame => '遊戲';

  @override
  String get searchZoneKnowledge => '知識';

  @override
  String get searchZoneTech => '科技';

  @override
  String get searchZoneSports => '運動';

  @override
  String get searchZoneCar => '汽車';

  @override
  String get searchZoneLife => '生活';

  @override
  String get searchZoneFood => '美食';

  @override
  String get searchZoneAnimal => '動物';

  @override
  String get searchZoneKichiku => '鬼畜';

  @override
  String get searchZoneFashion => '時尚';

  @override
  String get searchZoneInfo => '資訊';

  @override
  String get searchZoneEnt => '娛樂';

  @override
  String get searchZoneDoc => '紀錄';

  @override
  String get searchZoneFilm => '電影';

  @override
  String get searchZoneTv => '電視';

  @override
  String get searchCaptchaInitFailed => '驗證碼初始化失敗';

  @override
  String get searchCaptchaIncomplete => '未完成滑塊驗證';

  @override
  String get searchCaptchaValidateFailed => '驗證碼校驗失敗';

  @override
  String get searchCaptchaValidateFailedRetry => '驗證碼校驗失敗，請重試';

  @override
  String get searchCaptchaPassed => '驗證通過，正在重新搜尋';

  @override
  String get searchBiliHint => '搜尋 B 站…';

  @override
  String get searchHistoryTitle => '搜尋歷史';

  @override
  String get searchHistoryClear => '清空';

  @override
  String get searchHistoryClearConfirm => '確定清空目前分區的搜尋歷史？';

  @override
  String get searchHistoryEmpty => '暫無搜尋歷史';

  @override
  String get searchVideoFilter => '影片搜尋篩選';

  @override
  String searchFilterWithCount(int count) {
    return '篩選 · $count';
  }

  @override
  String get searchFilter => '篩選';

  @override
  String get searchSwitchSingleCol => '單欄';

  @override
  String get searchSwitchMulti => '多欄';

  @override
  String get searchLayoutMulti => '多欄';

  @override
  String get searchLayoutSingle => '單欄';

  @override
  String get searchPickStartDate => '選擇開始日期';

  @override
  String get searchPickEndDate => '選擇結束日期';

  @override
  String get searchPubTimeSection => '發佈時間';

  @override
  String get searchDateBegin => '開始';

  @override
  String get searchDateTo => '至';

  @override
  String get searchDateEnd => '結束';

  @override
  String get searchDurationSection => '內容時長';

  @override
  String get searchZoneSection => '內容分區';

  @override
  String get searchAntiFuzzy => '防模糊搜尋';

  @override
  String get searchAntiFuzzyHint => '限定 2009-06-26 至今的結果，避免異常早期資料干擾';

  @override
  String get searchFilterReset => '重設';

  @override
  String get searchAllLoaded => '— 已全部載入 —';

  @override
  String get searchKeywordHint => '輸入關鍵字搜尋 B 站';

  @override
  String get searchPressToSearch => '點擊「搜尋」或按 Enter 開始搜尋';

  @override
  String searchNoResultInType(String keyword, String type) {
    return '「$keyword」在$type中暫無結果';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · 共 $count 個結果';
  }

  @override
  String get userSpaceLoadFailed => '載入失敗';

  @override
  String get userSpaceAvatarLoadFailed => '頭像載入失敗';

  @override
  String get userSpaceTitle => 'UP 主空間';

  @override
  String get userSpaceLoading => '正在載入 UP 主空間…';

  @override
  String get userSpaceLoadingName => '載入中…';

  @override
  String get userSpaceStatFans => '粉絲';

  @override
  String get userSpaceStatFollowing => '關注';

  @override
  String get userSpaceStatVideos => '影片';

  @override
  String get userSpaceStatLikes => '獲讚';

  @override
  String userSpaceVideoCount(int count) {
    return '共 $count 部影片';
  }

  @override
  String get userSpaceSectionAllVideos => '全部影片';

  @override
  String get userSpaceNoVideos => '暫無投稿';

  @override
  String get userSpaceDynLoadFailed => '動態載入失敗';

  @override
  String get userSpaceNoDynamics => '暫無動態';

  @override
  String get userSpaceBangumiLoadFailed => '追番清單載入失敗';

  @override
  String get userSpaceNoBangumi => '暫無追番';

  @override
  String userSpaceBangumiCount(int count) {
    return '追番 · 共 $count 部';
  }

  @override
  String get userSpaceLazySign => '這個人很懶，什麼都沒有留下';

  @override
  String get userSpaceTabHome => '主頁';

  @override
  String get userSpaceTabDynamic => '動態';

  @override
  String get userSpaceTabBangumi => '追番';

  @override
  String get userSpaceToday => '今天';

  @override
  String get userSpaceBangumiFinished => '完結';

  @override
  String get userSpaceBangumiSerializing => '連載中';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return '開播 $date';
  }

  @override
  String get browserApp => '應用程式';

  @override
  String browserOpenAppAttempt(String app) {
    return '網頁嘗試開啟: $app';
  }

  @override
  String get browserNoAppForLink => '找不到可開啟此連結的應用程式';

  @override
  String get browserOpenFailedSystem => '開啟失敗: 未安裝對應應用程式或受系統限制';

  @override
  String get browserEmptyCookieHint => '這裡空空的';

  @override
  String get browserCopyAll => '複製全部';

  @override
  String get browserCookieCopied => 'Cookie 已複製';

  @override
  String get browserCookieEmpty => 'Cookie 空空如也';

  @override
  String get browserSetUaTitle => '設定 User-Agent';

  @override
  String get browserUaHint => '輸入自訂 User-Agent';

  @override
  String get browserApplyAndReload => '套用並重新整理';

  @override
  String get browserUaUpdated => 'UA 已更新並重新整理頁面';

  @override
  String browserUaSetFailed(String error) {
    return '設定 UA 失敗: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView 初始化失敗，請檢查是否已安裝 WebView2';

  @override
  String get browserBiliCookieReadFailed =>
      '無法讀取完整的登入 Cookie（SESSDATA 為 HttpOnly，目前平台無法自動讀取），請改用掃碼登入或貼上 Cookie';

  @override
  String get browserCookieImportFailed => 'Cookie 匯入失敗，請重試';

  @override
  String get browserStoppedLoading => '已停止載入';

  @override
  String get browserClipboardAllowed => '已允許網頁寫入剪貼簿';

  @override
  String get browserClipboardBlocked => '已禁止網頁自動寫入剪貼簿';

  @override
  String get browserNoCurrentUrl => '無法取得目前連結';

  @override
  String get browserTroubleshootFailed => '開啟失敗，請檢查「取得說明」是否存在';

  @override
  String get browserSystemBrowserMissing => '系統瀏覽器不見了(';

  @override
  String get browserQrTitle => '掃我';

  @override
  String get browserSaveToDevice => '儲存到裝置';

  @override
  String get browserQrSaved => 'QR Code 已儲存到相簿/圖片庫';

  @override
  String browserSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get browserStopLoading => '停止載入';

  @override
  String get browserImporting => '匯入中…';

  @override
  String get browserLoginDoneImport => '登入完成，匯入';

  @override
  String get browserClipboardAccess => '剪貼簿存取';

  @override
  String get browserShareQr => '分享 QR Code';

  @override
  String get browserCopyLink => '複製連結';

  @override
  String get browserViewCookies => '檢視 Cookies';

  @override
  String get browserSetUa => '設定 UA';

  @override
  String get browserUaModeAuto => '自動（跟隨系統）';

  @override
  String get browserUaModeDesktop => '電腦端';

  @override
  String get browserUaModeMobile => '手機端';

  @override
  String get browserRefresh => '重新整理';

  @override
  String get browserSystemBrowser => '系統瀏覽器';

  @override
  String get browserTroubleshootNetwork => '偵測連線問題';

  @override
  String get browserUnsupportedPlatform => '目前平台不支援內建瀏覽器';

  @override
  String get browserOpenedInSystem => '已嘗試在系統瀏覽器中開啟';

  @override
  String get browserReopenInSystem => '重新用系統瀏覽器開啟';

  @override
  String get browserAndroidErrorTitle => '沒有指令';

  @override
  String get browserAndroidErrorCause => '原因';

  @override
  String get browserAndroidErrorDetail =>
      'WebView 元件初始化失敗\n可能是系統 WebView 未更新或已停用';

  @override
  String get browserUpdateWebview => '前往 Google Play 更新 Android System WebView';

  @override
  String get browserOpenDevOptions => '開啟開發者選項檢視 WebView 實作';

  @override
  String get browserAppleErrorTitle => '應用程式未預期的結束';

  @override
  String get browserAppleErrorReport => '問題報告';

  @override
  String get browserAppleErrorDetail => '無法在此裝置上初始化內嵌瀏覽器。請確認作業系統已更新至最新版本。';

  @override
  String get browserBsodMessage =>
      '你的 Webview2 發生問題，我們需要收集一些錯誤資訊，然後為你重新啟動應用程式。';

  @override
  String get browserBsodNoRestart => '（其實不用重新啟動，安裝完元件即可）';

  @override
  String get browserBsodComplete => '100% 完成';

  @override
  String get browserBsodSolutions => '檢視解決方案：';

  @override
  String get browserBsodDownload => '下載 Webview2 執行階段';

  @override
  String get browserBsodWinUpdate => '開啟 Windows 更新設定';

  @override
  String get browserBsodScanQr => '掃描此 QR Code 取得解決方案';

  @override
  String get browserBsodStopCode => '終止代碼：WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => '無法開啟外部連結';

  @override
  String get callOutgoing => '正在撥打...';

  @override
  String get callIncoming => '來電...';

  @override
  String get callConnecting => '連線中...';

  @override
  String get chatConnectionNotEstablishedImage => '連線未建立，無法傳送圖片';

  @override
  String get chatImageSent => '✅ 圖片已傳送';

  @override
  String get chatImageSendFailed => '傳送圖片失敗';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return '處理剪貼簿圖片失敗：$error';
  }

  @override
  String get chatImageStaged => '🖼️ 圖片已加入輸入框';

  @override
  String get chatClipboardNoImage => '剪貼簿沒有圖片資料';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return '取得剪貼簿圖片失敗：$error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported => '剪貼簿為空或格式不支援';

  @override
  String get chatConnectionNotEstablishedFile => '連線未建立，無法傳送檔案';

  @override
  String get chatFileNotExist => '檔案不存在';

  @override
  String get chatFileSendFailed => '傳送檔案失敗';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName 傳送成功';
  }

  @override
  String chatFileSendError(String error) {
    return '傳送檔案失敗：$error';
  }

  @override
  String get chatIpUnknown => 'IP 未知';

  @override
  String get chatReconnecting => '正在重新建立連線...';

  @override
  String get chatReconnectFailed => '重新連線失敗，請檢查網路或對方是否在線';

  @override
  String get chatStatusUnknown => '狀態未知';

  @override
  String get chatStatusWaiting => '等待連線';

  @override
  String get chatMe => '我';

  @override
  String get chatFileInfoLost => '（檔案資訊遺失）';

  @override
  String chatOpenFileFailed(String message) {
    return '無法開啟檔案：$message';
  }

  @override
  String get chatFileNotDownloaded => '檔案尚未下載';

  @override
  String chatOpenFileError(String error) {
    return '開啟檔案失敗：$error';
  }

  @override
  String get chatFilePathUnavailable => '無法取得檔案路徑（Android 權限限制？）';

  @override
  String chatPickFileFailed(String error) {
    return '選擇檔案失敗：$error';
  }

  @override
  String get chatImagePathUnavailable => '無法取得圖片路徑';

  @override
  String chatPickImageFailed(String error) {
    return '選擇圖片失敗：$error';
  }

  @override
  String get chatCopyText => '複製文字';

  @override
  String get chatSelectText => '選取文字';

  @override
  String get chatOpenFile => '開啟檔案';

  @override
  String get chatCopyImage => '複製圖片';

  @override
  String get chatSaveImage => '儲存圖片';

  @override
  String get chatCopyingImage => '正在複製圖片...';

  @override
  String get chatImageCopied => '✅ 圖片已複製到剪貼簿';

  @override
  String get chatCopyFailed => '複製失敗';

  @override
  String chatCopyImageFailed(String error) {
    return '複製圖片失敗: $error';
  }

  @override
  String get chatSaving => '正在儲存...';

  @override
  String get chatSaveSuccess => '✅ 儲存成功';

  @override
  String chatSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get chatMessageContent => '訊息內容';

  @override
  String get chatEmptyContent => '（這裡空空的）';

  @override
  String get chatDeleteMessageConfirm => '確定要刪除這則訊息嗎？';

  @override
  String get chatMessageDeleted => '訊息已刪除';

  @override
  String get chatOpenLinkTitle => '開啟連結';

  @override
  String chatWillOpen(String url) {
    return '將開啟：$url';
  }

  @override
  String get chatBrowserTitle => '內建網頁瀏覽器';

  @override
  String get chatCantOpenLink => '無法開啟連結';

  @override
  String chatOpenLinkFailed(String error) {
    return '開啟連結失敗：$error';
  }

  @override
  String get chatPlusImage => '圖片';

  @override
  String get chatPlusFile => '檔案';

  @override
  String get chatImageReady => '圖片已就緒';

  @override
  String get chatMore => '更多';

  @override
  String get chatPasteImage => '貼上圖片';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get chatEmoji => '表情符號';

  @override
  String get chatSend => '傳送';

  @override
  String get chatInvalidAddress => '連線位址無效，無法傳送';

  @override
  String get chatImageSendError => '圖片傳送失敗';

  @override
  String chatSendFailed(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get chatConnStatusUnknown => '連線狀態未知，無法傳送訊息';

  @override
  String get chatPendingCannotSend => '等待對方驗證，無法傳送訊息';

  @override
  String get chatConnRejected => '連線已被拒絕';

  @override
  String get chatConnDisconnected => '對方已中斷連線';

  @override
  String get chatConnNotEstablished => '連線尚未建立，無法傳送訊息';

  @override
  String get chatNoMessages => '暫無訊息，開始聊天吧';

  @override
  String get chatDisconnectedRetry => '連線已中斷，點擊嘗試重新連線';

  @override
  String get chatRejectedRetry => '連線被拒絕，點擊重試';

  @override
  String get chatExpandInput => '展開輸入欄';

  @override
  String get discoverMyLanIps => '我的區域網路 IP';

  @override
  String get discoverNoIpOfType => '找不到此類型的有效 IP，請檢查網路連線。';

  @override
  String discoverIpCopied(String ip) {
    return '已複製 $ip';
  }

  @override
  String get discoverTitle => '發現附近裝置';

  @override
  String get discoverMyIp => '我的 IP';

  @override
  String get discoverRefreshBroadcast => '重新整理/廣播';

  @override
  String get discoverLanDevices => '區域網路裝置';

  @override
  String get discoverSearching => '正在尋找附近的裝置...';

  @override
  String get discoverSendRequest => '點擊傳送連線請求';

  @override
  String get discoverPendingVerify => '等待對方驗證...';

  @override
  String get discoverRejectedRetry => '已被拒絕，點擊重試';

  @override
  String get discoverDisconnectedRetry => '已中斷，點擊重新連線';

  @override
  String get discoverUnknownDevice => '未知裝置';

  @override
  String get discoverAlreadyConnected => '此裝置已連線';

  @override
  String get discoverAlreadyPending => '正在等待對方驗證，請勿重複傳送';

  @override
  String get discoverConnectFailed => '連線失敗，請檢查網路或對方是否在線';

  @override
  String get discoverManualConnect => '手動連線到對等端';

  @override
  String get discoverConnectIpHint => '輸入 IP 位址（例如：192.168.1.100 / fe80::1）';

  @override
  String get displayScaleCompact => '緊湊模式 · 顯示更多內容';

  @override
  String get displayScaleSmall => '略小 · 適合大螢幕';

  @override
  String get displayScaleDefault => '預設';

  @override
  String get displayScaleLarge => '略大 · 更容易閱讀';

  @override
  String get displayScaleLargeFont => '大字體 · 無障礙友善';

  @override
  String get displayScaleHuge => '超大 · 輔助功能';

  @override
  String get displayScaleMin => '最小 · 資訊密度最高';

  @override
  String get displayScaleCompactBig => '緊湊 · 適合大螢幕';

  @override
  String get displayScaleSystemDefault => '系統預設';

  @override
  String get displayScaleLargeFontShort => '大字體 · 無障礙';

  @override
  String get displayScaleTitle => '顯示縮放';

  @override
  String get displayHeroTransitionBlur => '使用新版動畫';

  @override
  String get displayIosPushTransition => 'iOS 風格頁面切換';

  @override
  String get displayIosPushTransitionCorner => '轉場圓角';

  @override
  String get searchIosPushTransition => 'iOS 頁面切換動畫';

  @override
  String get pageBgTitle => '頁面背景圖';

  @override
  String get pageBgSubtitle => '設定類頁面共用的背景圖，選擇後可裁剪';

  @override
  String get pageBgEnabled => '顯示頁面背景圖';

  @override
  String get pageBgOpacity => '背景強度';

  @override
  String get pageBgBlur => '背景模糊';

  @override
  String get pageBgNotSet => '未設置';

  @override
  String get pageBgPick => '選擇並裁剪圖片';

  @override
  String get pageBgClear => '清除背景圖';

  @override
  String get pageBgSaved => '背景圖已更新';

  @override
  String get pageBgCleared => '背景圖已清除';

  @override
  String get pageBgPickFailed => '選擇圖片失敗';

  @override
  String get cropTitle => '裁剪背景圖';

  @override
  String get cropAspectFree => '自由';

  @override
  String get cropApply => '應用';

  @override
  String get cropReset => '重置';

  @override
  String get displayAdvancedGlass => '高級渲染';

  @override
  String get displayDisableLiquidGlassMenus => '減弱效果';

  @override
  String get displayLiquidGlassTuner => '液態玻璃調校';

  @override
  String get displayLiquidGlassTunerSubtitle => '調整玻璃厚度、模糊、著色、折射率等材質參數';

  @override
  String get lgTunerPreview => '即時預覽';

  @override
  String get lgTunerSectionMaterial => '材質參數';

  @override
  String get lgTunerThickness => '玻璃厚度';

  @override
  String get lgTunerBlur => '背景模糊';

  @override
  String get lgTunerTint => '著色強度';

  @override
  String get lgTunerSaturation => '飽和度';

  @override
  String get lgTunerRefractiveIndex => '折射率';

  @override
  String get lgTunerLightIntensity => '高光強度';

  @override
  String get lgTunerAmbient => '環境光';

  @override
  String get lgTunerLightAngle => '光源角度';

  @override
  String get lgTunerAberration => '色散';

  @override
  String get lgTunerReset => '恢復預設';

  @override
  String get lgTunerNote =>
      '調整即時生效並全域套用：未單獨指定參數的玻璃表面（下拉選單、彈窗等）都會跟隨；聊天頁頂欄等顯式設定的表面保持獨立樣式。';

  @override
  String get lgTunerFallbackNote =>
      '目前平台不支援進階玻璃渲染（Impeller），預覽為 FakeGlass 效果；厚度、折射率、飽和度等參數僅行動端生效。';

  @override
  String get displayScaleReset => '重設為 100%';

  @override
  String get displayScaleFineTune => '精細調整';

  @override
  String get displayScalePresets => '快捷預設';

  @override
  String get displayScaleNote =>
      '縮放比例會全域套用於文字與部分版面尺寸。設為 100% 可恢復預設。修改立即生效，無需重新啟動。';

  @override
  String displayScaleConnCount(int count) {
    return '$count 個連線';
  }

  @override
  String get displayThemeLight => '淺色';

  @override
  String get displayThemeDark => '深色';

  @override
  String get displaySettingsTitle => '顯示';

  @override
  String get displaySectionAppearance => '外觀';

  @override
  String get displayThemeMode => '主題模式';

  @override
  String get displayPureBlack => '純黑深色模式';

  @override
  String get displayPureBlackOn => '深色模式（已黑化）';

  @override
  String get displayOff => '已關閉';

  @override
  String get displaySectionPersonalize => '個人化';

  @override
  String get displayThemeColor => '主題配色';

  @override
  String get displayFollowSystemColor => '跟隨系統配色';

  @override
  String get displayFontWeight => '文字粗細';

  @override
  String get displaySeedDefaultGreen => '預設綠';

  @override
  String get displaySeedPink => '粉紅色';

  @override
  String get displaySeedRed => '紅色';

  @override
  String get displaySeedOrange => '橙色';

  @override
  String get displaySeedAmber => '琥珀色';

  @override
  String get displaySeedYellow => '黃色';

  @override
  String get displaySeedLime => '酸橙色';

  @override
  String get displaySeedLightGreen => '淺綠色';

  @override
  String get displaySeedGreen => '綠色';

  @override
  String get displaySeedCyan => '青色';

  @override
  String get displaySeedTeal => '藍綠色';

  @override
  String get displaySeedLightBlue => '淺藍色';

  @override
  String get displaySeedBlue => '藍色';

  @override
  String get displaySeedIndigo => '靛藍色';

  @override
  String get displaySeedPurple => '紫色';

  @override
  String get displaySeedDeepPurple => '深紫色';

  @override
  String get displaySeedBlueGrey => '藍灰色';

  @override
  String get displaySeedBrown => '棕色';

  @override
  String get displaySeedGrey => '灰色';

  @override
  String get displaySeedCustom => '自訂';

  @override
  String displayWeightThin(int weight) {
    return '極細 ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return '細 ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return '標準 ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return '中等 ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return '粗 ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return '極粗 ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return '自訂 ($weight)';
  }

  @override
  String get fontWeightThin => '極細';

  @override
  String get fontWeightLight => '細';

  @override
  String get fontWeightRegular => '標準';

  @override
  String get fontWeightMedium => '中等';

  @override
  String get fontWeightBold => '粗';

  @override
  String get fontWeightBlack => '極粗';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\n敏捷的棕色狐狸跳過懶惰的狗。';

  @override
  String get fontWeightSaveApply => '儲存並套用';

  @override
  String get geetestTitle => '完成滑塊驗證';

  @override
  String get geetestInitFailed => '驗證碼元件初始化失敗，請重試或改用其他登入方式';

  @override
  String get geetestUnsupported => '目前平台不支援內建驗證碼，請使用掃碼或 Cookie 登入';

  @override
  String get slicerPickImageFirst => '請先選擇圖片';

  @override
  String get slicerRowColInvalid => '行數與列數必須大於 0';

  @override
  String get slicerSuccess => '切割成功，已加入開始畫面';

  @override
  String slicerSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get slicerTitle => '圖片切割磁貼';

  @override
  String get slicerTileSize => '磁貼尺寸（所有碎片皆相同）';

  @override
  String get slicerColsLabel => '列數 (Cols)';

  @override
  String get slicerRowsLabel => '行數 (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return '預覽：將切割為 $count 個 $type 磁貼';
  }

  @override
  String get slicerProcessing => '處理中...';

  @override
  String get slicerSaveToStart => '儲存到開始畫面';

  @override
  String get viewerSaving => '正在儲存...';

  @override
  String get viewerSaveSuccess => '儲存成功';

  @override
  String viewerSaveFailed(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get viewerShareImage => '分享圖片';

  @override
  String viewerShareFailed(String error) {
    return '分享失敗: $error';
  }

  @override
  String get viewerCopying => '正在複製...';

  @override
  String viewerCopyFailed(String error) {
    return '複製失敗: $error';
  }

  @override
  String get viewerSaveToAlbum => '儲存到相簿';

  @override
  String get viewerCopyToClipboard => '複製到剪貼簿';

  @override
  String get viewerImageLoadFailed => '圖片載入失敗';

  @override
  String get viewerImageDataNotFound => '找不到圖片資料';

  @override
  String get userSpaceMidInvalid => 'mid 無效';

  @override
  String get userSpaceNoCard => '回應缺少 card';

  @override
  String get userSpaceNoList => '回應缺少 list';

  @override
  String get searchTypeVideo => '影片';

  @override
  String get searchTypeBangumi => '番劇';

  @override
  String get searchTypeFt => '影視';

  @override
  String get searchTypeLive => '直播間';

  @override
  String get searchTypeUser => '使用者';

  @override
  String get searchTypeArticle => '專欄';

  @override
  String get tenThousandUnit => '萬';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play播放 · $danmaku彈幕';
  }

  @override
  String searchScore(String score) {
    return '評分 $score';
  }

  @override
  String searchOnline(String count) {
    return '$count人在線';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans粉絲 · $videos影片';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views閱讀 · $replies評論';
  }

  @override
  String get searchBadgeCourse => '課堂';

  @override
  String get searchBadgeLive => '直播';

  @override
  String get searchBadgeCoop => '合作';

  @override
  String get searchBadgeLiveNow => '直播中';

  @override
  String get searchKeywordEmpty => '關鍵詞為空';

  @override
  String get searchBadResponse => '回應格式異常';

  @override
  String get searchFailed => '搜尋失敗';

  @override
  String get searchGaiaParamMissing => 'gaia register 參數缺失';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register 異常: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate 未通過 (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate 異常: $error';
  }

  @override
  String get commentOidEmpty => 'oid 為空';

  @override
  String commentException(String error) {
    return '異常: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return '樓中樓 HTTP $code';
  }

  @override
  String get commentSubNoData => '樓中樓回應缺少 data';

  @override
  String commentSubException(String error) {
    return '樓中樓異常: $error';
  }

  @override
  String get commentNotLoggedIn => '未登入或未開啟「攜帶 Cookie 請求」';

  @override
  String get commentMissingJct => 'Cookie 缺少 bili_jct，請重新登入';

  @override
  String commentNetworkError(String error) {
    return '網路異常: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message（code=$code）';
  }

  @override
  String get deviceOs => '作業系統';

  @override
  String get deviceBuild => '內部建置編號';

  @override
  String get deviceSecurityPatch => '安全性修補程式';

  @override
  String get deviceOem => 'OEM 廠商';

  @override
  String get deviceBrand => '品牌';

  @override
  String get deviceModel => '型號';

  @override
  String get deviceRomVersion => 'ROM/顯示版本';

  @override
  String get deviceFingerprint => '裝置指紋';

  @override
  String get deviceName => '裝置名稱';

  @override
  String get deviceComputerName => '電腦名稱';

  @override
  String get deviceHardwareModel => '硬體型號';

  @override
  String get deviceKernel => '核心版本';

  @override
  String get deviceDistro => '發行版';

  @override
  String get deviceVersion => '版本';

  @override
  String get devicePlatform => '平台';

  @override
  String deviceInfoFailed(String error) {
    return '取得資訊失敗: $error';
  }

  @override
  String get logWebUnsupported => '（Web 不支援檔案日誌）';

  @override
  String get logNotInitialized => '（未初始化）';

  @override
  String logAppDataDir(String path) {
    return '應用程式資料目錄\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData（Roaming）\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return '本機資料目錄\n$path';
  }

  @override
  String get nowPlayingVideo => '正在播放影片';

  @override
  String get commonUnknown => '未知';

  @override
  String get unnamedPlaylist => '未命名的播放清單';

  @override
  String get unknownVideo => '未知影片';

  @override
  String dohQueryFailed(int code) {
    return 'DoH 查詢失敗: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP 連線成功';

  @override
  String get netModeCompat => 'Host 映射 IP 直連，繞過 SNI 干擾';

  @override
  String get netModeStandard => '系統預設網路堆疊';

  @override
  String netHostResolveFailed(String host) {
    return '無法解析主機 $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie 為空';

  @override
  String get biliCookieIncomplete =>
      'Cookie 不完整，請從瀏覽器複製全部 Cookie（需包含 SESSDATA）';

  @override
  String get biliCookieMissingJct =>
      'Cookie 缺少 bili_jct，請重新從瀏覽器複製完整 Cookie（點讚/發評論等操作依賴它）';

  @override
  String get biliCookieInvalid => 'Cookie 無效或已過期，請重新從瀏覽器複製';

  @override
  String get biliLoginSuccess => '登入成功';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked => '請求被風控攔截(-412)，請稍後重試';

  @override
  String get biliQrExpired => 'QR Code 已失效';

  @override
  String get biliQrScanned => '已掃描，請在手機上確認';

  @override
  String get biliQrWaiting => '等待掃描';

  @override
  String get biliRequestFailed => '請求失敗';

  @override
  String get biliResponseNoData => '回應缺少 data';

  @override
  String get biliQrNoSessionCookie => '未取得工作階段 Cookie，請重新整理 QR Code 後重試';

  @override
  String get biliQrMissingJct =>
      'QR Code 登入未取得完整工作階段（缺少 bili_jct），請改用「貼上 Cookie」或「瀏覽器登入」方式';

  @override
  String get biliNoSessionCookie => '未取得工作階段 Cookie';

  @override
  String get biliWebKeyFailed => '取得登入公鑰失敗，請檢查網路';

  @override
  String get biliPwdEncryptFailed => '密碼加密失敗';

  @override
  String get biliNeedGeetest => '需要完成滑塊驗證';

  @override
  String get biliUnknownError => '未知錯誤';

  @override
  String get csPlaylists => '播放清單';

  @override
  String get csDanmaku => '彈幕';

  @override
  String get csCloudEncrypted => '雲端資料已加密，請先在 WebDAV 設定中填寫同步密碼';

  @override
  String get csCloudPassMismatch => '雲端資料已加密且同步密碼不匹配，無法同步';

  @override
  String get csCloudNoFile => '雲端沒有播放清單檔案，無法還原';

  @override
  String get csRestoredFromCloud => '已從雲端還原';

  @override
  String get csSyncDone => '同步完成';

  @override
  String csUploadBgCount(int count) {
    return '上傳背景圖 $count 張';
  }

  @override
  String csDownloadBgCount(int count) {
    return '下載背景圖 $count 張';
  }

  @override
  String csUploadedFileCount(int count) {
    return '上傳 $count 個檔案';
  }

  @override
  String csDownloadedFileCount(int count) {
    return '下載 $count 個檔案';
  }

  @override
  String csMergedListsCount(int count) {
    return '合併 $count 個清單';
  }

  @override
  String get csEncrypted => '已加密';

  @override
  String csSyncFailed(String error) {
    return '同步失敗: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return '已上傳 $count 個播放清單到雲端';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return '上傳 $uploaded 個，下載 $downloaded 個';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return '，失敗 $failed 個（$details）';
  }

  @override
  String get unknownUser => '未知使用者';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => '傳送檔案';

  @override
  String receivingFile(String fileName) {
    return '接收: $fileName';
  }

  @override
  String get notificationChannelName => '聊天訊息';

  @override
  String get notificationChannelDesc => '接收聊天訊息和快速回覆';

  @override
  String get notificationReply => '回覆';

  @override
  String get screenshotSavedTitle => '截圖已儲存';

  @override
  String get screenshotSavedToAlbum => '截圖已儲存到相簿';

  @override
  String get notificationConfirm => '確認';

  @override
  String get callInProgressError => '目前有未結束的通話，請先掛斷';

  @override
  String get callTcpFailed => '無法連線對方（TCP 建立失敗），請確認對方上線';

  @override
  String get callConnectionDropped => '連線建立後立即中斷，請檢查網路或對方狀態';

  @override
  String callInitFailed(String error) {
    return '發起通話失敗：$error';
  }

  @override
  String callAcceptFailed(String error) {
    return '接聽通話失敗：$error';
  }

  @override
  String get callRecordVoice => '語音通話';

  @override
  String get callRecordMissedOutgoing => '未接通話';

  @override
  String get callRecordRejected => '已拒絕來電';

  @override
  String get callRecordMissedIncoming => '未接來電';

  @override
  String get callPeerNoAnswer => '對方未接聽';

  @override
  String get callUnknown => '未知';

  @override
  String get callInProgress => '通話中';

  @override
  String get webdavHttpWarning => '警告：使用 HTTP 連線，憑證將以明文傳輸。建議使用 HTTPS。';

  @override
  String get webdavConfigRequired => '請先填寫伺服器位址和使用者名稱';

  @override
  String get webdavAuthFailed => '認證失敗：使用者名稱或密碼錯誤';

  @override
  String webdavConnectFailed(int code) {
    return '連線失敗：HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return '網路錯誤：無法連線到伺服器 ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return '未知錯誤：$error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV 未設定';

  @override
  String webdavLocalFileMissing(String path) {
    return '本機檔案不存在: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return '上傳失敗：HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return '上傳異常：$error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return '下載失敗: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return '下載異常: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return '刪除失敗: $error';
  }

  @override
  String webdavListFailed(String error) {
    return '列出檔案失敗: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND 失敗: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return '網路錯誤：$msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return '準備備份 $count 個檔案...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return '正在備份 ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return '備份完成：$success 成功，$fail 失敗';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '確定';

  @override
  String get commonConnect => '連線';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCreate => '建立';

  @override
  String get commonDelete => '刪除';

  @override
  String get drawerHome => '首頁';

  @override
  String get drawerVerificationRequests => '驗證請求';

  @override
  String get drawerSettings => '設定';

  @override
  String get drawerAbout => '關於';

  @override
  String get drawerCloseMenu => '關閉選單';

  @override
  String get drawerLockNow => '立即鎖定';

  @override
  String get drawerNoNickname => '未設定暱稱';

  @override
  String get drawerSwitchToDark => '切換到深色模式';

  @override
  String get drawerSwitchToLight => '切換到淺色模式';

  @override
  String get drawerLightMode => '淺色模式';

  @override
  String get drawerDarkMode => '深色模式';

  @override
  String get drawerSystemMode => '跟隨系統';

  @override
  String drawerThemeSwitched(String mode) {
    return '已切換到 $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return '取得失敗: $error';
  }

  @override
  String get drawerNoDeviceInfo => '暫無裝置資訊';

  @override
  String get drawerBackgroundTitle => '側邊欄背景';

  @override
  String get drawerBackgroundHasCustom => '目前已設定自訂背景，您可以更換或移除。';

  @override
  String get drawerBackgroundNoCustom => '為側邊欄設定一張個人化背景圖片。';

  @override
  String get drawerBackgroundUpdated => '✅ 側邊欄背景已更新';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '❌ 設定失敗: $error';
  }

  @override
  String get drawerBackgroundChange => '更換背景';

  @override
  String get drawerBackgroundSelect => '選擇背景圖片';

  @override
  String get drawerBackgroundRestored => '已恢復預設背景';

  @override
  String get drawerBackgroundRemove => '移除背景';

  @override
  String get homeOpenMenu => '開啟選單';

  @override
  String get homeAddConnection => '新增連線';

  @override
  String get homeMessages => '訊息';

  @override
  String get homeNoConnections => '尚無連線';

  @override
  String get homePullToRefreshHint => '下拉重新整理或點擊右上角新增';

  @override
  String get homeLoadFailed => '聊天記錄載入失敗，請重試';

  @override
  String get homeRetryLoad => '重新載入';

  @override
  String get homeUnknownAddress => '未知位址';

  @override
  String get homeNoMessages => '尚無訊息';

  @override
  String homeFileMessage(String fileName) {
    return '[檔案] $fileName';
  }

  @override
  String get homeFileFallbackName => '檔案';

  @override
  String get homeMessagePlaceholder => '[訊息]';

  @override
  String get connectionLost => '連線已失效';

  @override
  String get openVideoFailed => '無法開啟該影片';

  @override
  String get connectDialogTitle => '連線到對等端';

  @override
  String get connectIpHint => '輸入 IP 位址 (例如：192.168.1.100 或 fe80::1)';

  @override
  String get connectIpEmpty => '請輸入 IP 位址';

  @override
  String get connectIpInvalid => 'IP 位址格式不正確';

  @override
  String get connectIpNotLan => '僅允許區域網路 IP 位址';

  @override
  String get connectRequestSent => '已傳送連線請求，等待對方驗證';

  @override
  String get connectFailed => '連線失敗，請檢查 IP 位址是否正確或對方是否上線';

  @override
  String get homeScanQr => '掃一掃';

  @override
  String get homeMyQrCode => '我的 QR Code';

  @override
  String get homeManualAdd => '手動新增';

  @override
  String get scannedFriends => '透過掃描新增的好友';

  @override
  String get scanTitle => '掃一掃';

  @override
  String get scanTitleWebdav => '掃描 WebDAV 位址';

  @override
  String get scanHint => '將 QR Code / 條碼對準框內';

  @override
  String get scanHintWebdav => '將 WebDAV 伺服器位址 QR Code 對準框內';

  @override
  String get scanHintAddFriend => '將好友的裝置 QR Code 對準框內';

  @override
  String get scanPreparing => '正在準備相機...';

  @override
  String get scanPermissionNeeded => '需要相機權限';

  @override
  String get scanPermissionNeededMsg => '請在權限彈窗中允許使用相機，才能掃描。';

  @override
  String get scanPermissionDenied => '相機權限被拒絕';

  @override
  String get scanPermissionDeniedMsg => '權限已被永久拒絕，請前往系統設定手動開啟。';

  @override
  String get scanCameraUnavailable => '相機無法使用';

  @override
  String get scanRetry => '重試';

  @override
  String get scanOpenSettings => '前往系統設定';

  @override
  String get scanTorch => '閃光燈';

  @override
  String get scanDetectedLink => '偵測到連結';

  @override
  String get scanOpenLinkPrompt => '是否在內建瀏覽器中開啟以下連結？';

  @override
  String get scanCopy => '複製';

  @override
  String get scanOpen => '開啟';

  @override
  String get scanLinkCopied => '連結已複製';

  @override
  String get scanDetectedBiliVideo => '偵測到 B 站影片連結';

  @override
  String get scanBiliVideoPrompt => '是否用內置播放器開啟該影片？';

  @override
  String scanBiliVideoAt(String time) {
    return '空降至 $time';
  }

  @override
  String get scanOpenVideo => '開啟影片';

  @override
  String get scanDetectedWebdav => '偵測到 WebDAV 位址';

  @override
  String get scanWebdavPrompt => '該連結看起來是 WebDAV 伺服器位址，是否自動填入設定？';

  @override
  String get scanOpenInBrowser => '瀏覽器開啟';

  @override
  String get scanFillConfig => '填入設定';

  @override
  String get scanDetectedText => '辨識到文字';

  @override
  String get scanCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get scanClose => '關閉';

  @override
  String get scanResultTitle => '掃描結果';

  @override
  String get scanErrorPermission => '相機權限被拒絕';

  @override
  String get scanErrorUnsupported => '目前裝置不支援掃描';

  @override
  String get scanErrorDisposed => '掃描器已釋放，請重試';

  @override
  String scanErrorGeneric(String code) {
    return '相機無法使用（$code）';
  }

  @override
  String scanInitFailed(String error) {
    return '掃描器初始化失敗：$error';
  }

  @override
  String get scanDetectedDevice => '偵測到裝置 QR Code';

  @override
  String get scanAddFriendPrompt => '是否將該裝置新增為好友？';

  @override
  String get scanAddFriend => '新增好友';

  @override
  String get scanFriendAdded => '已傳送好友請求，等待對方驗證';

  @override
  String get scanFriendAddFailed => '新增好友失敗，請檢查網路或對方是否上線';

  @override
  String get myQrTitle => '我的 QR Code';

  @override
  String get myQrHint => '讓好友掃描此 QR Code 來新增您';

  @override
  String get myQrEmbedIp => 'QR Code 中已嵌入第一個區域網路 IP';

  @override
  String get myQrLocalIps => '目前區域網路 IP';

  @override
  String get myQrCopyContent => '複製 QR Code 內容';

  @override
  String get myQrCopied => '已複製到剪貼簿';

  @override
  String get myQrNoIp => '找不到有效的區域網路 IP，請檢查網路連線。';

  @override
  String get displayModeSectionTitle => '螢幕';

  @override
  String get displayModeTitle => '螢幕更新率';

  @override
  String get displayModeAuto => '自動';

  @override
  String get displayModeSystemTag => '[系統]';

  @override
  String get displayModeHint => '沒有生效？重新啟動應用程式試試';

  @override
  String get displayModeUnsupported => '目前平台不支援設定螢幕更新率（僅 Android）';

  @override
  String get displayModeAndroidOnly => '僅 Android';

  @override
  String get displayModeLoading => '正在取得螢幕更新率...';

  @override
  String get displayModeEmpty => '未取得可用的螢幕更新率';

  @override
  String get playerSectionEnhance => '畫面增強';

  @override
  String get superResolutionTitle => '超解析度';

  @override
  String get superResolutionOff => '關閉';

  @override
  String get superResolutionEfficiency => '效率（低耗電）';

  @override
  String get superResolutionQuality => '畫質（最佳效果）';

  @override
  String get superResolutionHint => '透過 mpv 著色器即時增強畫面，建議搭配硬體解碼；對動畫內容效果最佳';

  @override
  String get skipIntroOutroTitle => '跳過片頭/片尾';

  @override
  String get skipIntroOutroHint => '透過社群共享資料辨識片頭片尾，僅在影片有 BV+CID 時提示';

  @override
  String get skipIntro => '跳過片頭';

  @override
  String get skipOutro => '跳過片尾';

  @override
  String playlistDetailEpisodes(int count) {
    return '共 $count 集';
  }

  @override
  String get playlistDetailEmpty => '該播放清單為空，請先編輯新增影片';

  @override
  String playlistDetailEpisodeOf(int index) {
    return '第 $index 集';
  }

  @override
  String playlistDetailResume(String position) {
    return '看到這集 · $position';
  }

  @override
  String get playlistDetailBgTitle => '背景圖';

  @override
  String get playlistDetailBgPick => '選擇背景圖片';

  @override
  String get playlistDetailBgChange => '更換背景';

  @override
  String get playlistDetailBgRemove => '移除背景';

  @override
  String get playlistDetailBgUpdated => '✅ 背景圖已更新';

  @override
  String get playlistDetailBgRemoved => '已恢復預設背景';

  @override
  String playlistDetailBgFail(String error) {
    return '設定失敗：$error';
  }

  @override
  String get playlistFabRestart => '從頭開始';

  @override
  String get playlistMenuMore => '更多操作';

  @override
  String get playlistMenuRename => '編輯名稱';

  @override
  String get playlistMenuMultiSelect => '多選';

  @override
  String get playlistMenuDanmaku => '彈幕';

  @override
  String get playlistRenameTitle => '重新命名播放清單';

  @override
  String get playlistRenameHint => '輸入新的清單名稱';

  @override
  String get playlistRenameSaved => '已重新命名';

  @override
  String get playlistSelectDone => '完成';

  @override
  String get playlistSelectEmpty => '請先選擇劇集';

  @override
  String playlistSelectDelete(int count) {
    return '刪除選取（$count）';
  }

  @override
  String playlistSelectDeleted(int count) {
    return '已刪除 $count 集';
  }

  @override
  String get playlistDanmakuTitle => '匯入番劇彈幕';

  @override
  String get playlistDanmakuSsHint => '輸入番劇 SS 號（season_id）';

  @override
  String get playlistDanmakuFetchFail => '取得劇集失敗，請檢查 SS 號';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return '選擇劇集（共 $count 集）';
  }

  @override
  String get playlistDanmakuSelectAll => '全選';

  @override
  String get playlistDanmakuImport => '匯入並附加彈幕';

  @override
  String playlistDanmakuAttached(int count) {
    return '已為 $count 集附加彈幕';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '所選 $selected 集超過清單 $total 集，超出部分已忽略';
  }

  @override
  String get splitSelectChat => '選擇一個聊天';

  @override
  String get statusPending => '待對方驗證';

  @override
  String get statusConnected => '已連線';

  @override
  String get statusRejected => '已拒絕';

  @override
  String get statusDisconnected => '已中斷連線';

  @override
  String get homeStart => '開始';

  @override
  String get homeDone => '完成';

  @override
  String get homeBack => '返回';

  @override
  String get homeOverview => '鳥瞰視圖';

  @override
  String get homeLocalUser => '本機使用者';

  @override
  String get homeDefaultGroup => '預設群組';

  @override
  String get homeNewGroup => '新群組';

  @override
  String get homeUnnamedGroup => '（未命名群組）';

  @override
  String get homeDeleteGroupTitle => '確認刪除';

  @override
  String get homeDeleteGroupMessage => '刪除該組將同時刪除組內的所有磁貼，是否繼續？';

  @override
  String get homeNewGroupTitle => '新增群組';

  @override
  String get homeGroupNameHint => '輸入群組名稱';

  @override
  String get homeRenameGroupTitle => '為該組命名';

  @override
  String get homeNewGroupNameHint => '輸入新組名';

  @override
  String get homeImageSlice => '圖片碎片';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (小)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (寬)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (大)';
  }

  @override
  String get homeGroupOne => '分組1';

  @override
  String get homeGroupTwo => '分組2';

  @override
  String get homeGroupProductivity => '生產力工具';

  @override
  String get homeGroupLegacy => '舊版';

  @override
  String get tileImageSlicer => '圖片切割';

  @override
  String get tileSystemSettings => '系統設定';

  @override
  String get tileDatabase => '資料庫';

  @override
  String get tileLcdDisplay => 'LCD 顯示器';

  @override
  String get tileLedDynamic => 'LED 動態';

  @override
  String get tileLedStatic => 'LED 靜態';

  @override
  String get tilePisScreen => 'PIS 螢幕';

  @override
  String get tileRoutePreview => '路線預覽';

  @override
  String get tileStationEntranceDesign => '出入口設計';

  @override
  String get tileStationEntrancePillar => '出入口立柱';

  @override
  String get tileStationEntranceSideName => '出入口側名';

  @override
  String get tilePlatformSideName => '側邊站名';

  @override
  String get tileScreenDoorCover => '月台門蓋板';

  @override
  String get tileStationNameSign => '站名牌';

  @override
  String get tileGeneralSign => '通用標誌';

  @override
  String get tileLineSymbol => '路線符號';

  @override
  String get tileBusLcd => '公車 LCD';

  @override
  String get tileJsonEditor => 'JSON 編輯器';

  @override
  String get tileNamingRule => '命名規範';

  @override
  String get tilePlatformText => '月台文字';

  @override
  String get tileDepartureText => '出發文字';

  @override
  String get tileArrivalText => '到站文字';

  @override
  String get tileOperationDirectionLegacy => '營運方向(舊)';

  @override
  String get tileLegacyLcdWarning => '舊版 LCD（警告）';

  @override
  String get tileLinearRoute => '線性路線';

  @override
  String get tileRoadSign => '路牌';

  @override
  String get commentPanelTitle => '留言區';

  @override
  String commentTotalCount(int count) {
    return '共 $count 則';
  }

  @override
  String get commentSortHeat => '依熱門程度';

  @override
  String get commentSortTime => '依時間';

  @override
  String get commentLoading => '正在載入留言...';

  @override
  String get commentLoadFail => '留言載入失敗，請檢查網路';

  @override
  String get commentLoadMoreFail => '載入更多留言失敗';

  @override
  String get commentNoMore => '沒有更多留言了';

  @override
  String get commentLoadingMore => '載入中...';

  @override
  String get commentEmpty => '還沒有留言';

  @override
  String get commentPinned => '置頂';

  @override
  String get commentDeleted => '留言已刪除';

  @override
  String get commentExpand => '展開';

  @override
  String get commentCollapse => '收起';

  @override
  String get commentTranslateNeedEnable => '請先在語言設定中開啟 AI 翻譯';

  @override
  String get commentTranslateNone => '沒有可用翻譯';

  @override
  String commentSubCount(int count) {
    return '共 $count 則回覆';
  }

  @override
  String commentSubLoadMore(String hint) {
    return '載入更多回覆（$hint）';
  }

  @override
  String get commentYesterday => '昨天';

  @override
  String get articleLoadFailed => '文章載入失敗';

  @override
  String get articleNoContent => '文章正文為空或暫不支援渲染';

  @override
  String get articleOpenBrowser => '瀏覽器開啟';

  @override
  String get articleShare => '分享';

  @override
  String get articleAuthorUnknown => '未知作者';

  @override
  String get browserLinkPageTitle => '網頁連結';

  @override
  String articleViews(String count) {
    return '$count 閱讀';
  }

  @override
  String get contactPickerTitle => '傳送給聯絡人';

  @override
  String get contactPickerContentLabel => '傳送內容';

  @override
  String get contactPickerContentHint => '輸入要傳送的內容';

  @override
  String get contactPickerContentEmpty => '內容不能為空';

  @override
  String get contactPickerSearchHint => '搜尋聯絡人';

  @override
  String get contactPickerEmpty => '暫無聯絡人';

  @override
  String get contactPickerNoMatch => '未找到符合的聯絡人';

  @override
  String get contactPickerSelectAll => '全選';

  @override
  String contactPickerSendToCount(int count) {
    return '傳送給 $count 個聯絡人';
  }

  @override
  String contactPickerSent(int count) {
    return '已傳送給 $count 個聯絡人';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '「$name」未連接，無法傳送';
  }

  @override
  String contactPickerSendFailed(String error) {
    return '傳送失敗：$error';
  }

  @override
  String get contactPickerOnline => '在線';

  @override
  String get contactPickerOffline => '離線';

  @override
  String get articleShareToContact => '私訊分享';

  @override
  String get playerDanmakuList => '彈幕列表';

  @override
  String playerDanmakuListCount(int count) {
    return '彈幕列表 · 共 $count 條';
  }

  @override
  String get playerDanmakuListEmpty => '暫無彈幕';

  @override
  String get playerDanmakuListNoMatch => '無符合的彈幕';

  @override
  String get playerDanmakuListSearchHint => '搜尋彈幕內容';

  @override
  String get playerDanmakuListJumpCurrent => '定位到目前播放';

  @override
  String get playerViewNotes => '查看筆記';

  @override
  String get playerNotesTitle => '筆記';

  @override
  String playerNotesCount(int count) {
    return '筆記（$count）';
  }

  @override
  String get playerNotesEmpty => '該影片暫無公開筆記';

  @override
  String get playerNotesNoMore => '沒有更多了';

  @override
  String get playerNotesLoadFailed => '筆記載入失敗';

  @override
  String get playerNotesViewFull => '查看全部';

  @override
  String get playerWriteNote => '寫筆記';

  @override
  String get noteEditorWrite => '寫筆記';

  @override
  String get noteEditorTitle => '寫筆記';

  @override
  String get noteEditorTitleHint => '標題（選填）';

  @override
  String get noteEditorContentHint => '開始記筆記…';

  @override
  String get noteEditorEmoji => '表情';

  @override
  String get noteEditorPublish => '發布';

  @override
  String get noteEditorEmptyContent => '筆記內容不能為空';

  @override
  String get noteEditorContentTooShort => '內容至少 10 個字元才能發布';

  @override
  String get noteEditorNotLoggedIn => '未登入：筆記已儲存為本機草稿，登入後可發布';

  @override
  String get noteEditorPublished => '筆記已發布';

  @override
  String get noteEditorPublishNetworkError => '發布失敗（網路異常），草稿已儲存';

  @override
  String get noteEditorPublishRejected => '發布被伺服器拒絕，草稿已保留';

  @override
  String get noteEditorDraftSaved => '已自動儲存草稿';

  @override
  String get noteEditorLoggedInHint => '已登入，可發布公開筆記';

  @override
  String get noteEditorGuestHint => '未登入：僅儲存本機草稿，不能發布';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return '草稿已儲存 $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count 字';
  }

  @override
  String get noteEditorMyDraft => '我的草稿';

  @override
  String get noteEditorDeleteDraft => '刪除草稿';

  @override
  String get playerMoreTooltip => '更多操作';

  @override
  String get commentComposerBarHint => '說點什麼…';

  @override
  String get commentComposerHint => '輸入評論內容…';

  @override
  String commentComposerReplyHint(String name) {
    return '回覆 @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return '回覆 @$name';
  }

  @override
  String get commentComposerEmote => '表情';

  @override
  String get commentComposerSend => '發送';

  @override
  String get commentComposerEmpty => '評論內容不能為空';

  @override
  String get commentComposerEmoteUnavailable => '表情面板不可用（可能未登入）';

  @override
  String get commentComposerPickImage => '選擇圖片';

  @override
  String get commentComposerMore => '更多';

  @override
  String get commentComposerVideoProgress => '影片進度';

  @override
  String get commentComposerVideoScreenshot => '影片截圖';

  @override
  String commentComposerImageLimit(int count) {
    return '最多選擇 $count 張圖片';
  }

  @override
  String get commentComposerCaptureFailed => '截圖失敗，請先開始播放';

  @override
  String get commentComposerUploadFailed => '圖片上傳失敗，請重試';

  @override
  String get commentComposerFabLabel => '發評論';

  @override
  String get commentComposerFabReply => '發回覆';

  @override
  String get danmakuSendTitle => '發彈幕';

  @override
  String get danmakuSendModeLabel => '模式';

  @override
  String get danmakuSendFontSizeLabel => '字號';

  @override
  String get danmakuSendColorLabel => '顏色';

  @override
  String get danmakuFontSizeSmall => '小';

  @override
  String get danmakuFontSizeStandard => '標準';

  @override
  String get danmakuFontSizeLarge => '大';

  @override
  String get danmakuSendCustomColor => '自訂顏色';

  @override
  String get danmakuSendColorOk => '確定';

  @override
  String get danmakuSendPreviewPlaceholder => '發個友善的彈幕見證當下';

  @override
  String get drawerHistory => '历史记录';

  @override
  String get drawerWatchLater => '稍后再看';

  @override
  String get drawerMyCache => '我的缓存';

  @override
  String get historyCenterTitle => '历史记录';

  @override
  String get historyTabWatch => '观看历史';

  @override
  String get historyTabPlay => '播放进度';

  @override
  String get historySearchHint => '搜索历史...';

  @override
  String get historyPauseHistory => '暂停记录历史';

  @override
  String get historyResumeHistory => '恢复记录历史';

  @override
  String get historyPausedTip => '历史记录已暂停';

  @override
  String get historyPausedTipAction => '点击恢复';

  @override
  String get historyClearWatchHistory => '清空观看历史';

  @override
  String get historyClearPlayHistory => '清空播放记录';

  @override
  String get historyClearAllTitle => '清空历史';

  @override
  String historyClearAllConfirm(String label) {
    return '确定要清空全部$label吗？此操作不可恢复。';
  }

  @override
  String get historyNoWatchHistory => '暂无观看历史';

  @override
  String get historyNoPlayHistory => '暂无播放记录';

  @override
  String get historyDeleteSelected => '删除选中';

  @override
  String historySelectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get historySearchNoResult => '无匹配结果';

  @override
  String get historyPauseOnSnack => '已暂停历史记录';

  @override
  String get historyResumeOnSnack => '已恢复历史记录';

  @override
  String historyDeleteToast(int count) {
    return '已删除 $count 条记录';
  }

  @override
  String get myCacheTitle => '我的缓存';

  @override
  String get myCacheSearchHint => '搜索缓存视频...';

  @override
  String get myCacheDownloading => '正在缓存';

  @override
  String get myCacheCached => '已缓存';

  @override
  String get myCacheNoCache => '暂无缓存视频';

  @override
  String myCacheGroupCount(int count) {
    return '$count个视频';
  }

  @override
  String get myCacheDeleteGroup => '删除整组';

  @override
  String get myCacheUpdateDanmaku => '更新弹幕';

  @override
  String get myCacheClearAllTitle => '清空全部缓存';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return '将删除全部已缓存视频（$count个视频 · $size），确定吗？';
  }

  @override
  String get cacheActionDownload => '缓存';

  @override
  String get cacheActionCached => '已缓存';

  @override
  String get cacheActionCaching => '缓存中';

  @override
  String get cacheToastSuccess => '已加入缓存队列';

  @override
  String get cacheToastCached => '该视频已缓存';

  @override
  String cacheToastFailed(String error) {
    return '缓存失败：$error';
  }

  @override
  String get drawerRecommend => '推荐';

  @override
  String get recommendSourceWeb => 'Web端';

  @override
  String get recommendSourceApp => 'APP端';

  @override
  String get recommendEmpty => '暂无推荐内容';

  @override
  String get recommendSwitchList => '切换为单列';

  @override
  String get recommendSwitchGrid => '切换为多列';

  @override
  String get sideBarExpand => '展开侧边栏';

  @override
  String get sideBarCollapse => '收起侧边栏';

  @override
  String get sideBarMore => '更多';

  @override
  String get recommendTabHot => '热门';

  @override
  String get recommendTabBangumi => '番剧';

  @override
  String get recommendSourceTitle => '推荐数据来源';
}
