# liquid_glass_widgets（vendored，含底栏拖拽崩溃补丁）

来源：`liquid_glass_widgets` **0.30.2**（pub，作者 sdegenaar
<https://github.com/sdegenaar/liquid_glass_widgets>）。

只复制了 `lib/`、`shaders/`、`pubspec.yaml`、`LICENSE`、`README.md`、
`CHANGELOG.md`；`example/`、`doc/`、`scripts/` 未收录。

## 为什么 vendor

安卓开启「高级玻璃渲染（片元着色器）」后，**拖动液态玻璃底栏会闪退**。

根因（源码级，已确认）：

1. `MaskingQuality.high` 的底栏用两个 `ClipPath` 把图标层裁成
   「选中胶囊内 / 外」两份，模拟 Apple 的 magic lens；
2. 这层裁剪用的是 `clipBehavior: Clip.antiAliasWithSaveLayer`
   —— 每帧都会 `pushClipPath(needsCompositing: true)`，即**离屏 saveLayer**；
3. clipper 是 `JellyClipper`（jelly 形变 + 拖拽位移），拖拽时
   `shouldReclip` 每帧返回 true → **每帧重建 Path + 重开 2 个全屏宽 saveLayer**；
4. 再叠加 `GlassQuality.premium`（片元着色器 + `BackdropFilter` +
   几何纹理 `toImageSync`），安卓 Impeller（GLES/Vulkan）上 GPU 资源迅速
   被打爆：模拟器实测直接是 gfxstream `bad color buffer handle`，
   整个渲染进程死；真机表现为拖动底栏闪退。

包作者在 `lib/widgets/shared/glass_effect.dart:951` 自己写明过：
> `Clip.antiAlias` is used (not `Clip.antiAliasWithSaveLayer`) because
> `antiAliasWithSaveLayer` would isolate the BackdropFilter ...
> `antiAlias` creates a ClipPathLayer with **no saveLayer**

也就是说**底栏那 6 处与包内既有实践不一致，属于实现疏忽**。

## 补丁清单（搜索 `[[naviflash vendored patch]]` / `Vendored patch` 可定位）

| 文件 | 改动 |
|---|---|
| `lib/src/widgets/surfaces/tab_bar_bottom_internal.dart` | 4 处 `clipBehavior: Clip.antiAliasWithSaveLayer` → `Clip.antiAlias` |
| `lib/src/widgets/surfaces/tab_bar_searchable_internal.dart` | 2 处同上 |

`antiAlias` 同样有亚像素抗锯齿，只是不再插一层 saveLayer ——
胶囊边缘观感不变，拖动时不再每帧分配离屏缓冲。

重打补丁：`python tool/_patch_liquid_glass.py`（幂等，已打过会跳过）。

## 退出条件

上游修掉这 6 处（或提供某个开关）后，删掉本目录、把 pubspec 改回
`liquid_glass_widgets: ^0.30.x` 即可。
