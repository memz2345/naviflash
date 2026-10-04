# 听视频页：接收/回传进度 + 沉浸背景 + 统一返回按钮
import io

path = 'lib/screens/bilibili_audio_page.dart'
with io.open(path, encoding='utf-8') as f:
    t = f.read()

PAIRS = [
    # 1) imports
    (
        "import 'dart:async';\nimport 'dart:math' as math;\n",
        "import 'dart:async';\nimport 'dart:math' as math;\nimport 'dart:ui' show ImageFilter;\n",
    ),
    (
        "import 'package:naviflash/widgets/liquid_glass_menu_button.dart';\n",
        "import 'package:naviflash/widgets/expressive_app_bar.dart';\n"
        "import 'package:naviflash/widgets/liquid_glass_menu_button.dart';\n",
    ),
    # 2) 构造参数 + 字段
    (
        "    this.initialIndex = 0,\n    this.ownerName,\n",
        "    this.initialIndex = 0,\n    this.initialPosition,\n    this.ownerName,\n",
    ),
    (
        "  final List<AudioEpisode> episodes;\n  final int initialIndex;\n",
        "  final List<AudioEpisode> episodes;\n  final int initialIndex;\n\n"
        "  /// 起始播放位置（从视频页「听视频」跳过来时带上，接着上次的进度听）。\n"
        "  /// 只在初始那一 P 生效，切集后不沿用。\n"
        "  final Duration? initialPosition;\n",
    ),
    # 3) state 待应用进度
    (
        "  double _rate = 1.0;\n",
        "  double _rate = 1.0;\n\n"
        "  /// 待应用的起始进度（首次 open 媒体后消费掉，只生效一次）。\n"
        "  Duration? _pendingSeek;\n",
    ),
    (
        "    );\n    unawaited(_init());\n",
        "    );\n    _pendingSeek = widget.initialPosition;\n    unawaited(_init());\n",
    ),
    # 4) open 后补 seek
    (
        "      if (_rate != 1.0) await _player!.setRate(_rate);\n"
        "      if (autoPlay) await _player!.play();\n",
        "      if (_rate != 1.0) await _player!.setRate(_rate);\n"
        "      // 从视频页「听视频」跳过来时接着上次进度听（只消费一次）\n"
        "      final pending = _pendingSeek;\n"
        "      if (pending != null && pending > Duration.zero) {\n"
        "        _pendingSeek = null;\n"
        "        await _player!.seek(pending);\n"
        "      }\n"
        "      if (autoPlay) await _player!.play();\n",
    ),
    # 5) Scaffold → PopScope + 自定义返回按钮
    (
        "    return Scaffold(\n"
        "      backgroundColor: cs.surface,\n"
        "      appBar: AppBar(\n"
        "        title: Text(l10n.audioPageTitle),\n",
        "    return PopScope(\n"
        "      // 返回时把当前进度交还给视频页（继续看）：leading 与系统返回走同一条路\n"
        "      canPop: false,\n"
        "      onPopInvokedWithResult: (didPop, _) {\n"
        "        if (didPop) return;\n"
        "        Navigator.of(context).pop(_posNotifier.value);\n"
        "      },\n"
        "      child: Scaffold(\n"
        "      backgroundColor: cs.surface,\n"
        "      appBar: AppBar(\n"
        "        // 与项目其它页面同款毛玻璃圆钮（默认 AppBar 返回键在深色主题上\n"
        "        // 只有 hover 才浮出圆底，观感不统一）\n"
        "        leading: MorphIconButton(\n"
        "          icon: Icons.arrow_back,\n"
        "          tooltip: l10n.commonBackTooltip,\n"
        "          onTap: () => Navigator.of(context).pop(_posNotifier.value),\n"
        "        ),\n"
        "        title: Text(l10n.audioPageTitle),\n",
    ),
    # 6) body 加沉浸背景层
    (
        "      body: SafeArea(\n        child: _error != null\n",
        "      body: Stack(\n"
        "        children: [\n"
        "          // 沉浸底：封面模糊 + 压暗（无封面时退回主题渐变），\n"
        "          // 避免整屏只剩主题色\n"
        "          Positioned.fill(child: _buildImmersiveBackdrop(cs)),\n"
        "          SafeArea(\n        child: _error != null\n",
    ),
    # 7) 闭合 Stack / Scaffold / PopScope
    (
        "                    )),\n      ),\n    );\n  }\n\n  Widget _buildError(",
        "                    )),\n"
        "          ),\n"
        "        ],\n"
        "      ),\n"
        "      ),\n"
        "    );\n"
        "  }\n"
        "\n"
        "  /// 沉浸背景：封面高斯模糊铺满 + 压暗；没有封面时用主题色竖直渐变兜底。\n"
        "  Widget _buildImmersiveBackdrop(ColorScheme cs) {\n"
        "    final cover = widget.cover;\n"
        "    if (cover.isEmpty) {\n"
        "      return DecoratedBox(\n"
        "        decoration: BoxDecoration(\n"
        "          gradient: LinearGradient(\n"
        "            begin: Alignment.topCenter,\n"
        "            end: Alignment.bottomCenter,\n"
        "            colors: [cs.surfaceContainerHighest, cs.surface],\n"
        "          ),\n"
        "        ),\n"
        "      );\n"
        "    }\n"
        "    return Stack(\n"
        "      fit: StackFit.expand,\n"
        "      children: [\n"
        "        ImageFiltered(\n"
        "          imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),\n"
        "          child: Image(\n"
        "            image: CachedImageProvider(cover),\n"
        "            fit: BoxFit.cover,\n"
        "            errorBuilder: (_, __, ___) => ColoredBox(color: cs.surface),\n"
        "          ),\n"
        "        ),\n"
        "        // 压暗，保证前景标题 / 按钮可读\n"
        "        ColoredBox(color: Colors.black.withValues(alpha: 0.45)),\n"
        "      ],\n"
        "    );\n"
        "  }\n"
        "\n"
        "  Widget _buildError(",
    ),
]

for old, new in PAIRS:
    assert t.count(old) == 1, (old[:60], t.count(old))
    t = t.replace(old, new)

with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(t)
print('patched', path)
