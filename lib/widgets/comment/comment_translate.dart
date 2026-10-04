                                             
  
               
                                                                      
                                                     
                                                      
                                
                  
                               
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/widgets/app_toast.dart';

                        
   
                                        
                                         
               
abstract final class CommentTranslateCache {
  static final Map<String, String> _map = <String, String>{};

  static String? of(String rpid) => _map[rpid];

  static void remember(String rpid, String translated) {
    if (rpid.isEmpty || translated.isEmpty) return;
    _map[rpid] = translated;
  }

  static void forget(String rpid) => _map.remove(rpid);

                   
  static void clear() => _map.clear();
}

                                               
              
Future<String?> fetchCommentTranslation(
  BuildContext context, {
  required int oid,
  required int type,
  required int rpid,
  required String original,
}) async {
  final l10n = AppLocalizations.of(context);
  if (!BilibiliTranslateService.enabledOrFalse) {
    showAppToast(context, l10n.commentTranslateNeedEnable, error: true);
    return null;
  }
  if (oid <= 0 || rpid <= 0) {
    showAppToast(context, l10n.commentTranslateNone, error: true);
    return null;
  }
  final map = await BilibiliTranslateApi.translateComment(
    oid: oid,
    type: type,
    rpids: [rpid],
  );
  final t = map[rpid] ?? '';
  if (t.isEmpty || t == original) {
    if (context.mounted) {
      showAppToast(context, l10n.commentTranslateNone, error: true);
    }
    return null;
  }
  return t;
}

                             
class CommentTranslateIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool translating;
  final bool active;

  const CommentTranslateIconButton({
    super.key,
    required this.onTap,
    this.translating = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (translating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          Icons.translate,
          size: 16,
          color: active ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
