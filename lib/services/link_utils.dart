// lib/services/link_utils.dart
//
// 全局链接检测：从文本中识别 URL，并提供「在内置浏览器中打开」的统一入口。
// 评论蓝链 / 评论长按菜单等复用（与 chat_screen 的链接处理一致）。
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';

/// 链接正则：可带可不带 http(s)://，识别域名 + 端口 + 路径。
final RegExp linkPattern = RegExp(
  r'(https?://)?'
  r'([a-zA-Z0-9-]+\.)+'
  r'[a-zA-Z]{2,}'
  r'(:[0-9]+)?'
  r'(/[^\s]*)?',
  caseSensitive: false,
);

/// 规范化链接：无协议前缀时补 https://。
String normalizeLink(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

/// 提取文本中的所有链接（已规范化）。
List<String> extractLinks(String text) {
  if (text.isEmpty) return const [];
  return linkPattern.allMatches(text).map((m) => normalizeLink(m[0]!)).toList();
}

/// 文本中的第一个链接；无则返回 null。
String? firstLink(String text) {
  final links = extractLinks(text);
  return links.isEmpty ? null : links.first;
}

/// 文本是否包含链接。
bool containsLink(String text) => linkPattern.hasMatch(text);

/// 在内置浏览器中打开链接（可选确认弹窗；长按菜单已选择时传 confirm: false）。
Future<void> openLinkInBuiltInBrowser(
  BuildContext context, {
  required String url,
  bool confirm = true,
}) async {
  final normalized = normalizeLink(url);
  if (normalized.isEmpty) return;
  final l10n = AppLocalizations.of(context);

  if (confirm) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chatOpenLinkTitle),
        content: Text(
          l10n.chatWillOpen(normalized),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.scanOpen),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BrowserPage(
        initialUrl: normalized,
        title: AppLocalizations.of(context).chatBrowserTitle,
      ),
    ),
  );
}
