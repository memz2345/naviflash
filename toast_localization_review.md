# 用户提示文案本地化梳理（Toast / SnackBar）

> 来源：`lib/l10n/app_zh_CN.arb`（主简体中文）
> 机制：`showAppToast()` 统一入口，Android 走原生 Toast，其余平台回退 floating SnackBar；带操作按钮的提示直接用 `SnackBar`。
> 说明：下表左侧为 `arb` 里现有的 key 与中文，右侧为"更有活力"的改写建议（口语化、第二人称、带点情绪/emoji，但不过分）。
> 改法：直接改 `app_zh_CN.arb` 对应 value 即可（同义 key 的 `app_zh.arb` 可同步；繁体 `zh_HK/zh_TW` 按需）。**纯技术性错误文案（接口码、堆栈类）建议保留原样。**

---

## A. 确凿的 Toast / Snack key（命名直接带 Toast / Snack）

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `danmakuToastEmpty` | 弹幕内容不能为空 | 弹幕不能空着呀 ✍️ |
| `danmakuToastSendFail` | 发送失败：{error} | 弹幕没发出去：{error} 😵 |
| `danmakuToastSent` | 弹幕已发送 | 🚀 弹幕已发射 |
| `netChatIpv6EnabledSnack` | 已开启聊天 IPv6（重启应用生效） | IPv6 聊天已开启 🚀（重启后生效） |
| `netChatIpv6DisabledSnack` | 已关闭聊天 IPv6（重启应用生效） | IPv6 聊天已关闭（重启后生效） |
| `netLocalSendCompatEnabledSnack` | 已开启 LocalSend 兼容 | 🔗 LocalSend 兼容已开启 |
| `netLocalSendCompatDisabledSnack` | 已关闭 LocalSend 兼容（恢复原生方案） | 已切回原生方案，LocalSend 兼容关闭 |
| `lsEnabledSnack` | 已开启 LocalSend 兼容 | 🔗 LocalSend 兼容已开启 |
| `historyPauseOnSnack` | 已暂停历史记录 | ⏸️ 历史记录已暂停 |
| `historyResumeOnSnack` | 已恢复历史记录 | ▶️ 历史记录已恢复 |
| `historyDeleteToast` | 已删除 {count} 条记录 | 🗑️ 已删掉 {count} 条 |
| `cacheToastSuccess` | 已加入缓存队列 | ⏳ 已加入缓存队列 |
| `cacheToastCached` | 该视频已缓存 | 这个视频已经缓存好啦 💾 |
| `cacheToastFailed` | 缓存失败：{error} | 😵 缓存失败了：{error} |

---

## B. 账号 / 登录 / Cookie

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `biliLoginSuccess` | 登录成功 | 🎉 登录成功，欢迎回来 |
| `accountsBiliLoginSuccess` | B 站登录成功 | ✅ B 站登录成功 |
| `accountsLoggedOut` | 已退出登录 | 👋 已退出登录 |
| `accountsLoggedOutWithCookie` | 已退出登录并清空浏览器 Cookie | 👋 已退出，浏览器 Cookie 也清了 |
| `accountsCookieCleared` | 已清空内置浏览器 Cookie | 🧹 浏览器 Cookie 已清空 |
| `biliLoginFailedRetry` | 登录失败，请重试 | 😣 登录没成功，再试一次吧 |
| `biliLoginQrFetchFailed` | 获取二维码失败，请检查网络 | 二维码没刷出来，看看网络？ |
| `biliQrExpired` | 二维码已失效 | ⏰ 二维码过期了，刷新一下 |
| `biliQrScanned` | 已扫码，请在手机上确认 | 📱 扫到了，去手机上点确认 |
| `biliQrWaiting` | 等待扫码 | 等你在 B 站里扫码… |
| `biliNeedGeetest` | 需要完成滑块验证 | 来个滑块验证再继续 🤖 |
| `biliCookieEmpty` | Cookie 为空 | Cookie 是空的哦 |
| `biliCookieIncomplete` | Cookie 不完整，请从浏览器复制全部 Cookie（需包含 SESSDATA） | Cookie 不全，要把带 SESSDATA 的整段都复制过来 |
| `biliCookieMissingJct` | Cookie 缺少 bili_jct，请重新从浏览器复制完整 Cookie（点赞/发评论等操作依赖它） | 缺了 bili_jct，复制完整的 Cookie 才能点赞评论 |
| `biliCookieInvalid` | Cookie 无效或已过期，请重新从浏览器复制 | Cookie 失效啦，重新复制一份吧 |
| `commentNotLoggedIn` | 未登录或未开启「携带 Cookie 请求」 | 先登录、并打开"携带 Cookie"才能操作哦 |
| `commentMissingJct` | Cookie 缺少 bili_jct，请重新登录 | 登录信息不完整，重新登录一下 |

---

## C. WebDAV / 云同步 / 播放列表同步

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `webdavConnectSuccess` | ✅ 连接成功！ | 🎉 连上了！ |
| `webdavConfigSaved` | 配置已保存 | 💾 配置已保存，放心 |
| `webdavConnectFailed` | 连接失败：HTTP {code} | 😵 连不上（HTTP {code}） |
| `webdavAuthFailed` | 认证失败：用户名或密码错误 | 账号或密码不对，认证失败 |
| `webdavNetworkError` | 网络错误：无法连接到服务器 ({msg}) | 网络抽风了，连不上服务器（{msg}） |
| `webdavUnknownError` | 未知错误：{error} | 😕 出了点意外：{error} |
| `webdavUploadFailed` | 上传失败：HTTP {code} | 上传挂了（HTTP {code}） |
| `webdavDownloadFailed` | 下载失败: HTTP {code} | 下载挂了（HTTP {code}） |
| `webdavDeleteFailed` | 删除失败: {error} | 没删掉：{error} |
| `webdavListFailed` | 列出文件失败: {error} | 文件列表加载失败：{error} |
| `csSyncDone` | 同步完成 | ✅ 同步搞定 |
| `csSyncFailed` | 同步失败: {error} | 😵 同步失败：{error} |
| `csRestoredFromCloud` | 已从云端恢复 | ☁️ 已从云端恢复 |
| `csCloudEncrypted` | 云端数据已加密，请先在 WebDAV 设置中填写同步密码 | 云端是加密的，先去填个同步密码 |
| `csCloudPassMismatch` | 云端数据已加密且同步密码不匹配，无法同步 | 密码对不上，解不开云端数据 |
| `csCloudNoFile` | 云端没有播放列表文件，无法恢复 | 云端还没有播放列表，没法恢复 |
| `playlistSyncResult` | {what}：{message} | {what}：{message}（保留，结构化提示） |

---

## D. 网络 / 发现 / 连接

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `connectRequestSent` | 已发送连接请求，等待对方验证 | 📨 请求已发出，等对方确认 |
| `connectFailed` | 连接失败，请检查 IP 地址是否正确或对方是否在线 | 没连上，确认下 IP 或对方在线没 |
| `connectIpEmpty` | 请输入 IP 地址 | 先填个 IP 地址呀 |
| `connectIpInvalid` | IP 地址格式不正确 | 这个 IP 格式不对哦 |
| `connectIpNotLan` | 仅允许内网 IP 地址 | 只能填内网 IP 哈 |
| `discoverConnectFailed` | 连接失败，请检查网络或对方是否在线 | 连不上，查查网络或对方在不在 |
| `discoverAlreadyConnected` | 该设备已连接 | 这个设备已经连着啦 |
| `discoverAlreadyPending` | 正在等待对方验证，请勿重复发送 | 已经在等对方确认了，别重复发 |
| `tcpConnectSuccess` | TCP 连接成功 | 🔌 TCP 连上了 |
| `netHostResolveFailed` | 无法解析主机 {host} | 解析不了 {host}，域名有问题？ |
| `netChatIpv6On` / `netChatIpv6Off` | （开关状态说明，通常非 toast） | 保留原文案 |

---

## E. 播放器 / 视频 / 投屏

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `playerResumeFrom` | 已从 {position} 继续播放 | ▶️ 从 {position} 接着看 |
| `playerSavedToAlbum` | 已保存到相册 | 💾 已存到相册 |
| `playerScreenshotSavedToAlbum` | 截图 {fileName} 已保存到相册 | 📸 {fileName} 已存相册 |
| `playerCopyLinkDone` | 已复制：{url} | 📋 已复制：{url} |
| `playerCopyLinkNotBili` | 仅 B 站视频支持复制链接 | 只有 B 站视频能复制链接哦 |
| `playerAlignAspectRatioDone` | 窗口已对齐视频比例 | 窗口已贴合视频比例 |
| `playerAlignAspectRatioFailed` | 无法获取视频尺寸 | 拿不到视频尺寸，对齐失败 |
| `playerScreenshotFailed` | 截图失败: {error} | 截图翻车了：{error} |
| `playerSaveFailed` | 保存失败: {error} | 保存失败：{error} |
| `playerPipFailed` | 画中画调用失败: {error} | 画中画没调起来：{error} |
| `playerAllEpisodesPlayed` | 已播放完全部 {count} 集 | 🏆 全部 {count} 集看完啦 |
| `playerQualityLocked` | 该画质不可用（需登录或大会员） | 这画质要登录/大会员才能看 |
| `playerSubtitleLoadFailed` | 字幕加载失败 | 字幕没加载出来 |
| `dlnaCastStarted` | 已投屏到 {device} | 📺 已投到 {device} |
| `dlnaCastFailed` | 投屏失败：{device} | 投屏没成功：{device} |
| `dlnaCastingTo` | 正在投屏到 {device} | 正在投到 {device}… |

---

## F. 评论 / 弹幕 / 笔记

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `commentLikeFail` | 点赞失败：{error} | 点赞没成：{error} |
| `commentLikeLoginRequired` | 请先登录 B 站账号（并开启携带 Cookie）后再点赞 | 先登录 B 站（打开携带 Cookie）才能点赞哦 |
| `commentLoadFail` | 评论加载失败，请检查网络 | 评论刷不出来，查查网络 |
| `commentLoadMoreFail` | 加载更多评论失败 | 更多评论没加载出来 |
| `commentComposerEmpty` | 评论内容不能为空 | 评论不能空着呀 |
| `commentComposerCaptureFailed` | 截图失败，请先开始播放 | 先播起来才能截图哦 |
| `commentComposerUploadFailed` | 图片上传失败，请重试 | 图片没传上去，再试一次 |
| `commentNetworkError` | 网络异常: {error} | 网络不对劲：{error} |
| `commentApiError` | {message}（code={code}） | {message}（错误码 {code}） |
| `commentException` | 异常: {error} | 出状况了：{error} |
| `commentDeleted` | 评论已删除 | 🗑️ 评论已删除 |
| `noteEditorPublished` | 笔记已发布 | 📝 笔记已发布 |
| `noteEditorDraftSaved` | 已自动保存草稿 | 💾 草稿已自动保存 |
| `noteEditorPublishNetworkError` | 发布失败（网络异常），草稿已保存 | 网络问题没发出去，草稿先存着了 |
| `noteEditorPublishRejected` | 发布被服务端拒绝，草稿已保留 | 服务端没通过，草稿还在 |

---

## G. 聊天 / 文件 / 图片 / 截图

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `chatImageSent` | ✅ 图片已发送 | 🖼️ 图片已发出 |
| `chatImageSendFailed` | 发送图片失败 | 图片没发出去 😣 |
| `chatFileSentSuccess` | ✅ {fileName} 发送成功 | ✅ {fileName} 发成功了 |
| `chatFileSendFailed` | 发送文件失败 | 文件没发出去 😣 |
| `chatImageCopied` | ✅ 图片已复制到剪贴板 | 📋 图片已复制 |
| `chatSaveSuccess` | ✅ 保存成功 | 💾 保存成功 |
| `chatSaveFailed` | 保存失败: {error} | 保存失败：{error} |
| `chatMessageDeleted` | 消息已删除 | 🗑️ 消息已删除 |
| `chatReconnectFailed` | 重连失败，请检查网络或对方是否在线 | 重连没成功，查查网络或对方在不在 |
| `chatConnDisconnected` | 对方已断开连接 | 对方跑啦，连接断了 |
| `chatConnRejected` | 连接已被拒绝 | 连接被拒绝了 |
| `chatCopyFailed` | 复制失败 | 复制没成功 |
| `chatClipboardEmptyOrUnsupported` | 剪贴板为空或格式不支持 | 剪贴板是空的，或格式不支持 |
| `lsSendSuccess` | 成功发送 {count} 个文件 | 📤 {count} 个文件发成功了 |
| `lsSendFailed` | 有 {count} 个文件发送成功，其余失败 | {count} 个发成功，剩下的挂了 |
| `lsFileReceived` | 已接收文件：{fileName} | 📥 收到文件：{fileName} |
| `viewerSaveSuccess` | 保存成功 | 💾 保存成功 |
| `viewerSaveFailed` | 保存失败: {error} | 保存失败：{error} |
| `viewerCopyFailed` | 复制失败: {error} | 复制失败：{error} |
| `viewerShareFailed` | 分享失败: {error} | 分享失败：{error} |
| `screenshotSavedToAlbum` | 截图已保存到相册 | 📸 截图已存相册 |
| `screenshotSavedTitle` | 截图已保存 | 📸 截图已保存 |

---

## H. 存储 / 缓存 / 历史

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `storageCleared` | {label}已清理 | 🧹 {label}已清理 |
| `storageAllCleared` | 缓存已全部清理 | 🧹 缓存清得干干净净 |
| `playHistoryDeleted` | 已删除「{title}」的播放记录 | 🗑️ 已删掉「{title}」的进度 |
| `historyClearAllConfirm` | 确定要清空全部{label}吗？此操作不可恢复。 | 要把全部{label}清空吗？删了可找不回来哦 |
| `myCacheClearAllConfirm` | 将删除全部已缓存视频（{count}个视频 · {size}），确定吗？ | 会删掉全部缓存视频（{count}个 · {size}），确定？ |
| `cacheActionCaching` | 缓存中 | 缓存中… ⏳ |

---

## I. 设置 / 主题 / 外观 / 个人资料

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `themeColorExtracted` | 已从图片提取主题色 | 🎨 已从图片提取主题色 |
| `themeColorFailed` | 取色失败: {error} | 取色失败：{error} |
| `themeColorCopied` | 已复制色号: {hex} | 📋 色号已复制：{hex} |
| `themeSwitched` | 已切换至 {name} 主题 | 🎨 已切到 {name} 主题 |
| `themeDeleted` | 已删除 "{name}" | 🗑️ 已删除「{name}」 |
| `themeCreated` | 主题 "{name}" 已创建并保存 | ✨ 主题「{name}」已创建保存 |
| `profileAvatarUpdated` | ✅ 头像已更新 | 🐱 头像已更新 |
| `profileAvatarFailed` | ❌ 选择头像失败: {error} | 头像没换成功：{error} |
| `profileNicknameUpdated` | ✅ 昵称已更新 | ✏️ 昵称已更新 |
| `settingsNicknameUpdated` | 昵称已更新 | ✏️ 昵称已更新 |
| `settingsAvatarUpdated` | 头像已更新 | 🐱 头像已更新 |
| `drawerThemeSwitched` | 已切换到 {mode} | 🎨 已切到 {mode} |
| `drawerBackgroundUpdated` | 侧边栏背景已更新 | 侧边栏背景换好啦 |
| `drawerBackgroundRestored` | 已恢复默认背景 | 已恢复默认背景 |
| `drawerBackgroundSetFailed` | 设置失败: {error} | 背景没设成：{error} |
| `pageBgSaved` | 背景图已更新 | 背景图换好啦 🎨 |
| `pageBgCleared` | 背景图已清除 | 背景图已清除 |
| `playlistDetailBgUpdated` | ✅ 背景图已更新 | 🎨 背景图已更新 |
| `playlistDetailBgRemoved` | 已恢复默认背景 | 已恢复默认背景 |
| `playlistDetailBgFail` | 设置失败：{error} | 背景没设成：{error} |

---

## J. 播放列表 / 发现 / 扫码 / 联系人 / 其他

| arb key | 当前中文 | 活力建议 |
|---|---|---|
| `playlistCreated` | 已创建: {name} | ✨ 播放列表「{name}」已创建 |
| `playlistImportAdded` | 已添加 {count} 个文件 | ➕ 已加 {count} 个文件 |
| `playlistRenameSaved` | 已重命名 | ✏️ 已重命名 |
| `playlistSelectDeleted` | 已删除 {count} 集 | 🗑️ 已删 {count} 集 |
| `playlistDanmakuAttached` | 已为 {count} 集附加弹幕 | 💬 已给 {count} 集挂上弹幕 |
| `slicerSuccess` | 切割成功，已添加到开始屏幕 | ✂️ 切好啦，已加到开始屏幕 |
| `slicerSaveFailed` | 保存失败: {error} | 保存失败：{error} |
| `scanCopiedToClipboard` | 已复制到剪贴板 | 📋 已复制 |
| `scanLinkCopied` | 链接已复制 | 📋 链接已复制 |
| `scanFriendAdded` | 已发送好友请求，等待对方验证 | 🤝 好友请求已发，等对方确认 |
| `scanFriendAddFailed` | 添加好友失败，请检查网络或对方是否在线 | 加好友没成功，查查网络或对方在不在 |
| `myQrCopied` | 已复制到剪贴板 | 📋 已复制 |
| `discoverIpCopied` | 已复制 {ip} | 📋 已复制 {ip} |
| `contactPickerSent` | 已发送给 {count} 个联系人 | 📤 已发给 {count} 个联系人 |
| `contactPickerSendFailed` | 发送失败：{error} | 发送失败：{error} |
| `contactPickerNotConnected` | 「{name}」未连接，无法发送 | 「{name}」还没连上，发不了 |
| `browserUaUpdated` | UA 已更新并刷新页面 | UA 已更新，页面刷新了 |
| `browserCookieCopied` | Cookie已复制 | 📋 Cookie 已复制 |
| `browserSaveFailed` | 保存失败: {error} | 保存失败：{error} |
| `webdavPassphraseGenerated` | 已生成同步密码并复制到剪贴板，请在其他设备上填入相同密码 | 🔑 密码已生成并复制，去其他设备填一样的 |

---

## 备注
- **保留技术性文案**：像 `commentSubHttpError`（楼中楼 HTTP {code}）、`dohQueryFailed`、`biliHttpError`、`searchGaia*` 这类偏开发/接口语义的，建议维持原样，避免掩盖真实错误信息。
- **带 `SnackBarAction` 的提示**（如"去登录""点击操作"类）通常是对话/引导型，不在纯 toast 范围，可按需在对应调用处单独调整语气。
- **硬编码提示**：项目里还有一部分提示是直接在 Dart 里写死的中文字符串（注释约定新功能默认硬编码中文），如果要做"全局统一有活力"，那些也得一并改——需要的话我可以用 Grep 把 `showAppToast(` 里硬编码中文的调用也捞出来。
