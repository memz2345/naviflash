import 'package:flutter/widgets.dart';

class DeviceUtils {
                  
  static double getDeviceWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

                     
  static double dp2px(double dp, BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    return dp * ratio;
  }
}