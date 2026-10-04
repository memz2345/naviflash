                                         
  
                                                     
  
                                                      
                                           
                                                  
                                                            
                                                                           
                                             
                                                
           
  
                                                             
                                                  
  
           
                                            
                                                                                  
                                                           
                                                  
                                                            
                                                     
                    
                                     
                                                                 
                                                   
                                                
                                                     

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

import 'package:naviflash/widgets/predictive_back_detector.dart';

                                                
   
                                                        
                                   
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
  bool enablePredictiveBack = true,
}) {
                                 
  final bool linearize =
      sheetAnimationStyle?.curve == null &&
      sheetAnimationStyle?.reverseCurve == null;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
    builder: (BuildContext sheetContext) => PredictiveBackSheet(
      enabled: enablePredictiveBack,
      linearize: linearize,
      child: builder(sheetContext),
    ),
  );
}

                                     
                              
class PredictiveBackSheet extends StatefulWidget {
  const PredictiveBackSheet({
    super.key,
    required this.child,
    this.enabled = true,
    this.linearize = true,
  });

  final Widget child;

                                         
  final bool enabled;

                                     
  final bool linearize;

  @override
  State<PredictiveBackSheet> createState() => _PredictiveBackSheetState();
}

class _PredictiveBackSheetState extends State<PredictiveBackSheet>
    with WidgetsBindingObserver {
  ModalRoute<dynamic>? _route;

                                                      
  bool _owned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

               
     
                                                    
                                                
                                                   
                                       
     
                                                           
                                       
                         
  bool get _canTake =>
      widget.enabled &&
      !_imeOpen &&
      !_nestedNavigatorCanPop &&
      (_route?.popGestureEnabled ?? false);

                                 
     
                                              
                            
  bool get _nestedNavigatorCanPop {
    final NavigatorState? nested = Navigator.maybeOf(context);
    final NavigatorState? root = Navigator.maybeOf(context, rootNavigator: true);
    if (nested == null || root == null || identical(nested, root)) return false;
    return nested.canPop();
  }

                                  
  bool get _imeOpen => MediaQuery.viewInsetsOf(context).bottom > 0;

                                        
  double _valueFor(double systemProgress) {
    final double visible = (1 - systemProgress).clamp(0.0, 1.0);
    return widget.linearize ? _controllerValueForVisible(visible) : visible;
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final ModalRoute<dynamic>? route = _route;
    if (!_canTake || route == null) return false;
                                 
    if (backEvent.isButtonEvent) return false;
    _owned = true;
    route.handleStartBackGesture(progress: _valueFor(backEvent.progress));
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_owned) return;
    if (!(_route?.isCurrent ?? false)) return;
    _route!.handleUpdateBackGestureProgress(
      progress: _valueFor(backEvent.progress),
    );
  }

  @override
  void handleCommitBackGesture() {
    if (!_owned) return;
    _owned = false;
    final ModalRoute<dynamic>? route = _route;
    if (route == null) return;

                                         
    final AnimationController? controller =
        PredictiveBackGestureDetector.controllerOf(route);
    final double resumeFrom = controller?.value ?? 0.0;

    route.handleCommitBackGesture();

    if (controller != null &&
        controller.isAnimating &&
        resumeFrom > 0 &&
        resumeFrom < 1) {
      controller.reverse(from: resumeFrom);
    }
  }

  @override
  void handleCancelBackGesture() {
    if (!_owned) return;
    _owned = false;
                              
    _route?.handleCancelBackGesture();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

             

                                          
                                                         
   
                                                      
                              
const Cubic _kSheetCurve = Cubic(0.0, 0.0, 0.2, 1.0);

final bool _linearizeEnabled = _curveMatchesFramework();

bool _curveMatchesFramework() {
  for (final double x in <double>[0.1, 0.25, 0.5, 0.75, 0.9]) {
    if ((Easing.legacyDecelerate.transform(x) - _kSheetCurve.transform(x))
            .abs() >
        1e-9) {
      return false;
    }
  }
  return true;
}

                                            
   
                                                      
                                            
double _controllerValueForVisible(double visible) {
  if (!_linearizeEnabled) return visible;
  if (visible <= 0) return 0;
  if (visible >= 1) return 1;
  double lo = 0;
  double hi = 1;
  for (int i = 0; i < 24; i++) {
    final double mid = (lo + hi) / 2;
    if (_kSheetCurve.transform(mid) < visible) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

                                      
@visibleForTesting
bool get debugSheetLinearizeEnabled => _linearizeEnabled;

                     
@visibleForTesting
double debugControllerValueForVisible(double visible) =>
    _controllerValueForVisible(visible);
