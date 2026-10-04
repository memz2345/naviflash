                               
  
                                  
  
                                                               
                                             
                                     
                 
  
                                                        
                                
                                          
                                  
                                        
                                     
import 'dart:io';

import 'package:naviflash/services/storage_paths.dart';

abstract final class AppCacheDirs {
                                  
                                         
  static const List<String> legacyNames = StoragePaths.legacyCacheNames;

                                 
  static Future<Directory> root() => StoragePaths.rootFor(StorageSlot.autoCache);

                                         
  static Future<Directory> sub(String name) async {
    final base = await root();
    final dir = Directory('${base.path}/$name');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
