import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

                      
class MiniPlayerData {
  const MiniPlayerData({
    required this.videoUrl,
    required this.title,
    this.bvid,
    this.aid,
    this.cid,
    this.cover,
    this.ownerName,
    this.ownerMid,
    this.httpHeaders,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

                                        
  final String videoUrl;
  final String title;
  final String? bvid;
  final int? aid;
  final int? cid;
  final String? cover;
  final String? ownerName;
  final int? ownerMid;
  final Map<String, String>? httpHeaders;

                
  final Duration position;
  final Duration duration;

  MiniPlayerData copyWith({Duration? position, Duration? duration}) {
    return MiniPlayerData(
      videoUrl: videoUrl,
      title: title,
      bvid: bvid,
      aid: aid,
      cid: cid,
      cover: cover,
      ownerName: ownerName,
      ownerMid: ownerMid,
      httpHeaders: httpHeaders,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

                                 
   
                                                 
                         
class MiniPlayerService extends ChangeNotifier {
  MiniPlayerService._();

  static final MiniPlayerService instance = MiniPlayerService._();

  static const String _kPrefLeftRatio = 'miniPlayerLeftRatio';
  static const String _kPrefTopRatio = 'miniPlayerTopRatio';

  MiniPlayerData? _data;
  Rect? _originRect;
  Rect? _frame;

  double? _savedLeftRatio;
  double? _savedTopRatio;

  MiniPlayerData? get data => _data;

               
  bool get isActive => _data != null;

                                     
  Rect? get originRect => _originRect;

                   
  Rect? get frame => _frame;

  double? get savedLeftRatio => _savedLeftRatio;
  double? get savedTopRatio => _savedTopRatio;

                                  
  Future<void> loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedLeftRatio = prefs.getDouble(_kPrefLeftRatio);
      _savedTopRatio = prefs.getDouble(_kPrefTopRatio);
      notifyListeners();
    } catch (_) {
                        
    }
  }

                                            
  void enter(MiniPlayerData data, {Rect? origin}) {
    if (_data != null && _data!.videoUrl == data.videoUrl) {
                              
      _data = data;
      notifyListeners();
      return;
    }
    _data = data;
    _originRect = origin;
    notifyListeners();
  }

           
  void close() {
    if (_data == null) return;
    _data = null;
    _originRect = null;
    notifyListeners();
  }

                               
  void setFrame(Rect frame) {
    if (_frame == frame) return;
    _frame = frame;
    notifyListeners();
  }

                        
  Future<void> persistFrameRatio(Rect frame, Size screen) async {
    if (screen.width <= 0 || screen.height <= 0) return;
    _savedLeftRatio = (frame.left / screen.width).clamp(0.0, 1.0);
    _savedTopRatio = (frame.top / screen.height).clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kPrefLeftRatio, _savedLeftRatio!);
      await prefs.setDouble(_kPrefTopRatio, _savedTopRatio!);
    } catch (_) {
                     
    }
  }
}
