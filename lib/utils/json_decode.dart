                             
  
                                                      
                                               
                                   
  
                                                      
                                            
import 'dart:convert';

import 'package:flutter/foundation.dart';

Future<dynamic> decodeJsonAsync(
  String source, {
  int isolateThreshold = 64 * 1024,
}) async {
  if (source.length < isolateThreshold) return jsonDecode(source);
  return compute(jsonDecode, source);
}
