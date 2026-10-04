                                   
  
                            
  
                                          
                                              
                                               
                                 
                                 

import 'dart:async';

                                           
               
abstract class PlaybackAudioSource {
                                       
  bool get isPlaying;

                                   
  FutureOr<void> pause();
}

class PlaybackFocus {
  PlaybackFocus._();

  static final PlaybackFocus instance = PlaybackFocus._();

  final Set<PlaybackAudioSource> _sources = <PlaybackAudioSource>{};

                      
  void register(PlaybackAudioSource source) {
    _sources.add(source);
  }

                             
  void unregister(PlaybackAudioSource source) {
    _sources.remove(source);
  }

                                      
                                    
  bool get anyPlaying {
    for (final s in List<PlaybackAudioSource>.of(_sources)) {
      try {
        if (s.isPlaying) return true;
      } catch (_) {}
    }
    return false;
  }

                                              
                         
  Future<void> pauseAll({PlaybackAudioSource? except}) async {
    final others = _sources
        .where((s) => !identical(s, except))
        .toList(growable: false);
    for (final s in others) {
      try {
        if (s.isPlaying) await s.pause();
      } catch (_) {
                              
      }
    }
  }

                                      
  Future<void> acquire(PlaybackAudioSource self) {
    return pauseAll(except: self);
  }
}
