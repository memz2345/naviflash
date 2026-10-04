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
  
                                                  
  final double sigmaScale;
                               
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
                                          
            children: layers.map((layer) {
              return SizedBox(
                width: double.infinity,
                height: max(0, layer.height),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: layer.blur * sigmaScale,
                    sigmaY: layer.blur * sigmaScale,
                  ),
                                     
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

                                   
    final fineLayers = max(0, (totalHeight / 2.5).floor());
    final layersCount = _calculateLayersCount(totalHeight, fineLayers);
    final layerCount = max(0, layersCount - 1);

                
    final progressList = <double>[];
    double tmpHeight = totalHeight;
    for (int i = 1; i <= layerCount; i++) {
      if (i <= fineLayers) {
        tmpHeight -= 2;
      } else {
        final j = i - fineLayers;
        tmpHeight -= pow(j + 1, 2.6).toDouble();        
      }
      final covered = totalHeight - max(0, tmpHeight);
      final p = totalHeight > 0 ? (covered / totalHeight).clamp(0.0, 1.0) : 0.0;
      progressList.add(p);
    }

                             
    final sumPSq = progressList.fold(0.0, (acc, p) => acc + p * p);
    final scale = sumPSq > 0 ? targetBlur / sqrt(sumPSq) : 0.0;
    final perLayerBlur = progressList.map((p) => scale * pow(p, fadePower)).toList();

                        
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