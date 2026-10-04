                                      
  
                                                   
                                         
  
                                                    
                                      
// ignore_for_file: depend_on_referenced_packages
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' show calloc, malloc;

                        
class TtsExportUnsupportedException implements Exception {
  @override
  String toString() => 'MP3/SILK 导出目前仅支持 Android';
}

                           
class TtsNativeEncodeException implements Exception {
  final String message;
  TtsNativeEncodeException(this.message);

  @override
  String toString() => message;
}

                 

typedef _EncodeSilkC = Pointer<Uint8> Function(
  Pointer<Int16> pcm,
  Int32 nSamples,
  Int32 sampleRate,
  Int32 tencent,
  Int32 bitrateBps,
  Pointer<Int32> outSize,
  Pointer<Int8> err,
  Int32 errLen,
);
typedef _EncodeSilkDart = Pointer<Uint8> Function(
  Pointer<Int16> pcm,
  int nSamples,
  int sampleRate,
  int tencent,
  int bitrateBps,
  Pointer<Int32> outSize,
  Pointer<Int8> err,
  int errLen,
);

typedef _EncodeMp3C = Pointer<Uint8> Function(
  Pointer<Int16> pcm,
  Int32 nSamples,
  Int32 sampleRate,
  Pointer<Int32> outSize,
  Pointer<Int8> err,
  Int32 errLen,
);
typedef _EncodeMp3Dart = Pointer<Uint8> Function(
  Pointer<Int16> pcm,
  int nSamples,
  int sampleRate,
  Pointer<Int32> outSize,
  Pointer<Int8> err,
  int errLen,
);

typedef _FreeC = Void Function(Pointer<Void> p);
typedef _FreeDart = void Function(Pointer<Void> p);

class TtsExportNative {
  TtsExportNative._() {
    if (!Platform.isAndroid) return;
    final lib = DynamicLibrary.open('libttsexport.so');
    _encodeSilk = lib.lookupFunction<_EncodeSilkC, _EncodeSilkDart>(
      'tts_silk_encode',
    );
    _encodeMp3 = lib.lookupFunction<_EncodeMp3C, _EncodeMp3Dart>(
      'tts_mp3_encode',
    );
    _free = lib.lookupFunction<_FreeC, _FreeDart>('tts_free');
  }

  static final TtsExportNative instance = TtsExportNative._();

  bool get isSupported => Platform.isAndroid;

  late final _EncodeSilkDart _encodeSilk;
  late final _EncodeMp3Dart _encodeMp3;
  late final _FreeDart _free;

  static const int _errCap = 256;

                                       
  String _drainError(Pointer<Int8> err) {
    final bytes = err.cast<Uint8>();
    final raw = <int>[];
    for (var i = 0; i < _errCap; i++) {
      final b = bytes[i];
      if (b == 0) break;
      raw.add(b);
    }
    return raw.isEmpty ? 'native encoder failed' : String.fromCharCodes(raw);
  }

                              
     
                                                      
  Uint8List encodeSilk(
    Int16List pcm,
    int sampleRate, {
    required bool tencent,
    int bitrateBps = 25000,
  }) {
    if (!isSupported) throw TtsExportUnsupportedException();

    final pcmPtr = malloc<Int16>(pcm.length);
    final sizePtr = malloc<Int32>(1);
    final errPtr = calloc<Int8>(_errCap);              
    Pointer<Uint8> outPtr = nullptr;
    try {
      pcmPtr.asTypedList(pcm.length).setAll(0, pcm);
      outPtr = _encodeSilk(
        pcmPtr,
        pcm.length,
        sampleRate,
        tencent ? 1 : 0,
        bitrateBps,
        sizePtr,
        errPtr,
        _errCap,
      );
      if (outPtr == nullptr) {
        throw TtsNativeEncodeException(_drainError(errPtr));
      }
      final size = sizePtr.value;
      if (size <= 0) throw TtsNativeEncodeException('empty silk payload');
      return Uint8List.fromList(outPtr.asTypedList(size));
    } finally {
      if (outPtr != nullptr) _free(outPtr.cast<Void>());
      malloc.free(pcmPtr);
      malloc.free(sizePtr);
      calloc.free(errPtr);
    }
  }

                                                
  Uint8List encodeMp3(Int16List pcm, int sampleRate) {
    if (!isSupported) throw TtsExportUnsupportedException();

    final pcmPtr = malloc<Int16>(pcm.length);
    final sizePtr = malloc<Int32>(1);
    final errPtr = calloc<Int8>(_errCap);
    Pointer<Uint8> outPtr = nullptr;
    try {
      pcmPtr.asTypedList(pcm.length).setAll(0, pcm);
      outPtr = _encodeMp3(
        pcmPtr,
        pcm.length,
        sampleRate,
        sizePtr,
        errPtr,
        _errCap,
      );
      if (outPtr == nullptr) {
        throw TtsNativeEncodeException(_drainError(errPtr));
      }
      final size = sizePtr.value;
      if (size <= 0) throw TtsNativeEncodeException('empty mp3 payload');
      return Uint8List.fromList(outPtr.asTypedList(size));
    } finally {
      if (outPtr != nullptr) _free(outPtr.cast<Void>());
      malloc.free(pcmPtr);
      malloc.free(sizePtr);
      calloc.free(errPtr);
    }
  }
}
