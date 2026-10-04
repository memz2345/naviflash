                                         
                                                    
                                                 
                              
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' show NativePlayer;

abstract final class PlayerAudioService {
  static const String modeDisable = 'disable';
  static const String modeDynaudnorm = 'dynaudnorm';
  static const String modeLoudnorm = 'loudnorm';

                                         
  static String filterFor(String mode) => switch (mode) {
        modeDynaudnorm => 'lavfi=[dynaudnorm=g=5:f=250:r=0.9:p=0.5]',
        modeLoudnorm => 'lavfi=[loudnorm=I=-16:LRA=11:TP=-1.5]',
        _ => '',
      };

  static String label(String mode) => switch (mode) {
        modeDynaudnorm => '动态均衡（dynaudnorm）',
        modeLoudnorm => '响度均衡（loudnorm）',
        _ => '关闭',
      };

                    
  static Future<void> apply(NativePlayer platform, String mode) async {
    try {
      await platform.setProperty('af', filterFor(mode));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 应用音量均衡失败: $e');
    }
  }
}
