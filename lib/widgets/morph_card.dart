                              
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../services/native_menu_service.dart';
import '../services/settings_search_controller.dart';

                     
const double kGroupRadius = 16.0;

                    
const double kItemRadius = 8.0;

                                             
const double kItemPressedRadius = 12.0;

                   
const double kListEdgeRadius = 2.0;

                           
const double kIconBtnRadius = 14.0;

                     
const double kCardGap = 2.0;

              
const Duration kMorphDuration = Duration(milliseconds: 70);

              
const Curve kMorphCurve = Curves.fastOutSlowIn;

                                         
   
                                              
                                           
                                                  
   
           
              
                    
                    
                           
                             
                           
     
       
class MorphItem extends StatefulWidget {
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final bool interactive;
  final Widget child;

                                    
  final String? flashKey;

                                        
                                   
  final Object? flashToken;

  const MorphItem({
    super.key,
    required this.selected,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.interactive = true,
    this.flashKey,
    this.flashToken,
  });

  @override
  State<MorphItem> createState() => _MorphItemState();
}

class _MorphItemState extends State<MorphItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  AnimationController? _flashCtrl;
  int? _handledFlashToken;

  @override
  void initState() {
    super.initState();
    if (widget.flashKey != null) {
      _flashCtrl = _createFlashCtrl();
      SettingsSearchController.current.addListener(_onSearchTargetChanged);
      _onSearchTargetChanged();
    } else if (widget.flashToken != null) {
      _flashCtrl = _createFlashCtrl();
                                          
      _triggerFlash();
    }
  }

  @override
  void didUpdateWidget(MorphItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashToken != null &&
        widget.flashToken != oldWidget.flashToken) {
      _flashCtrl ??= _createFlashCtrl();
      _triggerFlash();
    }
  }

  AnimationController _createFlashCtrl() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_onFlashTick);
  }

                        
  void _onFlashTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.flashKey != null) {
      SettingsSearchController.current.removeListener(_onSearchTargetChanged);
    }
    _flashCtrl?.dispose();
    super.dispose();
  }

                         
  void _triggerFlash() {
    final ctrl = _flashCtrl;
    if (ctrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
      ctrl.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1560), () {
        if (mounted) {
          ctrl.stop();
          ctrl.reset();
        }
      });
    });
  }

                      
  void _onSearchTargetChanged() {
    final target = SettingsSearchController.current.value;
    if (target == null || target.optionKey != widget.flashKey) return;
    if (target.token == _handledFlashToken) return;
    _handledFlashToken = target.token;
    _triggerFlash();
  }

  BorderRadius _defaultRadius() {
    const big = kItemPressedRadius;
    const edge = kListEdgeRadius;

    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(big);
    }
    if (widget.isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(big),
        topRight: Radius.circular(big),
        bottomLeft: Radius.circular(edge),
        bottomRight: Radius.circular(edge),
      );
    }
    if (widget.isLast) {
      return const BorderRadius.only(
        topLeft: Radius.circular(edge),
        topRight: Radius.circular(edge),
        bottomLeft: Radius.circular(big),
        bottomRight: Radius.circular(big),
      );
    }
    return BorderRadius.circular(edge);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.selected ? cs.secondaryContainer : cs.surfaceBright;
    final overlay = widget.selected
        ? cs.onSecondaryContainer.withValues(alpha: 0.10)
        : cs.onSurface.withValues(alpha: 0.08);
    var color = _pressed ? Color.alphaBlend(overlay, base) : base;

                                     
    final flash = _flashCtrl?.isAnimating ?? false;
    if (flash) {
      final t = _flashCtrl!.value;
      final pulse = t < 0.5 ? t * 2 : (1 - t) * 2;              
      color = Color.alphaBlend(
        cs.primaryContainer.withValues(alpha: 0.55 * pulse),
        color,
      );
    }

                                       
                                          
    final radius = (_pressed || widget.selected)
        ? BorderRadius.circular(kItemPressedRadius)
        : _defaultRadius();

    final container = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );

    if (!widget.interactive) return container;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: container,
    );
  }
}

                                                
class MorphRowItem {
  final Widget child;
  final bool interactive;

                                    
  final String? flashKey;

  const MorphRowItem({
    required this.child,
    this.interactive = true,
    this.flashKey,
  });
}

                                           
   
           
                                
                                         
                                                             
      
       
List<Widget> buildMorphSegmentedList(List<MorphRowItem> items) {
  return List.generate(items.length, (i) {
    final isFirst = i == 0;
    final isLast = i == items.length - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
      child: MorphItem(
        selected: false,
        isFirst: isFirst,
        isLast: isLast,
        interactive: items[i].interactive,
        flashKey: items[i].flashKey,
        child: items[i].child,
      ),
    );
  });
}

                                               
   
                                                      
                   
                                                
                                        
                                                
                                                                        
                                    
   
                                               
              
   
           
                               
                                
              
                                                                            
                                                                             
        
                        
                                                    
        
     
       
class MorphGlassDropdown<T> extends StatefulWidget {
                           
  final T? value;

                                                             
  final List<DropdownMenuItem<T>>? items;

                        
  final ValueChanged<T?>? onChanged;

                               
  final double menuWidth;

                            
  final double menuMaxHeight;

                                              
  final ColorScheme? menuColorScheme;

  const MorphGlassDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.menuWidth = 220.0,
    this.menuMaxHeight = 320.0,
    this.menuColorScheme,
  });

  @override
  State<MorphGlassDropdown<T>> createState() => _MorphGlassDropdownState<T>();
}

class _MorphGlassDropdownState<T> extends State<MorphGlassDropdown<T>> {
  List<DropdownMenuItem<T>> get _items => widget.items ?? const [];

                                                   
                          
  OverlayEntry? _entry;

                                             
  DropdownMenuItem<T>? get _selected {
    for (final item in _items) {
      if (item.value == widget.value) return item;
    }
    return _items.isEmpty ? null : _items.first;
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  void _closeMenu() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.menuColorScheme ?? Theme.of(context).colorScheme;
    return InkWell(
      onTap: widget.onChanged == null ? null : _openMenu,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                                                      
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
              child: _selected?.child ?? const SizedBox.shrink(),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 24,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

                                                 
  Future<void> _openMenu() async {
    if (await _tryNativeMenu()) return;
    _openFlutterMenu();
  }

                                             
                                                        
                                            
  Future<bool> _tryNativeMenu() async {
    if (_items.isEmpty) return false;
    final items = <NativeMenuItem>[];
    for (final item in _items) {
      final text = _plainTextOf(item.child);
      if (text == null) return false;
      items.add(
        NativeMenuItem(
          text: text,
          checked: item.value == widget.value,
          enabled: item.enabled,
          onTap: () => widget.onChanged?.call(item.value),
        ),
      );
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    return NativeMenuService.showMenu(
      context,
      items: items,
      position: box.localToGlobal(Offset(0, box.size.height)),
      width: widget.menuWidth,
    );
  }

                                                      
  static String? _plainTextOf(Widget? child) {
    if (child is Text) return child.data ?? child.textSpan?.toPlainText();
    if (child is RichText) return child.text.toPlainText();
    return null;
  }

                                          
  void _openFlutterMenu() {
    _closeMenu();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
                                                          
                                                      
                                        
                                           
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final globalAnchor = box.localToGlobal(Offset.zero);
    final anchor = (overlayBox != null && overlayBox.attached)
        ? overlayBox.globalToLocal(globalAnchor)
        : globalAnchor;
    final area = (overlayBox != null && overlayBox.attached)
        ? overlayBox.size
        : MediaQuery.sizeOf(context);
    final cs = widget.menuColorScheme ?? Theme.of(context).colorScheme;
    final width = widget.menuWidth;
                                  
    final estHeight = _items.length * 44.0 + 12.0;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        double left = anchor.dx;
        double top = anchor.dy + box.size.height + 4;
        if (left + width > area.width - 8) {
          left = area.width - width - 8;
        }
        if (left < 8) left = 8;
        if (top + estHeight > area.height - 8) {
          top = anchor.dy - estHeight - 4;              
          if (top < 8) top = 8;
        }
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
                onSecondaryTap: _closeMenu,
                onPanDown: (_) => _closeMenu(),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(left: left, top: top, child: _buildMenu(cs, _closeMenu)),
          ],
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }

  Widget _buildMenu(ColorScheme cs, VoidCallback close) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kGroupRadius),
      child: BackdropFilter(
                                                             
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: widget.menuWidth,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(kGroupRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.menuMaxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _items.length - 1 ? 0 : kCardGap,
                      ),
                      child: MorphItem(
                        selected: _items[i].value == widget.value,
                        isFirst: i == 0,
                        isLast: i == _items.length - 1,
                        interactive: _items[i].enabled,
                        child: _buildItem(cs, _items[i], close),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    ColorScheme cs,
    DropdownMenuItem<T> item,
    VoidCallback close,
  ) {
    final selected = item.value == widget.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () {
                close();
                widget.onChanged?.call(item.value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : null,
              color: item.enabled
                  ? (selected ? cs.onSecondaryContainer : cs.onSurface)
                  : cs.onSurface.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: item.child)],
            ),
          ),
        ),
      ),
    );
  }
}
