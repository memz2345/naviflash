import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class _IsolateParams {
  final Uint8List bytes;
  final int maxDimension;
  final double saturationBoost;
  _IsolateParams(this.bytes, this.maxDimension, this.saturationBoost);
}

bool _isNearBlack(int r, int g, int b) => r < 35 && g < 35 && b < 35;
bool _isNearWhite(int r, int g, int b) => r > 220 && g > 220 && b > 220;

Color _applySaturationBoost(double r, double g, double b, double boost) {
  final gray = 0.299 * r + 0.587 * g + 0.114 * b;
  int clampChannel(double c) => (gray + (c - gray) * boost).clamp(0, 255).round();
  return Color.fromRGBO(clampChannel(r), clampChannel(g), clampChannel(b), 1);
}

Color _analyzeInIsolate(_IsolateParams params) {
  img.Image? image = img.decodeImage(params.bytes);
  if (image == null) return Colors.deepPurple;

  final maxDim = params.maxDimension;
  if (image.width > maxDim || image.height > maxDim) {
    image = img.copyResize(image,
        width: maxDim, height: maxDim, maintainAspect: true);
  }

                                
  final pixels = image.getBytes();
  final pixelCount = image.width * image.height;
  
                           
  final bytesPerPixel = pixels.length ~/ pixelCount;
  
  double red = 0, green = 0, blue = 0;
  int count = 0;

                                           
  for (int i = 0; i < pixels.length; i += bytesPerPixel) {
           
    if (i + 2 >= pixels.length) break;
    
    final r = pixels[i];
    final g = pixels[i + 1];
    final b = pixels[i + 2];
    final a = bytesPerPixel > 3 ? pixels[i + 3] : 255;

    if (a < 50) continue;
    if (_isNearBlack(r, g, b)) continue;
    if (_isNearWhite(r, g, b)) continue;

    red += r;
    green += g;
    blue += b;
    count++;
  }

  if (count == 0) {
    double allR = 0, allG = 0, allB = 0;
    int allCount = 0;
    
    for (int i = 0; i < pixels.length; i += bytesPerPixel) {
      if (i + 2 >= pixels.length) break;
      
      final a = bytesPerPixel > 3 ? pixels[i + 3] : 255;
      if (a < 50) continue;
      
      allR += pixels[i];
      allG += pixels[i + 1];
      allB += pixels[i + 2];
      allCount++;
    }
    
    if (allCount == 0) return Colors.deepPurple;
    
    return Color.fromRGBO(
      (allR / allCount).round(),
      (allG / allCount).round(),
      (allB / allCount).round(),
      1,
    );
  }

  final avgR = red / count;
  final avgG = green / count;
  final avgB = blue / count;

  return _applySaturationBoost(avgR, avgG, avgB, params.saturationBoost);
}

Future<Color> analyzeImageColor(
  Uint8List bytes, {
  int maxDimension = 256,
  double saturationBoost = 1.5,
}) {
  return compute(
    _analyzeInIsolate,
    _IsolateParams(bytes, maxDimension, saturationBoost),
  );
}