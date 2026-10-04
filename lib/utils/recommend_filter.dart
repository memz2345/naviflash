                                  
  
                                                                
  
                                                             
                                          
  
                      
                                                    
                                                  
                                                 
  
                                          
                                                        
import 'package:flutter/foundation.dart';

abstract final class RecommendFilter {
                      
  static int minDurationSec = 0;

                     
  static int minPlay = 0;

                         
  static int minLikeRatioPercent = 0;

                    
  static bool exemptFollowed = true;

                     
  static bool applyToRelatedVideos = true;

  static RegExp? _titleRe;
  static RegExp? _zoneRe;

  static bool get enableTitleFilter => _titleRe != null;
  static bool get enableZoneFilter => _zoneRe != null;

                                

                              
                                                               
  static bool filterBlacklistUsers = false;

  static Set<int> _blacklistMids = const <int>{};

                                                       
  static void setBlacklist({required bool enabled, required Set<int> mids}) {
    filterBlacklistUsers = enabled;
    _blacklistMids = Set<int>.unmodifiable(mids);
  }

                                     
                        
  static bool filterOwnerMid(int ownerMid) =>
      filterBlacklistUsers && ownerMid > 0 && _blacklistMids.contains(ownerMid);

                                                   
  static void configure({
    required int minLikeRatioPercent,
    required int minDurationSec,
    required int minPlay,
    required String banWordPattern,
    required String banZonePattern,
    required bool exemptFollowed,
    required bool applyToRelatedVideos,
  }) {
    RecommendFilter.minLikeRatioPercent = minLikeRatioPercent;
    RecommendFilter.minDurationSec = minDurationSec;
    RecommendFilter.minPlay = minPlay;
    RecommendFilter.exemptFollowed = exemptFollowed;
    RecommendFilter.applyToRelatedVideos = applyToRelatedVideos;
    setBanWordPatterns(
      recommendPattern: banWordPattern,
      zonePattern: banZonePattern,
    );
  }

                                         
     
                                                 
                          
  static void setBanWordPatterns({
    required String recommendPattern,
    required String zonePattern,
  }) {
    _titleRe = _compile(recommendPattern);
    _zoneRe = _compile(zonePattern);
  }

                                               
  static RegExp? _compile(String pattern) {
    final p = pattern.trim();
    if (p.isEmpty) return null;
    try {
      return RegExp(p, caseSensitive: false);
    } catch (e) {
      debugPrint('[RecommendFilter] 正则不合法，已按「不过滤」处理: $p ($e)');
      return null;
    }
  }

  @visibleForTesting
  static void debugReset() {
    minDurationSec = 0;
    minPlay = 0;
    minLikeRatioPercent = 0;
    exemptFollowed = true;
    applyToRelatedVideos = true;
    _titleRe = null;
    _zoneRe = null;
    filterBlacklistUsers = false;
    _blacklistMids = const <int>{};
  }

              
  static bool filterTitle(String title) => _titleRe?.hasMatch(title) ?? false;

                                           
  static bool filterZone(String? tname) =>
      tname != null && tname.isNotEmpty && (_zoneRe?.hasMatch(tname) ?? false);

                                                           
  static bool filterLikeRatio(int like, int view) {
                        
    if (view <= 0) return false;
    if (minPlay > 0 && view < minPlay) return true;
           
    if (like < 0) return false;
    if (minLikeRatioPercent <= 0) return false;
    return like * 100 < minLikeRatioPercent * view;
  }

                                             
  static bool filterAll({
    required String title,
    required int duration,
    required int like,
    required int view,
  }) {
    return (duration > 0 && duration < minDurationSec) ||
        filterLikeRatio(like, view) ||
        filterTitle(title);
  }

                                
  static bool filterHot({
    required String title,
    required int like,
    required int view,
  }) => filterTitle(title) || filterLikeRatio(like, view);

                               
  static bool filterItem({
    required String title,
    required int duration,
    required int like,
    required int view,
    bool isFollowed = false,
  }) {
    if (isFollowed && exemptFollowed) return false;
    return filterAll(
      title: title,
      duration: duration,
      like: like,
      view: view,
    );
  }
}
