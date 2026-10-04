                                        
  
                                   
  
                                                            
      
                                             
                                                
  
                                                        
                                         
                                          
  
                       
                                        
                                               
  
        
                                                                                 
                                                                  
                          
                                                                 
  
                                                        
                                   
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

                                       
class NativeMenuItem {
  final String text;

                                    
  final String? subtitle;

                                              
  final IconData? icon;

                                                       
  final bool checked;

                 
  final bool destructive;

  final bool enabled;

                                                
  final bool closeAfter;

  final VoidCallback onTap;

  const NativeMenuItem({
    required this.text,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.checked = false,
    this.destructive = false,
    this.enabled = true,
    this.closeAfter = true,
  });
}

class _PendingMenu {
  List<NativeMenuItem> items;
  final Completer<void> completer;

                                               
                             
  final List<NativeMenuItem> Function()? refreshProvider;

  _PendingMenu(this.items, this.completer, {this.refreshProvider});
}

class NativeMenuService {
  NativeMenuService._();

  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/native_menu',
  );

                                        
  static bool enabled = true;

  static int _seq = 0;
  static final Map<int, _PendingMenu> _pending = <int, _PendingMenu>{};
  static bool _handlerInstalled = false;

  static void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler(_handleCall);
  }

                                      
     
                                             
                                                   
             
  static Future<bool> showMenu(
    BuildContext context, {
    required List<NativeMenuItem> items,
    required Offset position,
    double width = 220,
  }) {
    return _show(
      context,
      style: 'dropdown',
      items: items,
      position: position,
      width: width,
    );
  }

                                             
     
                                                         
                                                 
  static Future<bool> showMoreSheet(
    BuildContext context, {
    required String title,
    required List<NativeMenuItem> items,
    List<NativeMenuItem> Function()? refreshProvider,
  }) {
    return _show(
      context,
      style: 'bottomSheet',
      title: title,
      items: items,
      refreshProvider: refreshProvider,
    );
  }

  static Future<bool> _show(
    BuildContext context, {
    required String style,
    required List<NativeMenuItem> items,
    String title = '',
    Offset? position,
    double width = 220,
    List<NativeMenuItem> Function()? refreshProvider,
  }) async {
    if (!enabled || !Platform.isAndroid || items.isEmpty) return false;
    _ensureHandler();
    final id = ++_seq;
    final completer = Completer<void>();
    _pending[id] = _PendingMenu(
      List.of(items),
      completer,
      refreshProvider: refreshProvider,
    );
    try {
      final ok = await _channel.invokeMethod<bool>('showMenu', {
        'menuId': id,
        'style': style,
        'title': title,
        'items': _serialize(items),
                                                            
        'x': position?.dx ?? 0.0,
        'y': position?.dy ?? 0.0,
        'width': width,
        'dark': Theme.of(context).brightness == Brightness.dark,
      });
      if (ok != true) {
        _pending.remove(id);
        return false;
      }
      await completer.future;
      return true;
    } catch (_) {
      _pending.remove(id);
      return false;
    }
  }

                           
  static Future<void> hideMenu() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('hideMenu');
    } catch (_) {}
  }

  static List<Map<String, Object?>> _serialize(List<NativeMenuItem> items) => [
    for (final item in items)
      {
        'text': item.text,
        'subtitle': item.subtitle,
        'iconCodePoint': item.icon?.codePoint,
        'iconFontFamily': item.icon?.fontFamily,
        'checked': item.checked,
        'destructive': item.destructive,
        'enabled': item.enabled,
        'closeAfter': item.closeAfter,
      },
  ];

  static Future<dynamic> _handleCall(MethodCall call) async {
    final args = call.arguments;
    if (args is! Map) return null;
    final id = (args['menuId'] as num?)?.toInt();
    final menu = id == null ? null : _pending[id];
    if (menu == null) return null;

    if (call.method == 'onSelect') {
      final index = (args['index'] as num?)?.toInt() ?? -1;
      final item = index >= 0 && index < menu.items.length
          ? menu.items[index]
          : null;
      if (item == null) {
        _pending.remove(id);
        if (!menu.completer.isCompleted) menu.completer.complete();
        return null;
      }
      if (item.closeAfter) {
        _pending.remove(id);
        if (!menu.completer.isCompleted) menu.completer.complete();
        item.onTap();
        return null;
      }
                                             
                                             
      item.onTap();
      final provider = menu.refreshProvider;
      if (provider != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (menu.completer.isCompleted || _pending[id] == null) return;
          try {
            final fresh = provider();
            if (fresh.isEmpty) {
                               
              _pending.remove(id);
              if (!menu.completer.isCompleted) menu.completer.complete();
              unawaited(hideMenu());
              return;
            }
            menu.items = List.of(fresh);
            unawaited(
              _channel.invokeMethod<void>('updateItems', {
                'menuId': id,
                'items': _serialize(fresh),
              }),
            );
          } catch (_) {
                                        
          }
        });
      }
      return null;
    }

                
    _pending.remove(id);
    if (!menu.completer.isCompleted) menu.completer.complete();
    return null;
  }
}
