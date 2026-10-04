# -*- coding: utf-8 -*-
"""给 vendored 的 liquid_glass_widgets 打「底栏拖拽 saveLayer」补丁。

背景：底栏在 MaskingQuality.high 下用 ClipPath(clipBehavior:
Clip.antiAliasWithSaveLayer) 包住图标层，clipper 是 JellyClipper，拖拽时
shouldReclip 每帧为真 → 每帧重建 2 个全宽 saveLayer。叠加 premium 片元
着色器 + BackdropFilter 后，安卓（Impeller GLES/Vulkan）GPU 资源迅速耗尽，
表现为拖动底栏闪退 / 整个渲染进程崩。

包作者自己在 widgets/shared/glass_effect.dart 里写明：这类裁剪应当用
Clip.antiAlias（无 saveLayer，同样有亚像素抗锯齿），antiAliasWithSaveLayer
会额外隔离合成层。底栏这几处与包内既有实践不一致，属实现疏忽。

用法：python tool/_patch_liquid_glass.py
"""
import io
import os

ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    '..',
    'third_party',
    'liquid_glass_widgets',
    'lib',
)

TARGETS = [
    'src/widgets/surfaces/tab_bar_bottom_internal.dart',
    'src/widgets/surfaces/tab_bar_searchable_internal.dart',
]

OLD = 'clipBehavior: Clip.antiAliasWithSaveLayer,'
NEW = 'clipBehavior: Clip.antiAlias, // Vendored patch'

HEADER = (
    '// [[naviflash vendored patch]] 见 third_party/liquid_glass_widgets/VENDORED.md\n'
    '// 底栏图标层的 ClipPath 去掉了 antiAliasWithSaveLayer：拖拽时该裁剪每帧\n'
    '// 都会重建，saveLayer 会跟着每帧重开，叠加 premium 着色器后安卓上会把\n'
    '// GPU 资源打爆（拖动底栏闪退）。antiAlias 同样抗锯齿但不建离屏层。\n'
)

changed = 0
for rel in TARGETS:
    path = os.path.join(ROOT, rel)
    with io.open(path, encoding='utf-8') as f:
        src = f.read()
    n = src.count(OLD)
    if n == 0:
        print('SKIP(已打过或无命中)', rel)
        continue
    src = src.replace(OLD, NEW)
    if '[[naviflash vendored patch]]' not in src:
        src = HEADER + src
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(src)
    print('OK  %s  替换 %d 处' % (rel, n))
    changed += n

print('\n共替换 %d 处' % changed)
