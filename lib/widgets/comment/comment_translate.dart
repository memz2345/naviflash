// lib/widgets/comment/comment_translate.dart
//
// 评论区「翻译」动作助手：
// - [fetchCommentTranslation]：封装 gRPC TranslateReply 调用 + 未开启/无译文的提示。
// - [CommentTranslateIconButton]：只有 translate 图标的按钮（放在点赞右侧）。
// 交互（由各评论卡片持有状态）：
//   点翻译 → 正文替换为译文；再点一下 → 恢复原文。
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/widgets/app_toast.dart';

/// 调用评论翻译接口。返回译文（与原文不同）；失败 / 未开启 / 无译文时返回 null
/// （并视情况弹提示）。
Future<String?> fetchCommentTranslation(
  BuildContext context, {
  required int oid,
  required int type,
  required int rpid,
  required String original,
}) async {
  final l10n = AppLocalizations.of(context);
  if (!BilibiliTranslateService.instance.enabled) {
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

/// 纯 translate 图标的翻译按钮（无文字）。
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
