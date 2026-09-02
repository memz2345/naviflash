import 'package:flutter/widgets.dart';

class DeviceUtils {
  /// 获取设备逻辑宽度（dp）
  static double getDeviceWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// dp 转 px（屏幕实际像素）
  static double dp2px(double dp, BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    return dp * ratio;
  }
}