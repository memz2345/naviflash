                                       
                                          
                    
import 'package:flutter/material.dart';

import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/videoshot_service.dart';

class BiliSeekPreview extends StatelessWidget {
  final VideoShotData data;
  final int index;

                          
  final double cellWidth;

  const BiliSeekPreview({
    super.key,
    required this.data,
    required this.index,
    this.cellWidth = 168,
  });

  @override
  Widget build(BuildContext context) {
    final xLen = data.imgXLen <= 0 ? 10 : data.imgXLen;
    final yLen = data.imgYLen <= 0 ? 10 : data.imgYLen;
    final total = xLen * yLen;
    final idx = index.clamp(0, data.index.length - 1);
    final page = total <= 0 ? 0 : (idx ~/ total).clamp(0, data.image.length - 1);
    final align = total <= 0 ? 0 : idx % total;
    final x = align % xLen;
    final y = align ~/ xLen;

    final aspect = (data.imgXSize > 0 && data.imgYSize > 0)
        ? data.imgXSize / data.imgYSize
        : 16 / 9;
    final cellW = cellWidth;
    final cellH = cellW / aspect;
    final url = data.image[page];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: cellW,
          height: cellH,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(-x * cellW, -y * cellH),
              child: Image(
                image: CachedImageProvider(url),
                width: xLen * cellW,
                height: yLen * cellH,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: xLen * cellW,
                  height: yLen * cellH,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatSeconds(data.index[idx]),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatSeconds(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(ss)}' : '${two(m)}:${two(ss)}';
  }
}
