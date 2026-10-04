                                     
  
                              
                           
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/clipboard_image_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

class ScreenshotDialog extends StatelessWidget {
  const ScreenshotDialog({super.key, required this.pngBytes});

  final Uint8List pngBytes;

                                               
  static Future<void> show(BuildContext context, Uint8List pngBytes) {
    return showDialog<void>(
      context: context,
      builder: (_) => ScreenshotDialog(pngBytes: pngBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(size.width * 0.9, 960),
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.playerMenuScreenshot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
            Flexible(
              child: GestureDetector(
                                             
                onSecondaryTapDown: (details) =>
                    _showContextMenu(context, details.globalPosition),
                child: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Image.memory(pngBytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
                                              
                                                  
                                                       
    final safeContext = Navigator.of(context).context;
    showGlassDropdownMenu(
      context,
      globalPosition: globalPosition,
      menuWidth: 200,
      actions: [
        GlassMenuAction(
          icon: Icons.content_copy_outlined,
          text: AppLocalizations.of(context).screenshotCopy,
          onTap: () => _copyToClipboard(safeContext),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (!ClipboardImageService.isSupported) {
      showAppToast(context, l10n.screenshotCopyUnsupported, error: true);
      return;
    }
    final ok = await ClipboardImageService.copyPng(pngBytes);
    if (!context.mounted) return;
    showAppToast(
      context,
      ok ? l10n.screenshotCopied : l10n.screenshotCopyUnsupported,
      error: !ok,
    );
  }
}
