                                     
  
                                                             
  
                                               
                                               
                                           
                                            
                                                    
                                           
                                       
  
                                        
                    
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;
import 'package:waterfall_flow/waterfall_flow.dart'
    show SliverWaterfallFlow, SliverWaterfallFlowDelegate;

                             
const double kDynamicCardMinWidth = 400.0;

         
const int kDynamicMaxColumns = 4;

                                       
int dynamicColumnCount(double width) =>
    (width / kDynamicCardMinWidth).ceil().clamp(1, kDynamicMaxColumns);

                                      
class DynamicWaterfallSliver<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;

                               
  final Key Function(T item)? itemKey;

                              
  final EdgeInsets singleColumnPadding;

               
  final EdgeInsets multiColumnPadding;

                 
  final double spacing;

  const DynamicWaterfallSliver({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemKey,
    this.singleColumnPadding = const EdgeInsets.fromLTRB(12, 8, 12, 24),
    this.multiColumnPadding = const EdgeInsets.fromLTRB(12, 8, 12, 0),
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = dynamicColumnCount(constraints.crossAxisExtent);
                         
        if (columns <= 1) {
          return SliverPadding(
            padding: singleColumnPadding,
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: itemBuilder(context, items[index]),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: multiColumnPadding,
          sliver: SliverWaterfallFlow(
            gridDelegate: _NaviWaterfallDelegate(
              maxCrossAxisExtent: kDynamicCardMinWidth,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                final child = itemBuilder(context, item);
                final key = itemKey?.call(item);
                return key == null
                    ? child
                    : KeyedSubtree(key: key, child: child);
              },
                                             
              childCount: items.length,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }
}

                      
   
                                              
                                                 
                                                    
class _NaviWaterfallDelegate extends SliverWaterfallFlowDelegate {
  _NaviWaterfallDelegate({
    required this.maxCrossAxisExtent,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
  });

  final double maxCrossAxisExtent;

  int? _columnCount;
  double? _lastCrossAxisExtent;

  @override
  int getCrossAxisCount(SliverConstraints constraints) {
    final extent = constraints.crossAxisExtent;
    if (_columnCount != null && _lastCrossAxisExtent == extent) {
      return _columnCount!;
    }
    _lastCrossAxisExtent = extent;
    _columnCount = (extent / (maxCrossAxisExtent + crossAxisSpacing))
        .ceil()
        .clamp(1, kDynamicMaxColumns);
    return _columnCount!;
  }

  @override
  bool shouldRelayout(covariant SliverWaterfallFlowDelegate oldDelegate) {
    final changed =
        oldDelegate.runtimeType != runtimeType ||
        (oldDelegate is _NaviWaterfallDelegate &&
            (oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
                super.shouldRelayout(oldDelegate)));
    if (changed) {
      _columnCount = null;
      _lastCrossAxisExtent = null;
    }
    return changed;
  }
}

                                
Widget dynamicWaterfallTail({
  required bool loadingMore,
  required bool hasMore,
  required String noMoreText,
  required Color color,
}) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (hasMore
                  ? const SizedBox(height: 8)
                  : Text(
                      noMoreText,
                      style: TextStyle(fontSize: 12, color: color),
                    )),
      ),
    ),
  );
}
