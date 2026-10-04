                                            
  
                                                  
                                  
                                                  
                                                     
                                     
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class MemoryPressureService {
  MemoryPressureService._();

                                   
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void handleMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    tick.value++;
  }
}
