                               
                                                                       
                                                 
                                                
import 'package:flutter/foundation.dart';

                                 
enum HwDecType {
  no('no', '启用软解', <TargetPlatform>{}),
  auto('auto', '启用任意可用解码器', <TargetPlatform>{}),
  autoSafe('auto-safe', '启用最佳解码器', <TargetPlatform>{}),
  autoCopy('auto-copy', '启用带拷贝功能的最佳解码器', <TargetPlatform>{}),
  d3d12va('d3d12va', 'DirectX 12 (Windows10 及以上)', {TargetPlatform.windows}),
  d3d12vaCopy(
    'd3d12va-copy',
    'DirectX 12 (Windows10 及以上) (非直通)',
    {TargetPlatform.windows},
  ),
  d3d11va('d3d11va', 'DirectX 11 (Windows8 及以上)', {TargetPlatform.windows}),
  d3d11vaCopy(
    'd3d11va-copy',
    'DirectX 11 (Windows8 及以上) (非直通)',
    {TargetPlatform.windows},
  ),
  dxva2('dxva2', 'DXVA2 (Windows7 及以上)', {TargetPlatform.windows}),
  dxva2Copy(
    'dxva2-copy',
    'DXVA2 (Windows7 及以上) (非直通)',
    {TargetPlatform.windows},
  ),
  videotoolbox(
    'videotoolbox',
    'VideoToolbox (macOS / iOS)',
    {TargetPlatform.iOS, TargetPlatform.macOS},
  ),
  videotoolboxCopy(
    'videotoolbox-copy',
    'VideoToolbox (macOS / iOS) (非直通)',
    {TargetPlatform.iOS, TargetPlatform.macOS},
  ),
  vaapi('vaapi', 'VAAPI (Linux)', {TargetPlatform.linux}),
  vaapiCopy('vaapi-copy', 'VAAPI (Linux) (非直通)', {TargetPlatform.linux}),
  nvdec('nvdec', 'NVDEC (NVIDIA独占)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }),
  nvdecCopy('nvdec-copy', 'NVDEC (NVIDIA独占) (非直通)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }),
  drm('drm', 'DRM (Linux)', {TargetPlatform.linux}),
  drmCopy('drm-copy', 'DRM (Linux) (非直通)', {TargetPlatform.linux}),
  vulkan('vulkan', 'Vulkan (全平台) (实验性)', <TargetPlatform>{}),
  vulkanCopy('vulkan-copy', 'Vulkan (全平台) (实验性) (非直通)', <TargetPlatform>{}),
  vdpau('vdpau', 'VDPAU (Linux)', {TargetPlatform.linux}),
  vdpauCopy('vdpau-copy', 'VDPAU (Linux) (非直通)', {TargetPlatform.linux}),
  mediacodec('mediacodec', 'MediaCodec (Android)', {TargetPlatform.android}),
  mediacodecCopy(
    'mediacodec-copy',
    'MediaCodec (Android) (非直通)',
    {TargetPlatform.android},
  ),
  cuda('cuda', 'CUDA (NVIDIA独占) (过时)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }),
  cudaCopy('cuda-copy', 'CUDA (NVIDIA独占) (过时) (非直通)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }),
  crystalhd('crystalhd', 'CrystalHD (全平台) (过时)', <TargetPlatform>{}),
  rkmpp('rkmpp', 'Rockchip MPP (仅部分Rockchip芯片)', {
    TargetPlatform.linux,
    TargetPlatform.android,
  }),
  amf('amf', 'AMF (AMD独占)', {TargetPlatform.windows, TargetPlatform.linux}),
  amfCopy('amf-copy', 'AMF (AMD独占) (非直通)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
  }),
  qsv('qsv', 'Quick Sync Video (Intel独占)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
  }),
  qsvCopy('qsv-copy', 'Quick Sync Video (Intel独占) (非直通)', {
    TargetPlatform.windows,
    TargetPlatform.linux,
  });

                                      
  final String hwdec;

                      
  final String desc;

                    
  final Set<TargetPlatform> platforms;

  const HwDecType(this.hwdec, this.desc, this.platforms);

                  
  bool get supportedOnCurrentPlatform {
    if (platforms.isEmpty) return true;
    return platforms.contains(defaultTargetPlatform);
  }

                                                           
  static String get defaultForCurrentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [HwDecType.mediacodec.hwdec, HwDecType.autoSafe.hwdec].join(',');
    }
    return HwDecType.auto.hwdec;
  }

                                 
  static HwDecType? byValue(String value) {
    final v = value.trim();
    for (final e in values) {
      if (e.hwdec == v) return e;
    }
    return null;
  }

                                     
  static List<HwDecType> availableOnCurrentPlatform() {
    return values.where((e) => e.supportedOnCurrentPlatform).toList();
  }

                             
  static List<HwDecType> parse(String commaList) {
    final result = <HwDecType>[];
    for (final part in commaList.split(',')) {
      final v = part.trim();
      if (v.isEmpty) continue;
      final e = byValue(v);
      if (e != null) result.add(e);
    }
    return result;
  }
}
