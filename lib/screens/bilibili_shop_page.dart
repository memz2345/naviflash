                                      
  
                                                
                                              
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';

class BilibiliShopPage extends StatelessWidget {
  const BilibiliShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BrowserPage(
      initialUrl: 'https://mall.bilibili.com/',
      title: l10n.memberShop,
    );
  }
}
