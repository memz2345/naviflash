                                      
  
                    
                                                            
                          
                                         
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';

class EmotePickerPanel extends StatefulWidget {
                             
  final ValueChanged<String> onPick;

  const EmotePickerPanel({super.key, required this.onPick});

  @override
  State<EmotePickerPanel> createState() => _EmotePickerPanelState();
}

class _EmotePickerPanelState extends State<EmotePickerPanel> {
  List<BiliEmotePackage>? _packages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final packages = await BilibiliCommentService.fetchEmotePanel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _packages = packages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
      );
    }
    final packages = _packages;
    if (packages == null || packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.commentComposerEmoteUnavailable,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                BilibiliCommentService.resetEmotePanelCache();
                _load();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: packages.length,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorColor: cs.primary,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              tabs: [
                for (final pkg in packages)
                  _EmoteTabLabel(package: pkg, colorScheme: cs),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final pkg in packages)
                  _EmoteGrid(package: pkg, onTap: widget.onPick),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

                               
class _EmoteTabLabel extends StatelessWidget {
  final BiliEmotePackage package;
  final ColorScheme colorScheme;

  const _EmoteTabLabel({required this.package, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    if (package.isTextPackage) {
      final label = package.emotes.first.text;
      return Tab(
        height: 38,
        child: Text(
          label.length > 4 ? label.substring(0, 4) : label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Tab(
      height: 38,
      child: package.url.isNotEmpty
          ? Image(
              image: CachedImageProvider(package.url),
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => Icon(
                Icons.emoji_emotions_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.emoji_emotions_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
    );
  }
}

                           
class _EmoteGrid extends StatelessWidget {
  final BiliEmotePackage package;
  final ValueChanged<String> onTap;

  const _EmoteGrid({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 52,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: package.emotes.length,
      itemBuilder: (ctx, i) {
        final emote = package.emotes[i];
        final isSmall = emote.size == 1;
        if (package.isTextPackage) {
          final label = emote.text;
          final stripped = label.startsWith('[') && label.endsWith(']')
              ? label.substring(1, label.length - 1)
              : label;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTap(emote.text),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  stripped,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 13,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        }
        final size = isSmall ? 24.0 : 40.0;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(emote.text),
          child: Center(
            child: Image(
              image: CachedImageProvider(emote.url),
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: 18,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
