                                     
  
                                                   
  
                                                  
                                                            
                                        
                  
                                             
                                                                         
                                       
                                                      
                             
                                          
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'bilibili_account_service.dart';
import 'bilibili_comment_service.dart';
import 'bilibili_reply_grpc_service.dart';
import 'reply_antifraud_service.dart';
import 'settings_service.dart';

                   
class MyReplyRecord {
                                  
  final String rpid;

                                                   
  final String oid;

                   
  final String mid;

                                       
  final int type;

                             
  final String root;

                             
  final String parent;

                              
  final String message;

                  
  final int ctime;

                                     
  final String sourceTitle;

                                              
  final String sourceId;

                 
  final List<String> pictures;

                                              
  bool isCurated;

                 
  ReplyAuditStatus checkStatus;

             
  String checkMessage;

                            
  int checkedAt;

  MyReplyRecord({
    required this.rpid,
    required this.oid,
    required this.mid,
    required this.type,
    required this.root,
    required this.parent,
    required this.message,
    required this.ctime,
    this.sourceTitle = '',
    this.sourceId = '',
    this.pictures = const [],
    this.isCurated = false,
    this.checkStatus = ReplyAuditStatus.unknown,
    this.checkMessage = '',
    this.checkedAt = 0,
  });

               
  bool get isFloorReply => root.isNotEmpty && root != '0';

  Map<String, dynamic> toJson() => {
        'rpid': rpid,
        'oid': oid,
        'mid': mid,
        'type': type,
        'root': root,
        'parent': parent,
        'message': message,
        'ctime': ctime,
        'sourceTitle': sourceTitle,
        'sourceId': sourceId,
        'pictures': pictures,
        'isCurated': isCurated,
        'checkStatus': checkStatus.name,
        'checkMessage': checkMessage,
        'checkedAt': checkedAt,
      };

  factory MyReplyRecord.fromJson(Map<String, dynamic> json) => MyReplyRecord(
        rpid: (json['rpid'] as String?) ?? '',
        oid: (json['oid'] as dynamic)?.toString() ?? '',
        mid: (json['mid'] as dynamic)?.toString() ?? '',
        type: (json['type'] as num?)?.toInt() ?? 1,
        root: (json['root'] as dynamic)?.toString() ?? '0',
        parent: (json['parent'] as dynamic)?.toString() ?? '0',
        message: (json['message'] as String?) ?? '',
        ctime: (json['ctime'] as num?)?.toInt() ?? 0,
        sourceTitle: (json['sourceTitle'] as String?) ?? '',
        sourceId: (json['sourceId'] as String?) ?? '',
        pictures: (json['pictures'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        isCurated: json['isCurated'] == true,
        checkStatus: _statusFromName(json['checkStatus'] as String?),
        checkMessage: (json['checkMessage'] as String?) ?? '',
        checkedAt: (json['checkedAt'] as num?)?.toInt() ?? 0,
      );

  static ReplyAuditStatus _statusFromName(String? name) {
    for (final s in ReplyAuditStatus.values) {
      if (s.name == name) return s;
    }
    return ReplyAuditStatus.unknown;
  }
}

class MyReplyService extends ChangeNotifier {
  static const String _fileName = 'my_replies.json';

                         
  static const int _maxRecords = 2000;

  static MyReplyService? _instance;

                                   
  static MyReplyService get instance => _instance ??= MyReplyService._();

  MyReplyService._();

  List<MyReplyRecord> _items = [];
  bool _loaded = false;
  Future<void>? _initializing;

  bool get isLoaded => _loaded;

                 
  List<MyReplyRecord> get records => List.unmodifiable(_items);

  int get count => _items.length;

                 
  List<MyReplyRecord> get normalRecords =>
      _items.where((e) => !e.isCurated).toList();

                 
  List<MyReplyRecord> get curatedRecords =>
      _items.where((e) => e.isCurated).toList();

  Future<void> initialize() {
    return _initializing ??= _load();
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List)
            .whereType<Map<String, dynamic>>()
            .map(MyReplyRecord.fromJson)
            .toList();
        _items = list;
      }
    } catch (e) {
      debugPrint('[MyReply] 加载失败: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _persist() async {
    try {
      final file = await _file;
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await file.writeAsString(raw, flush: true);
    } catch (e) {
      debugPrint('[MyReply] 写入失败: $e');
    }
  }

                             
     
                                           
  Future<void> recordSent({
    required int oid,
    required int type,
    required String message,
    String root = '0',
    String parent = '0',
    BiliComment? comment,
    String sourceTitle = '',
    String sourceId = '',
    List<String> pictures = const [],
  }) async {
    final rpid = comment?.rpid ?? '';
    if (rpid.isNotEmpty) {
      final index = _items.indexWhere((e) => e.rpid == rpid);
      if (index >= 0) return;              
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final record = MyReplyRecord(
      rpid: rpid,
      oid: oid.toString(),
      mid: BilibiliAccountService.instance.mid.toString(),
      type: type,
      root: root,
      parent: parent,
      message: message,
      ctime: comment?.ctime ?? now,
      sourceTitle: sourceTitle,
      sourceId: sourceId,
      pictures: pictures,
    );
    _items.insert(0, record);
    if (_items.length > _maxRecords) {
      _items = _items.sublist(0, _maxRecords);
    }
    notifyListeners();
    await _persist();

    if (rpid.isEmpty) return;
    unawaited(_detectCurated(record));
    if (SettingsService.commAntifraudEnabledStatic) {
      unawaited(_autoAudit(record));
    }
  }

                           
  Future<void> _detectCurated(MyReplyRecord record) async {
    final oid = int.tryParse(record.oid) ?? 0;
    final curated = await BilibiliReplyGrpcService.isCurated(
      oid: oid,
      type: record.type,
    );
    if (curated == null || record.isCurated == curated) return;
    record.isCurated = curated;
    notifyListeners();
    await _persist();
  }

                                         
  Future<void> _autoAudit(MyReplyRecord record) async {
    await Future.delayed(const Duration(seconds: 8));
    if (!_items.contains(record)) return;
    await auditRecord(record, manual: false);
  }

                                                
  Future<ReplyAuditResult> auditRecord(
    MyReplyRecord record, {
    bool manual = true,
    bool showDialog = true,
  }) async {
    final result = await ReplyAntifraudService.check(
      oid: record.oid,
      type: record.type,
      rpid: record.rpid,
      root: record.root,
      message: record.message,
    );
    record.checkStatus = result.status;
    record.checkMessage = result.message;
    record.checkedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    notifyListeners();
    await _persist();
    if (showDialog) {
      await ReplyAntifraudService.showResultDialog(
        result,
        manual: manual,
        oid: record.oid,
        type: record.type,
      );
    }
    return result;
  }

             
  Future<void> remove(MyReplyRecord record) async {
    _items.remove(record);
    notifyListeners();
    await _persist();
  }

             
  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }
}
