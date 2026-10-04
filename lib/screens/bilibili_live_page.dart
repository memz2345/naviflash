                                      
  
                                     
                                                       
                                            
                                     
                                             
                                                                            
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/screens/bilibili_live_search_page.dart';
import 'package:naviflash/widgets/live_tag_feed.dart';
import 'package:naviflash/widgets/page_background.dart';

class BilibiliLivePage extends StatelessWidget {
                                            
  final bool embeddedInShell;

  const BilibiliLivePage({super.key, this.embeddedInShell = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feed = const LiveTagFeed();

    if (embeddedInShell) {
                                                
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
                                               
            PageBackground(
              baseColor: cs.surfaceContainer,
              contentStyle: true,
            ),
            SafeArea(bottom: false, child: feed),
            Positioned(
              right: 8,
              top: 4,
              child: _searchButton(context, cs),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('直播'),
        backgroundColor: cs.surfaceContainer,
        actions: [_searchButton(context, cs)],
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(child: feed),
        ],
      ),
    );
  }

                                                 
  Widget _searchButton(BuildContext context, ColorScheme cs) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return MorphIconButton(
      icon: Icons.search_rounded,
      tooltip: isZh ? '搜索直播间 / 主播' : 'Search live',
      transparent: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BilibiliLiveSearchPage()),
      ),
    );
  }
}
