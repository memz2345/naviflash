import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum BlurPosition { top, bottom, both }

class ProgressiveBlur extends StatelessWidget {
  final double blur;
  final double height;
  final BlurPosition position;
  final double borderRadius;
  final bool progressive;
  
  /// sigma 换算比例 (默认 0.25 视觉更清淡，避免 Flutter 叠加模糊发脏)
  final double sigmaScale;
  /// 底部衰减幂次 (默认 1.6，值越大底部归零越快)
  final double fadePower;

  const ProgressiveBlur({
    super.key,
    required this.blur,
    required this.height,
    this.position = BlurPosition.top,
    this.borderRadius = 0,
    this.progressive = true,
    this.sigmaScale = 0.25,
    this.fadePower = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    final showTop = position == BlurPosition.top || position == BlurPosition.both;
    final showBottom = position == BlurPosition.bottom || position == BlurPosition.both;

    return Stack(
      children: [
        if (showTop) _buildBlurSection(isTop: true),
        if (showBottom) _buildBlurSection(isTop: false),
      ],
    );
  }

  Widget _buildBlurSection({required bool isTop}) {
    final layers = _generateLayers(height, blur, isTop, progressive);
    
    return Align(
      alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop ? borderRadius : 0),
            topRight: Radius.circular(isTop ? borderRadius : 0),
            bottomLeft: Radius.circular(!isTop ? borderRadius : 0),
            bottomRight: Radius.circular(!isTop ? borderRadius : 0),
          ),
          child: Stack(
            // 按高度升序排列：大层(弱模糊)在下，小层(强模糊)在上
            children: layers.map((layer) {
              return SizedBox(
                width: double.infinity,
                height: max(0, layer.height),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: layer.blur * sigmaScale,
                    sigmaY: layer.blur * sigmaScale,
                  ),
                  // 完全透明，不叠加任何主题色或渐变
                  child: Container(color: Colors.transparent),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_BlurLayer> _generateLayers(
    double totalHeight,
    double targetBlur,
    bool isTop,
    bool useProgressive,
  ) {
    if (!useProgressive) {
      return [_BlurLayer(height: totalHeight, blur: targetBlur)];
    }

//  更激进：精细层数增加，衰减指数提升至 2.6，生成更多更薄的层
    final fineLayers = max(0, (totalHeight / 2.5).floor());
    final layersCount = _calculateLayersCount(totalHeight, fineLayers);
    final layerCount = max(0, layersCount - 1);

    // 1. 计算进度列表
    final progressList = <double>[];
    double tmpHeight = totalHeight;
    for (int i = 1; i <= layerCount; i++) {
      if (i <= fineLayers) {
        tmpHeight -= 2;
      } else {
        final j = i - fineLayers;
        tmpHeight -= pow(j + 1, 2.6).toDouble(); // 激进衰减
      }
      final covered = totalHeight - max(0, tmpHeight);
      final p = totalHeight > 0 ? (covered / totalHeight).clamp(0.0, 1.0) : 0.0;
      progressList.add(p);
    }

    // 2. RMS 缩放 + 幂次曲线加速底部归零
    final sumPSq = progressList.fold(0.0, (acc, p) => acc + p * p);
    final scale = sumPSq > 0 ? targetBlur / sqrt(sumPSq) : 0.0;
    final perLayerBlur = progressList.map((p) => scale * pow(p, fadePower)).toList();

    // 3. 生成层数据 (无颜色/渐变)
    final layers = <_BlurLayer>[];
    double theight = totalHeight;
    for (int i = 1; i <= layerCount; i++) {
      if (i <= fineLayers) {
        theight -= 2;
      } else {
        final j = i - fineLayers;
        theight -= pow(j + 1, 2.6).toDouble();
      }
      layers.add(_BlurLayer(
        height: max(0, theight),
        blur: perLayerBlur[i - 1],
      ));
    }

    layers.sort((a, b) => a.height.compareTo(b.height));
    return layers;
  }

  int _calculateLayersCount(double totalHeight, int fineLayers) {
    double h = totalHeight;
    int i = 1;
    while (h > 0) {
      if (i <= fineLayers) {
        h -= 2;
      } else {
        final j = i - fineLayers;
        h -= pow(j + 1, 2.6).toDouble();
      }
      i++;
    }
    return i;
  }
}

class _BlurLayer {
  final double height;
  final double blur;
  _BlurLayer({required this.height, required this.blur});
}