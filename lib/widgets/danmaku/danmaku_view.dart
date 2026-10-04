         
  
                                                       
                                        
                                    
                                       
                                        
  
                                                
                                          
                                     
              
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_danmaku/canvas_danmaku.dart' as canvas;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'danmaku_bas_renderer.dart';
import 'danmaku_controller.dart';

class DanmakuView extends StatefulWidget {
  final DanmakuController controller;

  const DanmakuView({super.key, required this.controller});

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
                                                   
                                       
  late final VoidCallback _repaintHandler = _handleRepaint;

                                 
  canvas.DanmakuController<Object?>? _attachedNative;

                                   
  ui.Image? _lastMask;

                                       
                                         
  bool _lastSmartMask = false;
  bool _lastShowAdvanced = true;

                                     
  bool _basActive = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(DanmakuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
                              
      oldWidget.controller.onNeedRepaint = null;
      oldWidget.controller.detachNative();
      _attachedNative = null;
      _bind();
    }
  }

  void _bind() {
    widget.controller.onNeedRepaint = _repaintHandler;
  }

  void _handleCreatedController(canvas.DanmakuController<Object?> native) {
    _attachedNative = native;
    widget.controller.attachNative(native);
  }

  @override
  void dispose() {
    final controller = widget.controller;
    if (identical(controller.onNeedRepaint, _repaintHandler)) {
      controller.onNeedRepaint = null;
    }
    controller.detachNative(_attachedNative);
    _attachedNative = null;
    super.dispose();
  }

                             
  void _syncViewState() {
    final c = widget.controller;
    _lastMask = c.smartMask ? c.personMask : null;
    _lastSmartMask = c.smartMask;
    _lastShowAdvanced = c.showAdvanced;
    _basActive = c.showAdvanced && c.activeBasDanmakus.isNotEmpty;
  }

                                            
                                 
  void _handleRepaint() {
    if (!mounted) return;
    final c = widget.controller;
    final mask = c.smartMask ? c.personMask : null;
    final basActive = c.showAdvanced && c.activeBasDanmakus.isNotEmpty;
    final needsRebuild = !identical(mask, _lastMask) ||
        c.smartMask != _lastSmartMask ||
        c.showAdvanced != _lastShowAdvanced ||
        basActive != _basActive;
    if (needsRebuild) {
      setState(_syncViewState);
      return;
    }
    if (basActive) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.setSize(constraints.maxWidth, constraints.maxHeight);
        _syncViewState();

        return ClipRect(
          child: _DanmakuMaskLayer(
            enabled: controller.smartMask,
            mask: _lastMask,
            child: Stack(
              fit: StackFit.expand,
              children: [
                canvas.DanmakuScreen<Object?>(
                  createdController: _handleCreatedController,
                  option: controller.option,
                ),
                                                         
                                                         
                                                             
                                            
                if (controller.showAdvanced)
                  CustomPaint(
                    painter: _BasOverlayPainter(controller),
                    size: Size.infinite,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

                
class _BasOverlayPainter extends CustomPainter {
  final DanmakuController controller;

  _BasOverlayPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final list = controller.activeBasDanmakus;
    if (list.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    DanmakuBasRenderer.paint(
      canvas,
      size,
      list,
      controller.currentTime,
      controller.opacity,
      controller.activeFontSizeScale,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BasOverlayPainter oldDelegate) => true;
}

                             
   
                                                        
                               
   
                                                     
                                          
                                 
class _DanmakuMaskLayer extends SingleChildRenderObjectWidget {
  const _DanmakuMaskLayer({
    required this.enabled,
    required this.mask,
    super.child,
  });

                                
  final bool enabled;

                              
  final ui.Image? mask;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDanmakuMaskLayer(enabled: enabled, mask: mask);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDanmakuMaskLayer renderObject,
  ) {
    renderObject
      ..enabled = enabled
      ..mask = mask;
  }
}

class _RenderDanmakuMaskLayer extends RenderProxyBox {
  _RenderDanmakuMaskLayer({required bool enabled, ui.Image? mask})
      : _enabled = enabled,
        _mask = mask;

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsPaint();
  }

  ui.Image? _mask;
  ui.Image? get mask => _mask;
  set mask(ui.Image? value) {
    if (identical(_mask, value)) return;
    _mask = value;
    markNeedsPaint();
  }

  ui.Image? _shaderImage;
  Size? _shaderSize;
  ui.ImageShader? _shader;

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  ui.ImageShader _shaderFor(ui.Image image, Size size) {
    if (_shader != null &&
        identical(_shaderImage, image) &&
        _shaderSize == size) {
      return _shader!;
    }
    final sx = image.width == 0 ? 1.0 : size.width / image.width;
    final sy = image.height == 0 ? 1.0 : size.height / image.height;
                                       
    final matrix = Float64List.fromList(<double>[
      sx, 0, 0, 0,   
      0, sy, 0, 0,   
      0, 0, 1, 0,   
      0, 0, 0, 1,
    ]);
    _shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      matrix,
      filterQuality: FilterQuality.medium,
    );
    _shaderImage = image;
    _shaderSize = size;
    return _shader!;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final image = _mask;
    if (!_enabled || image == null || size.isEmpty) {
                                        
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = _shaderFor(image, size)
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstOut;
    context.pushLayer(layer!, super.paint, offset);
    assert(() {
      layer!.debugCreator = debugCreator;
      return true;
    }());
  }
}
