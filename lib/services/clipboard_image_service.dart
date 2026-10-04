                                            
  
                                        
  
                          
                                               
                                                        
                                             
                     
  
                                                   
                                      
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

abstract final class ClipboardImageService {
                         
  static bool get isSupported => Platform.isWindows;

                                 
  static Future<bool> copyPng(Uint8List pngBytes) async {
    if (!isSupported) return false;
    final dib = await _pngToDib(pngBytes);
    if (dib == null) return false;
    return await _win32SetDib(dib);
  }

                                                               
     
                                                         
                                   
  static Future<Uint8List?> pngToDib(Uint8List pngBytes) => _pngToDib(pngBytes);

  static Future<Uint8List?> _pngToDib(Uint8List pngBytes) async {
    ui.Image? image;
    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      final width = image.width;
      final height = image.height;
                                              
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) return null;
      final pixels = raw.buffer.asUint8List(
        raw.offsetInBytes,
        raw.lengthInBytes,
      );

      const headerSize = 40;
      final dib = Uint8List(headerSize + width * height * 4);
      final bd = ByteData.view(dib.buffer);
      bd.setUint32(0, headerSize, Endian.little);          
      bd.setInt32(4, width, Endian.little);           
      bd.setInt32(8, height, Endian.little);                       
      bd.setUint16(12, 1, Endian.little);            
      bd.setUint16(14, 32, Endian.little);              
      bd.setUint32(16, 0, Endian.little);                          
      bd.setUint32(20, width * height * 4, Endian.little);               

                                       
                                 
                                        
                                          
      final src32 = pixels.buffer.asUint32List(
        pixels.offsetInBytes,
        width * height,
      );
      final dst32 = dib.buffer.asUint32List(headerSize, width * height);
      for (var y = 0; y < height; y++) {
        final srcRow = (height - 1 - y) * width;
        final dstRow = y * width;
        for (var x = 0; x < width; x++) {
          final s = src32[srcRow + x];
          dst32[dstRow + x] =
              0xFF000000 |                      
              ((s & 0x000000FF) << 16) |            
              (s & 0x0000FF00) |           
              ((s >> 16) & 0x000000FF);           
        }
      }
      return dib;
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
    }
  }

                
  static DynamicLibrary? _user32;
  static DynamicLibrary? _kernel32;

  static const int _cfDib = 8;
  static const int _gmemMoveable = 0x0002;

  static Future<bool> _win32SetDib(Uint8List dib) async {
    try {
      final u32 = _user32 ??= DynamicLibrary.open('user32.dll');
      final k32 = _kernel32 ??= DynamicLibrary.open('kernel32.dll');

      final globalAlloc = k32
          .lookupFunction<
            Pointer<Void> Function(Uint32, Size),
            Pointer<Void> Function(int, int)
          >('GlobalAlloc');
      final globalLock = k32
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>),
            Pointer<Void> Function(Pointer<Void>)
          >('GlobalLock');
      final globalUnlock = k32
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('GlobalUnlock');
      final openClipboard = u32
          .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
            'OpenClipboard',
          );
      final emptyClipboard = u32
          .lookupFunction<Int32 Function(), int Function()>('EmptyClipboard');
      final setClipboardData = u32
          .lookupFunction<
            Pointer<Void> Function(Uint32, Pointer<Void>),
            Pointer<Void> Function(int, Pointer<Void>)
          >('SetClipboardData');
      final closeClipboard = u32
          .lookupFunction<Int32 Function(), int Function()>('CloseClipboard');

      final hMem = globalAlloc(_gmemMoveable, dib.length);
      if (hMem.address == 0) return false;
      final dst = globalLock(hMem);
      if (dst.address == 0) return false;
      dst.cast<Uint8>().asTypedList(dib.length).setAll(0, dib);
      globalUnlock(hMem);

                                  
      var opened = false;
      for (var i = 0; i < 10 && !opened; i++) {
        opened = openClipboard(0) != 0;
                                       
        if (!opened) await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      if (!opened) return false;
      emptyClipboard();
                             
      final ok = setClipboardData(_cfDib, hMem).address != 0;
      closeClipboard();
      return ok;
    } catch (_) {
      return false;
    }
  }
}
