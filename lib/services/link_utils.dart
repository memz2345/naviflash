                               
  
                                         
                                           
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';

                                         
final RegExp linkPattern = RegExp(
  r'(https?://)?'
  r'([a-zA-Z0-9-]+\.)+'
  r'[a-zA-Z]{2,}'
  r'(:[0-9]+)?'
  r'(/[^\s]*)?',
  caseSensitive: false,
);

                           
String normalizeLink(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

                     
List<String> extractLinks(String text) {
  if (text.isEmpty) return const [];
  return linkPattern.allMatches(text).map((m) => normalizeLink(m[0]!)).toList();
}

                        
String? firstLink(String text) {
  final links = extractLinks(text);
  return links.isEmpty ? null : links.first;
}

             
bool containsLink(String text) => linkPattern.hasMatch(text);

                                                 
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
