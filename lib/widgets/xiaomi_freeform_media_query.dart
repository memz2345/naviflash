                                               
import 'package:flutter/material.dart';

                                                  
                                          
                                                       
                                            
   
                                                                        
   
                                             
                                          
MediaQueryData sanitizeXiaomiFreeformPadding(MediaQueryData data) {
  final height = data.size.height;
  if (height <= 0) return data;

                                                   
  final maxInset = height * 0.5;

  double top = data.padding.top;
  double bottom = data.padding.bottom;
  double viewTop = data.viewPadding.top;
  double viewBottom = data.viewPadding.bottom;

  if (top > maxInset) top = 0.0;
  if (bottom > maxInset) bottom = 0.0;
  if (viewTop > maxInset) viewTop = 0.0;
  if (viewBottom > maxInset) viewBottom = 0.0;

                   
  if (top == data.padding.top &&
      bottom == data.padding.bottom &&
      viewTop == data.viewPadding.top &&
      viewBottom == data.viewPadding.bottom) {
    return data;
  }

  return data.copyWith(
    padding: data.padding.copyWith(top: top, bottom: bottom),
    viewPadding: data.viewPadding.copyWith(top: viewTop, bottom: viewBottom),
  );
}

                                                      
                                                             
class XiaomiFreeformMediaQuery extends StatelessWidget {
  final Widget child;
  const XiaomiFreeformMediaQuery({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: sanitizeXiaomiFreeformPadding(MediaQuery.of(context)),
      child: child,
    );
  }
}
