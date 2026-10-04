import 'package:flutter/material.dart';
import 'package:m3e_design/m3e_design.dart';

@immutable
class LoadingTokensAdapter {
  const LoadingTokensAdapter(this.context);
  final BuildContext context;

  M3ETheme get _m3e {
    final t = Theme.of(context);
    return t.extension<M3ETheme>() ?? M3ETheme.defaults(t.colorScheme);
  }

                                             
  Color activeColor() => _m3e.colors.primary;

                                                                
  Color containerColorDefault() => Colors.transparent;

                             
  Color containedContainerColor() => _m3e.colors.primaryContainer;
  Color containedActiveColor() => _m3e.colors.onPrimaryContainer;

                            
  double containerWidth() => 48;                          
  double containerHeight() => 48;
  double activeIndicatorSize() => 38;

                        
  BorderRadius containerRadius() => BorderRadius.circular(999);
}
