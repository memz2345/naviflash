# Toast / SnackBar 中文本地化 · 有活力改写（无 emoji 版）

> 来源：`lib/l10n/app_zh_CN.arb`（主简体中文）。本表为**新风格建议**：去掉 emoji，句首用 唔… / 哦 / 咦? 作为语气引导，整体更口语、带点情绪。

> 改法：把 `app_zh_CN.arb` 里对应 key 的 value 换成「有活力版本」即可（占位符 `{error}`/`{count}`/`{name}` 等已逐条校验，一个不少）。同义 key 的 `app_zh.arb` 可同步；繁体 `zh_HK/zh_TW` 按需。

> 技术性错误文案（接口码、HTTP 码类）保留原信息，只调语气，不删内容。


> 共改写 **157** 条 arb key；其中当前已带 emoji（✅/❌ 等）、应用新值时会自动去掉的有 **9** 条：`chatFileSentSuccess, chatImageCopied, chatImageSent, chatSaveSuccess, profileAvatarFailed, profileAvatarUpdated, profileNicknameUpdated, playlistDetailBgUpdated, webdavConnectSuccess`

## A. Toast/Snack 确凿

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `danmakuToastEmpty` | 弹幕内容不能为空 | 哦，弹幕先写点内容呗 |
| `danmakuToastSendFail` | 发送失败：{error} | 唔…弹幕没发出去：{error} |
| `danmakuToastSent` | 弹幕已发送 | 哦，弹幕飞出去啦 |
| `netChatIpv6EnabledSnack` | 已开启聊天 IPv6（重启应用生效） | 哦，IPv6 聊天已开，重启后生效 |
| `netChatIpv6DisabledSnack` | 已关闭聊天 IPv6（重启应用生效） | 哦，IPv6 聊天已关，重启后生效 |
| `netLocalSendCompatEnabledSnack` | 已开启 LocalSend 兼容 | 哦，LocalSend 兼容已开 |
| `netLocalSendCompatDisabledSnack` | 已关闭 LocalSend 兼容（恢复原生方案） | 哦，已切回原生方案，LocalSend 兼容关了 |
| `lsEnabledSnack` | 已开启 LocalSend 兼容 | 哦，LocalSend 兼容已开 |
| `historyPauseOnSnack` | 已暂停历史记录 | 哦，历史记录先停一下 |
| `historyResumeOnSnack` | 已恢复历史记录 | 哦，历史记录接着记 |
| `historyDeleteToast` | 已删除 {count} 条记录 | 哦，删掉了 {count} 条记录 |
| `cacheToastSuccess` | 已加入缓存队列 | 哦，已经排上缓存队列啦 |
| `cacheToastCached` | 该视频已缓存 | 哦，这个视频缓存好啦 |
| `cacheToastFailed` | 缓存失败：{error} | 唔…缓存没成：{error} |

## B. 账号/登录/Cookie

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `biliLoginSuccess` | 登录成功 | 哦，登录成功，欢迎回来 |
| `accountsBiliLoginSuccess` | B 站登录成功 | 哦，B 站登录成了 |
| `accountsLoggedOut` | 已退出登录 | 哦，已经退出了 |
| `accountsLoggedOutWithCookie` | 已退出登录并清空浏览器 Cookie | 哦，退出了，浏览器 Cookie 也清了 |
| `accountsCookieCleared` | 已清空内置浏览器 Cookie | 哦，浏览器 Cookie 清空啦 |
| `biliLoginFailedRetry` | 登录失败，请重试 | 唔…登录没成，再试一次吧 |
| `biliLoginQrFetchFailed` | 获取二维码失败，请检查网络 | 咦？二维码没刷出来，看看网络？ |
| `biliQrExpired` | 二维码已失效 | 咦？二维码过期了，刷新一下 |
| `biliQrScanned` | 已扫码，请在手机上确认 | 哦，扫到了，去手机上点确认 |
| `biliQrWaiting` | 等待扫码 | 唔…等你扫码中 |
| `biliNeedGeetest` | 需要完成滑块验证 | 咦？来个滑块验证再继续 |
| `biliCookieEmpty` | Cookie 为空 | 咦？Cookie 是空的哦 |
| `biliCookieIncomplete` | Cookie 不完整，请从浏览器复制全部 Cookie（需包含 SESSDATA） | 唔…Cookie 不全，把带 SESSDATA 的整段都复制过来 |
| `biliCookieMissingJct` | Cookie 缺少 bili_jct，请重新从浏览器复制完整 Cookie（点赞/发评论等操作依赖它） | 唔…缺了 bili_jct，复制完整 Cookie 才能点赞评论 |
| `biliCookieInvalid` | Cookie 无效或已过期，请重新从浏览器复制 | 唔…Cookie 失效啦，重新复制一份 |
| `commentNotLoggedIn` | 未登录或未开启「携带 Cookie 请求」 | 哦，先登录、并打开“携带 Cookie”才能操作 |
| `commentMissingJct` | Cookie 缺少 bili_jct，请重新登录 | 唔…登录信息不全，重新登录一下 |

## C. WebDAV/云同步

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `webdavConnectSuccess` | ✅ 连接成功！ | 哦，连上了 |
| `webdavConfigSaved` | 配置已保存 | 哦，配置存好了 |
| `webdavConnectFailed` | 连接失败：HTTP {code} | 唔…连不上（HTTP {code}） |
| `webdavAuthFailed` | 认证失败：用户名或密码错误 | 唔…账号或密码不对 |
| `webdavNetworkError` | 网络错误：无法连接到服务器 ({msg}) | 唔…网络抽风了，连不上服务器（{msg}） |
| `webdavUnknownError` | 未知错误：{error} | 咦？出了点意外：{error} |
| `webdavUploadFailed` | 上传失败：HTTP {code} | 唔…上传挂了（HTTP {code}） |
| `webdavDownloadFailed` | 下载失败: HTTP {code} | 唔…下载挂了（HTTP {code}） |
| `webdavDeleteFailed` | 删除失败: {error} | 唔…没删掉：{error} |
| `webdavListFailed` | 列出文件失败: {error} | 唔…文件列表没加载出来：{error} |
| `csSyncDone` | 同步完成 | 哦，同步搞定 |
| `csSyncFailed` | 同步失败: {error} | 唔…同步失败：{error} |
| `csRestoredFromCloud` | 已从云端恢复 | 哦，从云端恢复好啦 |
| `csCloudEncrypted` | 云端数据已加密，请先在 WebDAV 设置中填写同步密码 | 咦？云端是加密的，先去填个同步密码 |
| `csCloudPassMismatch` | 云端数据已加密且同步密码不匹配，无法同步 | 唔…密码对不上，解不开云端数据 |
| `csCloudNoFile` | 云端没有播放列表文件，无法恢复 | 咦？云端还没有播放列表，没法恢复 |
| `playlistSyncResult` | {what}：{message} | 哦，{what}：{message} |

## D. 网络/发现/连接

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `connectRequestSent` | 已发送连接请求，等待对方验证 | 哦，请求已发，等对方确认 |
| `connectFailed` | 连接失败，请检查 IP 地址是否正确或对方是否在线 | 唔…没连上，确认下 IP 或对方在线没 |
| `connectIpEmpty` | 请输入 IP 地址 | 哦，先填个 IP 地址呀 |
| `connectIpInvalid` | IP 地址格式不正确 | 咦？这个 IP 格式不对哦 |
| `connectIpNotLan` | 仅允许内网 IP 地址 | 哦，只能填内网 IP 哈 |
| `discoverConnectFailed` | 连接失败，请检查网络或对方是否在线 | 唔…连不上，查查网络或对方在不在 |
| `discoverAlreadyConnected` | 该设备已连接 | 哦，这个设备已经连着啦 |
| `discoverAlreadyPending` | 正在等待对方验证，请勿重复发送 | 哦，已经在等对方确认了，别重复发 |
| `tcpConnectSuccess` | TCP 连接成功 | 哦，TCP 连上了 |
| `netHostResolveFailed` | 无法解析主机 {host} | 咦？解析不了 {host}，域名有问题？ |

## E. 播放器/视频/投屏

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `playerResumeFrom` | 已从 {position} 继续播放 | 哦，从 {position} 接着看 |
| `playerSavedToAlbum` | 已保存到相册 | 哦，已存到相册 |
| `playerScreenshotSavedToAlbum` | 截图 {fileName} 已保存到相册 | 哦，{fileName} 已存相册 |
| `playerCopyLinkDone` | 已复制：{url} | 哦，已复制：{url} |
| `playerCopyLinkNotBili` | 仅 B 站视频支持复制链接 | 哦，只有 B 站视频能复制链接 |
| `playerAlignAspectRatioDone` | 窗口已对齐视频比例 | 哦，窗口已贴合视频比例 |
| `playerAlignAspectRatioFailed` | 无法获取视频尺寸 | 唔…拿不到视频尺寸，对齐失败 |
| `playerScreenshotFailed` | 截图失败: {error} | 唔…截图翻车了：{error} |
| `playerSaveFailed` | 保存失败: {error} | 唔…保存失败：{error} |
| `playerPipFailed` | 画中画调用失败: {error} | 唔…画中画没调起来：{error} |
| `playerAllEpisodesPlayed` | 已播放完全部 {count} 集 | 哦，全部 {count} 集看完啦 |
| `playerQualityLocked` | 该画质不可用（需登录或大会员） | 咦？这画质要登录/大会员才能看 |
| `playerSubtitleLoadFailed` | 字幕加载失败 | 唔…字幕没加载出来 |
| `dlnaCastStarted` | 已投屏到 {device} | 哦，已投到 {device} |
| `dlnaCastFailed` | 投屏失败：{device} | 唔…投屏没成功：{device} |
| `dlnaCastingTo` | 正在投屏到 {device} | 哦，正在投到 {device}… |

## F. 评论/弹幕/笔记

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `commentLikeFail` | 点赞失败：{error} | 唔…点赞没成：{error} |
| `commentLikeLoginRequired` | 请先登录 B 站账号（并开启携带 Cookie）后再点赞 | 哦，先登录 B 站（打开携带 Cookie）才能点赞 |
| `commentLoadFail` | 评论加载失败，请检查网络 | 唔…评论刷不出来，查查网络 |
| `commentLoadMoreFail` | 加载更多评论失败 | 唔…更多评论没加载出来 |
| `commentComposerEmpty` | 评论内容不能为空 | 哦，评论先写点内容呀 |
| `commentComposerCaptureFailed` | 截图失败，请先开始播放 | 哦，先播起来才能截图 |
| `commentComposerUploadFailed` | 图片上传失败，请重试 | 唔…图片没传上去，再试一次 |
| `commentNetworkError` | 网络异常: {error} | 唔…网络不对劲：{error} |
| `commentApiError` | {message}（code={code}） | 唔…{message}（错误码 {code}） |
| `commentException` | 异常: {error} | 咦？出状况了：{error} |
| `commentDeleted` | 评论已删除 | 哦，评论删掉了 |
| `noteEditorPublished` | 笔记已发布 | 哦，笔记发出来啦 |
| `noteEditorDraftSaved` | 已自动保存草稿 | 哦，草稿已自动存好 |
| `noteEditorPublishNetworkError` | 发布失败（网络异常），草稿已保存 | 唔…网络问题没发出去，草稿先存着了 |
| `noteEditorPublishRejected` | 发布被服务端拒绝，草稿已保留 | 唔…服务端没通过，草稿还在 |

## G. 聊天/文件/图片/截图

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `chatImageSent` | ✅ 图片已发送 | 哦，图片发出去啦 |
| `chatImageSendFailed` | 发送图片失败 | 唔…图片没发出去 |
| `chatFileSentSuccess` | ✅ {fileName} 发送成功 | 哦，{fileName} 发成功了 |
| `chatFileSendFailed` | 发送文件失败 | 唔…文件没发出去 |
| `chatImageCopied` | ✅ 图片已复制到剪贴板 | 哦，图片已复制 |
| `chatSaveSuccess` | ✅ 保存成功 | 哦，保存成功 |
| `chatSaveFailed` | 保存失败: {error} | 唔…保存失败：{error} |
| `chatMessageDeleted` | 消息已删除 | 哦，消息删掉了 |
| `chatReconnectFailed` | 重连失败，请检查网络或对方是否在线 | 唔…重连没成功，查查网络或对方在不在 |
| `chatConnDisconnected` | 对方已断开连接 | 咦？对方跑啦，连接断了 |
| `chatConnRejected` | 连接已被拒绝 | 唔…连接被拒绝了 |
| `chatCopyFailed` | 复制失败 | 唔…复制没成功 |
| `chatClipboardEmptyOrUnsupported` | 剪贴板为空或格式不支持 | 咦？剪贴板是空的，或格式不支持 |
| `lsSendSuccess` | 成功发送 {count} 个文件 | 哦，{count} 个文件发成功了 |
| `lsSendFailed` | 有 {count} 个文件发送成功，其余失败 | 唔…{count} 个发成功，剩下的挂了 |
| `lsFileReceived` | 已接收文件：{fileName} | 哦，收到文件：{fileName} |
| `viewerSaveSuccess` | 保存成功 | 哦，保存成功 |
| `viewerSaveFailed` | 保存失败: {error} | 唔…保存失败：{error} |
| `viewerCopyFailed` | 复制失败: {error} | 唔…复制失败：{error} |
| `viewerShareFailed` | 分享失败: {error} | 唔…分享失败：{error} |
| `screenshotSavedToAlbum` | 截图已保存到相册 | 哦，截图已存相册 |
| `screenshotSavedTitle` | 截图已保存 | 哦，截图存好啦 |

## H. 存储/缓存/历史

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `storageCleared` | {label}已清理 | 哦，{label}已清理 |
| `storageAllCleared` | 缓存已全部清理 | 哦，缓存清得干干净净 |
| `playHistoryDeleted` | 已删除「{title}」的播放记录 | 哦，删掉「{title}」的进度 |
| `historyClearAllConfirm` | 确定要清空全部{label}吗？此操作不可恢复。 | 咦？要把全部{label}清空吗？删了可找不回来哦 |
| `myCacheClearAllConfirm` | 将删除全部已缓存视频（{count}个视频 · {size}），确定吗？ | 咦？会删掉全部缓存视频（{count}个 · {size}），确定？ |
| `cacheActionCaching` | 缓存中 | 缓存中… |

## I. 设置/主题/外观/资料

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `themeColorExtracted` | 已从图片提取主题色 | 哦，已从图片提取主题色 |
| `themeColorFailed` | 取色失败: {error} | 唔…取色失败：{error} |
| `themeColorCopied` | 已复制色号: {hex} | 哦，色号已复制：{hex} |
| `themeSwitched` | 已切换至 {name} 主题 | 哦，已切到 {name} 主题 |
| `themeDeleted` | 已删除 "{name}" | 哦，已删除「{name}」 |
| `themeCreated` | 主题 "{name}" 已创建并保存 | 哦，主题「{name}」已建好存上啦 |
| `profileAvatarFailed` | ❌ 选择头像失败: {error} | 唔…头像没换成功：{error} |
| `profileAvatarUpdated` | ✅ 头像已更新 | 哦，头像换好啦 |
| `profileNicknameUpdated` | ✅ 昵称已更新 | 哦，昵称改好啦 |
| `settingsNicknameUpdated` | 昵称已更新 | 哦，昵称改好啦 |
| `settingsAvatarUpdated` | 头像已更新 | 哦，头像换好啦 |
| `drawerThemeSwitched` | 已切换到 {mode} | 哦，已切到 {mode} |
| `drawerBackgroundUpdated` | 侧边栏背景已更新 | 哦，侧边栏背景换好啦 |
| `drawerBackgroundRestored` | 已恢复默认背景 | 哦，已恢复默认背景 |
| `drawerBackgroundSetFailed` | 设置失败: {error} | 唔…背景没设成：{error} |
| `pageBgSaved` | 背景图已更新 | 哦，背景图换好啦 |
| `pageBgCleared` | 背景图已清除 | 哦，背景图清掉了 |
| `playlistDetailBgUpdated` | ✅ 背景图已更新 | 哦，背景图换好啦 |
| `playlistDetailBgRemoved` | 已恢复默认背景 | 哦，已恢复默认背景 |
| `playlistDetailBgFail` | 设置失败：{error} | 唔…背景没设成：{error} |

## J. 播放列表/发现/扫码/联系人/其他

| arb key | 当前中文 | 有活力版本（新风格） |
|---|---|---|
| `playlistCreated` | 已创建: {name} | 哦，播放列表「{name}」已建好 |
| `playlistImportAdded` | 已添加 {count} 个文件 | 哦，已加 {count} 个文件 |
| `playlistRenameSaved` | 已重命名 | 哦，已重命名 |
| `playlistSelectDeleted` | 已删除 {count} 集 | 哦，已删 {count} 集 |
| `playlistDanmakuAttached` | 已为 {count} 集附加弹幕 | 哦，已给 {count} 集挂上弹幕 |
| `slicerSuccess` | 切割成功，已添加到开始屏幕 | 哦，切好啦，已加到开始屏幕 |
| `slicerSaveFailed` | 保存失败: {error} | 唔…保存失败：{error} |
| `scanCopiedToClipboard` | 已复制到剪贴板 | 哦，已复制 |
| `scanLinkCopied` | 链接已复制 | 哦，链接已复制 |
| `scanFriendAdded` | 已发送好友请求，等待对方验证 | 哦，好友请求已发，等对方确认 |
| `scanFriendAddFailed` | 添加好友失败，请检查网络或对方是否在线 | 唔…加好友没成功，查查网络或对方在不在 |
| `myQrCopied` | 已复制到剪贴板 | 哦，已复制 |
| `discoverIpCopied` | 已复制 {ip} | 哦，已复制 {ip} |
| `contactPickerSent` | 已发送给 {count} 个联系人 | 哦，已发给 {count} 个联系人 |
| `contactPickerSendFailed` | 发送失败：{error} | 唔…发送失败：{error} |
| `contactPickerNotConnected` | 「{name}」未连接，无法发送 | 咦？「{name}」还没连上，发不了 |
| `browserUaUpdated` | UA 已更新并刷新页面 | 哦，UA 已更新，页面刷新了 |
| `browserCookieCopied` | Cookie已复制 | 哦，Cookie 已复制 |
| `browserSaveFailed` | 保存失败: {error} | 唔…保存失败：{error} |
| `webdavPassphraseGenerated` | 已生成同步密码并复制到剪贴板，请在其他设备上填入相同密码 | 哦，密码已生成并复制，去其他设备填一样的 |

## 附：Dart 里写死的中文 toast（不走 arb，建议一并改）

> 这些在 `showAppToast(...)` 里直接写死中文，改 arb 不会生效，需要手动改源码。

| 文件 | 写死文案 | 有活力建议 |
|---|---|---|
| `lib/screens/article_page.dart` | 点赞统计暂为只读 | 哦，点赞数暂时只能看不能改 |
| `lib/screens/article_page.dart` | 收藏统计暂为只读 | 哦，收藏数暂时只能看不能改 |
| `lib/screens/bilibili_favorites_page.dart` | 创建失败：${result.message} | 唔…没建成功：${result.message} |
| `lib/screens/cache_contents_page.dart` | 已清空当前分类缓存 | 哦，当前分类缓存清掉了 |
| `lib/screens/cache_contents_page.dart` | 已删除缓存视频 ${e.bvid} | 哦，删掉缓存视频 ${e.bvid} |
| `lib/screens/cache_contents_page.dart` | 已删除缓存图片 | 哦，缓存图片删掉了 |
| `lib/screens/cache_contents_page.dart` | 已复制 ${e.bvid} | 哦，已复制 ${e.bvid} |
| `lib/screens/cache_contents_page.dart` | 已复制 ${e.key} | 哦，已复制 ${e.key} |
| `lib/screens/favorites_page.dart` | 已取消收藏 | 哦，取消收藏啦 |
| `lib/screens/my_cache_page.dart` | 已删除 $bvid | 哦，删掉 ${bvid} |
| `lib/screens/my_cache_page.dart` | 已删除 ${e.bvid} | 哦，删掉 ${e.bvid} |
| `lib/screens/my_cache_page.dart` | 已全选 ${_selectedBvids.length} 组 | 哦，已全选 ${_selectedBvids.length} 组 |
| `lib/screens/my_cache_page.dart` | 已取消全选 | 哦，取消全选啦 |
| `lib/screens/my_cache_page.dart` | 未选择任何缓存 | 咦？还没选任何缓存哦 |
| `lib/screens/page_background_settings_page.dart` | 裁剪失败 | 唔…裁剪没成 |
| `lib/screens/player.dart` | 切换画质失败 | 唔…画质没切过去 |
| `lib/widgets/search_video_menu.dart` | 已复制 $text | 哦，已复制 $text |