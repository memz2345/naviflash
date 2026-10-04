# canvas_danmaku（内联副本）

来源：<https://github.com/Predidit/canvas_danmaku>（pub.dev: `canvas_danmaku`），
即 [Kazumi](https://github.com/Predidit/Kazumi) 使用的弹幕渲染引擎。作者 Predidit。

- 上游版本：`0.3.3`（对应 `pubspec.yaml` 里的 `version`）
- 内联原因：弹幕系统需要与本工程同步演进（见下方补丁），并且不希望用户在无网络
  环境下因为 pub 拉取失败而构建不了。
- 引用方式：本工程 `pubspec.yaml` 以路径依赖引入

  ```yaml
  canvas_danmaku:
    path: third_party/canvas_danmaku
  ```

- 本目录已从 `analysis_options.yaml` 的静态分析中排除（`third_party/**`），
  升级时请比对上游 diff 后手工合并。

## 相对于上游 0.3.3 的改动

只有一处功能性修复，都在 `lib/danmaku_screen.dart`：

1. **暂停状态下新增弹幕不上屏**（`_handleAddDanmaku`）
   上游在 `_running == false` 时走 `_staticDanmakuItems.value.add(item)`，
   只改列表不 `notifyListeners()`，导致暂停时新增的弹幕（例如用户刚发送的
   弹幕）不会立即出现，要等恢复播放才被 `_resume()` 兜底刷新。
   补丁：该分支补一次 `_staticDanmakuItems.refresh()`。

2. **暂停状态下滚动弹幕不重绘**（`_handleAddDanmaku` 末尾）
   停掉 ticker 后没有逐帧刷新，新加入的滚动弹幕不会出现在右侧入口。
   补丁：`added && !_running` 时补一次 `_tickNotifier.refresh()`。

两处补丁都用 `// 修复（NaviFlash）：…` 注释标记，便于与上游对照。

> 注意：本工程的「防挡弹幕」（主体遮罩 dstOut 挖空）**没有**改这个包 ——
> 它由 `lib/widgets/danmaku/danmaku_view.dart` 里自定义的
> `_DanmakuMaskLayer`（RenderProxyBox）在外层完成，这样升级本包时不会冲突。
