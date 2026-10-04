# PiliPlus vs naviflashv2 功能差距报告

> 第二轮复核：2026-09-14
> 基准：本地快照 `F:\f\piliplus_ref\PiliPlus-main`（2026-09-07 抓取，对应线上 ~2.1.4）
> 做法：两个子代理分别产出双向功能清单 → 关键词 grep 逐项复核 → 人工判定。**不靠文件名猜**。

---

## 一、较第一版报告的变化

### 1. 已补齐（第一版列在 P0/P1，本轮确认已实现）

| 功能 | 落点 |
|---|---|
| 话题页 | `screens/bilibili_topic_page.dart` |
| 关注分组 / 关注内搜索 / 分组排序 | `follow_tag_manage_page.dart`、`follow_search_page.dart`、`bilibili_follow_page.dart` |
| 直播搜索 | `screens/bilibili_live_search_page.dart` |
| 空间隐私设置 | `screens/space_privacy_settings_page.dart` |

### 2. 更正（第一版误判为「缺 / 弱」）

| 项 | 第一版结论 | 实际 |
|---|---|---|
| 音量均衡 | 🟡 弱 | ✅ **已有** —— `player_settings_service` 的 `player_audio_normalization`（disable / dynaudnorm / loudnorm） |
| 全站排行榜 | 🟡 半 | ✅ **已有** —— `BiliPopularListKind.ranking` 走 `x/web-interface/ranking/v2` 全站综合榜 |
| 收藏夹排序 | 未提 | ✅ 夹内排序已有（最近收藏 / 最多播放 / 最近投稿）；**缺的只是「收藏夹目录本身的排序」** |

---

## 二、当前缺失清单

### P0 —— 日常真会点到的入口

| 功能 | PiliPlus | naviflashv2 | 备注 |
|---|---|---|---|
| 硬币 / 经验流水 | `pages/coin_log`、`pages/exp_log` | ❌ | 接口现成（`x/member/coin/log`、`x/member/exp/log`），半天量 |
| 黑名单管理列表 | `pages/blacklist` | 🟡 半 | 能拉黑 / 移除（user_space act 6/128），无管理列表页 |
| 登录设备管理 / 登录记录 | `pages/login_devices`、`pages/login_log` | ❌ | 安全类，接口现成 |
| 我的评论 | `pages/my_reply` | ❌ | 注意：消息中心的「**回复我的**」≠ 我发出的评论 |
| 稍后再看搜索 | `pages/later_search` | ❌ | 稍后再看列表页已有，缺搜索框 |

### P1 —— 发布侧与社交动作

| 功能 | PiliPlus | naviflashv2 | 备注 |
|---|---|---|---|
| 投票动态 / 预约发布 | `dynamics_create_vote`、`dynamics_create_reserve` | ❌ | gRPC pb 里已有 vote 结构，未接 UI |
| 分享到私信 | `pages/share` | 🟡 半 | 只有复制链接 / 系统分享 / 浏览器打开 |
| 收藏表情管理 | `pages/emote` | 🟡 半 | 发表情有（`emote_picker_panel`），收藏管理无 |
| 转发 / @ 选人（联系人选择器） | `pages/contact` | ❌ | — |
| @我的动态独立页 | `pages/dynamics_mention` | 🟡 半 | 消息中心有 @ 通知聚合 |
| 收藏夹目录排序 | `pages/fav_folder_sort` | ❌ | 夹内排序已有，目录排序无 |
| 睡眠定时 / 定时关机 | `services/shutdown_timer_service` | ❌ | 挂机看直播场景会用到 |
| 应用内迷你浮窗 | 完整 | 🟡 弱 | 有桌面 PiP 小窗 + Android PiP，无应用内悬浮小窗 |

### P2 —— 小众业务（可做可不做）

| 功能 | PiliPlus | naviflashv2 |
|---|---|---|
| 会员购橱窗 `member_shop` | ✅ | ❌ |
| 漫画 `member_comic` | ✅ | ❌ |
| 课堂 / 芝士 `member_cheese` | ✅ | ❌ |
| 赛事 `match_info` | ✅ | ❌ |
| 小黄条气泡 `bubble` | ✅ | ❌ |
| 私信屏蔽列表 `whisper_block` | ✅ | ❌ |
| 入站必刷 / 每周必看 | ✅ | ✅（`BiliPopularListKind.precious/weekly`）**不算缺口** |

> PiliPlus 的会员购 / 漫画 / 课堂本质也是「空间子 Tab + 外跳网页」，含金量不高。

---

## 三、naviflashv2 反超项（PiliPlus 没有或更弱）

| 能力 | 说明 |
|---|---|
| AI 翻译头（自研逆向） | `x-bili-locale-bin/metadata-bin/device-bin`，PiliPlus 无此套 |
| ONNX 智能防遮挡 | AI 字幕遮挡避让，按需下载模型（`third_party/onnxruntime` 纯 Dart fork） |
| Anime4K 超分辨率 | `super_resolution_service` + `assets/anime4k_shaders` |
| 视频剪辑 / GIF / 动态照片 | `video_clip_service`、`motion_photo_service` |
| Windows 深度集成 | 任务栏进度、跳转列表、SMTC、WinRT 大图通知、文件关联 |
| Android 桌面小组件 | 收藏夹预览，全手写原生（不引 home_widget） |
| iOS 转场 + Android 预测式返回 | `ios_push_transition` + `PredictiveBackHook` + 整页 Hero |
| CDN 测速 / 网络设置 | `cdn_speed_test_service` |
| 视觉体系 | Liquid Glass、动态取色、M3 Expressive 动效组件 |

---

## 四、基础设施差异（不影响功能，影响维护）

| 项 | PiliPlus | naviflashv2 |
|---|---|---|
| 本地数据库 | `hive_ce` | shared_preferences + secure_storage + 文件缓存 |
| 崩溃上报 | `catcher_2` | 基础级（`log_service` + `log_viewer_page`） |
| gRPC 覆盖面 | audio/dm/dyn/im/reply/space/url/view 9 域 | **仅热门 Popular**（IM 已改走 web HTTP） |
| 平台适配 | Android/iOS/Pad/Win/Linux/macOS 全量 | **Windows 最深**，iOS/Linux/macOS/web 仅基础可跑 |

---

## 五、建议动手顺序（性价比排序）

1. **硬币 / 经验流水** —— 接口最简单（`x/member/coin/log`、`x/member/exp/log`），半天
2. **黑名单管理列表** —— 半个页面，接口现成
3. **登录设备管理** —— 安全类，接口现成
4. **我的评论** —— 补齐社交闭环
5. **稍后再看搜索 + 收藏夹目录排序** —— 各半天
6. **投票动态 / 预约发布** —— 发布侧最缺的一块
7. 其余按兴趣排

---

*报告生成 2026-09-14（第一版）；2026-09-14 第二轮复核更新*
