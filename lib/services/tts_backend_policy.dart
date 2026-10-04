                                       
  
                             
  
                               
                                            
                       
                                                      
                                                
  
               
                                                                   
                                                             
                                                                
                                                   
                                       
                                           
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:llamadart/llamadart.dart' as llama;

                    
enum TtsInferenceDevicePreference {
                                                
  auto,

                                                 
  npu,

                                                         
  gpu,

                  
  cpu,
}

                                                  
enum TtsSocVendor { qualcomm, mediatek, other }

                         
class TtsHardwareInfo {
  final TtsSocVendor vendor;

                                                   
  final String hardware;

                                                     
  final String board;

  const TtsHardwareInfo({
    required this.vendor,
    this.hardware = '',
    this.board = '',
  });

                                              
  bool get isQualcommAndroid => vendor == TtsSocVendor.qualcomm;

  static const TtsHardwareInfo unknown =
      TtsHardwareInfo(vendor: TtsSocVendor.other);
}

                               
enum TtsNpuFallbackReason {
                                     
  hardwareUnsupported,

                                       
  runtimeNotBundled,

                                                       
                                                  
  deviceLoadFailed,
}

               
class ResolvedTtsDevice {
                
  final TtsInferenceDevicePreference preference;

                                               
  final TtsInferenceDevicePreference effective;

                                      
  final llama.GpuBackend gpuBackend;

                                   
  final int gpuLayers;

             
  final TtsHardwareInfo hardware;

                                                  
  TtsNpuFallbackReason? overrideFallbackReason;

  ResolvedTtsDevice({
    required this.preference,
    required this.effective,
    required this.gpuBackend,
    required this.gpuLayers,
    required this.hardware,
    this.overrideFallbackReason,
  });

                                        
  ResolvedTtsDevice._fallback({
    required TtsInferenceDevicePreference preference,
    required TtsHardwareInfo hardware,
    required TtsNpuFallbackReason reason,
  }) : this(
         preference: preference,
         effective: TtsInferenceDevicePreference.cpu,
         gpuBackend: llama.GpuBackend.cpu,
         gpuLayers: 0,
         hardware: hardware,
         overrideFallbackReason: reason,
       );

                                    
  bool get npuRequested =>
      preference == TtsInferenceDevicePreference.npu ||
      (preference == TtsInferenceDevicePreference.auto &&
          hardware.isQualcommAndroid);

                             
  bool get fellBackFromNpu =>
      npuRequested && effective != TtsInferenceDevicePreference.npu;

                        
  TtsNpuFallbackReason? get fallbackReason {
    if (!fellBackFromNpu) return null;
    final override = overrideFallbackReason;
    if (override != null) return override;
    return hardware.isQualcommAndroid
        ? TtsNpuFallbackReason.runtimeNotBundled
        : TtsNpuFallbackReason.hardwareUnsupported;
  }

                                         
  static ResolvedTtsDevice cpuFallbackFrom(
    ResolvedTtsDevice npu, {
    TtsNpuFallbackReason reason = TtsNpuFallbackReason.deviceLoadFailed,
  }) {
    return ResolvedTtsDevice._fallback(
      preference: npu.preference,
      hardware: npu.hardware,
      reason: reason,
    );
  }
}

                       
class TtsBackendPolicy {
  TtsBackendPolicy._();

                                    
     
                                                                
                                                                    
                                          
                                                   
  static const bool bundledNpuRuntime = true;

  static TtsHardwareInfo? _cachedHardware;
  static Future<TtsHardwareInfo>? _pendingProbe;

                                   
  static Future<TtsHardwareInfo> hardware() {
    final cached = _cachedHardware;
    if (cached != null) return Future.value(cached);
    final pending = _pendingProbe;
    if (pending != null) return pending;

    final future = _probeHardware();
    _pendingProbe = future;
    return future.then((info) {
      _cachedHardware = info;
      _pendingProbe = null;
      return info;
    });
  }

  static Future<TtsHardwareInfo> _probeHardware() async {
    if (!Platform.isAndroid) return TtsHardwareInfo.unknown;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final hw = info.hardware.toLowerCase();
      final board = info.board.toLowerCase();
      final vendor = _classifyVendor(hw, board);
      return TtsHardwareInfo(
        vendor: vendor,
        hardware: info.hardware,
        board: info.board,
      );
    } catch (_) {
      return TtsHardwareInfo.unknown;
    }
  }

                                                  
     
                                                             
                                                     
                                            
  static TtsSocVendor _classifyVendor(String hardware, String board) {
    bool isMtk(String s) =>
        RegExp(r'^mt\d').hasMatch(s);
    bool isQualcomm(String s) =>
        s.startsWith('qcom') ||
        s.startsWith('msm') ||
        s.startsWith('sdm') ||
        RegExp(r'^(sm|qcs|qcm)\d').hasMatch(s);

    if (isQualcomm(hardware) || isQualcomm(board)) {
      return TtsSocVendor.qualcomm;
    }
    if (isMtk(hardware) || isMtk(board)) {
      return TtsSocVendor.mediatek;
    }
    return TtsSocVendor.other;
  }

                            
  static Future<ResolvedTtsDevice> resolve(
    TtsInferenceDevicePreference preference,
  ) async {
    final hw = await hardware();

    switch (preference) {
      case TtsInferenceDevicePreference.npu:
        if (hw.isQualcommAndroid && bundledNpuRuntime) {
          return _npu(preference, hw);
        }
        return _cpu(preference, hw);
      case TtsInferenceDevicePreference.auto:
                                           
        if (hw.isQualcommAndroid) {
          return bundledNpuRuntime
              ? _npu(preference, hw)
              : _cpu(preference, hw);
        }
                                                       
                                                 
                                     
        return _autoNative(preference, hw);
      case TtsInferenceDevicePreference.gpu:
        return _gpu(preference, hw);
      case TtsInferenceDevicePreference.cpu:
        return _cpu(preference, hw);
    }
  }

  static ResolvedTtsDevice _cpu(
    TtsInferenceDevicePreference preference,
    TtsHardwareInfo hw,
  ) {
    return ResolvedTtsDevice(
      preference: preference,
      effective: TtsInferenceDevicePreference.cpu,
      gpuBackend: llama.GpuBackend.cpu,
      gpuLayers: 0,
      hardware: hw,
    );
  }

                                                      
  static ResolvedTtsDevice _autoNative(
    TtsInferenceDevicePreference preference,
    TtsHardwareInfo hw,
  ) {
    return ResolvedTtsDevice(
      preference: preference,
      effective: TtsInferenceDevicePreference.auto,
      gpuBackend: llama.GpuBackend.auto,
      gpuLayers: llama.ModelParams.maxGpuLayers,
      hardware: hw,
    );
  }

  static ResolvedTtsDevice _gpu(
    TtsInferenceDevicePreference preference,
    TtsHardwareInfo hw,
  ) {
                                                              
                                
    final apple = Platform.isIOS || Platform.isMacOS;
    return ResolvedTtsDevice(
      preference: preference,
      effective: TtsInferenceDevicePreference.gpu,
      gpuBackend:
          apple ? llama.GpuBackend.metal : llama.GpuBackend.vulkan,
      gpuLayers: llama.ModelParams.maxGpuLayers,
      hardware: hw,
    );
  }

  static ResolvedTtsDevice _npu(
    TtsInferenceDevicePreference preference,
    TtsHardwareInfo hw,
  ) {
                                                       
                                            
                                                           
                                                   
                                      
    return ResolvedTtsDevice(
      preference: preference,
      effective: TtsInferenceDevicePreference.npu,
      gpuBackend: llama.GpuBackend.hexagon,
      gpuLayers: llama.ModelParams.maxGpuLayers,
      hardware: hw,
    );
  }
}
