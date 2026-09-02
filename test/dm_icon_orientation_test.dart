import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> analyze(String asset, String label) async {
    final raw = await rootBundle.load(asset);
    final bytes = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    final picInfo = await vg.loadPicture(SvgBytesLoader(bytes), null);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawPicture(picInfo.picture);
    final image = await recorder.endRecording().toImage(1024, 900);
    final data = (await image.toByteData())!;
    int topRight = 0;
    int bottomRight = 0;
    int topLeft = 0;
    int bottomLeft = 0;
    for (int y = 0; y < 900; y++) {
      for (int x = 0; x < 1024; x++) {
        final a = data.getUint8((y * 1024 + x) * 4 + 3);
        if (a == 0) continue;
        if (x >= 500) {
          if (y < 400) {
            topRight++;
          } else if (y >= 500) {
            bottomRight++;
          }
        } else if (x < 500) {
          if (y < 400) {
            topLeft++;
          } else if (y >= 500) {
            bottomLeft++;
          }
        }
      }
    }
    // ignore: avoid_print
    print('[$label] topLeft=$topLeft topRight=$topRight '
        'bottomLeft=$bottomLeft bottomRight=$bottomRight');
  }

  test('dm_on orientation', () async {
    await analyze('assets/bili_icons/dm_on.svg', 'dm_on');
    await analyze('assets/bili_icons/dm_settings.svg', 'dm_settings');
    await analyze('assets/bili_icons/dm_off.svg', 'dm_off');
  });
}
