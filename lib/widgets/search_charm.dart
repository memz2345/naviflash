import 'package:flutter/material.dart';

class SearchCharm extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const SearchCharm({super.key, required this.isVisible, required this.onClose});

  @override
  State<SearchCharm> createState() => _SearchCharmState();
}

class _SearchCharmState extends State<SearchCharm> with TickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  late AnimationController _contentController;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubic,
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );

    if (widget.isVisible) {
      _panelController.value = 1.0;
      _contentController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SearchCharm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _panelController.forward().then((_) {
          _contentController.forward();
        });
      } else {
        _contentController.reverse().then((_) {
          _panelController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 透明遮罩层
        if (widget.isVisible)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        // 搜索面板主体
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _panelAnimation,
            builder: (context, child) {
              final width = _panelAnimation.value * 340.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: width,
                color: const Color(0xFF1E0052),
                clipBehavior: Clip.hardEdge,
                child: width > 20 ? child : Container(),
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 340.0,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: AnimatedBuilder(
                  animation: _contentAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset((1 - _contentAnimation.value) * 50, 0),
                      child: Opacity(
                        opacity: _contentAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Search",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            "Settings",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  hintText: "",
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF662D91),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(2),
                                  bottomRight: Radius.circular(2),
                                ),
                              ),
                              child:
                                  const Icon(Icons.search, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}