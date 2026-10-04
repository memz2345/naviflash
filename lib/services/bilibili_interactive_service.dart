                                                 
  
                                                    
                                                                          
                       
                                                 
                                                                              
                                                            
                                                                     
                                                    
                                      
                                                       
                                                                 
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

                                           
                                           
                                           

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

                                           
                                            
                                           

                                        
class BiliInteractiveStory {
  final int nodeId;
  final int edgeId;
  final String title;

                 
  final int cid;

                    
  final int startPosMs;
  final String cover;

                 
  final bool isCurrent;

                     
  final int cursor;

  const BiliInteractiveStory({
    required this.nodeId,
    required this.edgeId,
    required this.title,
    required this.cid,
    required this.startPosMs,
    required this.cover,
    required this.isCurrent,
    required this.cursor,
  });

  factory BiliInteractiveStory.fromJson(Map<String, dynamic> json) =>
      BiliInteractiveStory(
        nodeId: _toInt(json['node_id']),
        edgeId: _toInt(json['edge_id']),
        title: _toStr(json['title']),
        cid: _toInt(json['cid']),
        startPosMs: _toInt(json['start_pos']),
        cover: _toStr(json['cover']),
        isCurrent: _toInt(json['is_current']) == 1,
        cursor: _toInt(json['cursor']),
      );
}

                                        
class BiliInteractiveChoice {
                                                      
  final int id;

                                    
  final int cid;

           
  final String option;

                                        
                                      
  final String condition;

               
  final bool isDefault;

                              
  final bool isHidden;

                                                           
  final String platformAction;

                                   
                                     
  final double x;
  final double y;

  const BiliInteractiveChoice({
    required this.id,
    required this.cid,
    required this.option,
    required this.condition,
    required this.isDefault,
    required this.isHidden,
    required this.platformAction,
    required this.x,
    required this.y,
  });

  factory BiliInteractiveChoice.fromJson(Map<String, dynamic> json) {
    return BiliInteractiveChoice(
      id: _toInt(json['id']),
      cid: _toInt(json['cid']),
      option: _toStr(json['option']).trim(),
      condition: _toStr(json['condition']),
      isDefault: _toInt(json['is_default']) == 1,
      isHidden: _toInt(json['is_hidden']) == 1,
      platformAction: _toStr(json['platform_action']),
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

                                     
  bool get isSelectable => option.isNotEmpty && !isHidden;
}

                                
class BiliInteractiveQuestion {
                                           
  final int type;

                        
  final int durationMs;

                    
  final bool pauseVideo;

                    
  final List<BiliInteractiveChoice> choices;

  const BiliInteractiveQuestion({
    required this.type,
    required this.durationMs,
    required this.pauseVideo,
    required this.choices,
  });

  factory BiliInteractiveQuestion.fromJson(Map<String, dynamic> json) {
    final raw = (json['choices'] as List?) ?? const [];
    final choices = raw
        .map((e) => BiliInteractiveChoice.fromJson(_asMap(e) ?? const {}))
        .where((c) => c.isSelectable)
        .toList();
    return BiliInteractiveQuestion(
      type: _toInt(json['type']),
      durationMs: _toInt(json['duration']),
      pauseVideo: _toInt(json['pause_video']) == 1,
      choices: choices,
    );
  }

                                 
  bool get shouldShowCard =>
      type != 0 && choices.isNotEmpty;
}

                                       
class BiliInteractiveNode {
               
  final String title;

                                   
  final int edgeId;

                                                          
  final int cid;

                    
  final bool isLeaf;

                              
  final bool noBacktracking;

                            
  final List<BiliInteractiveStory> storyList;

                            
  final List<BiliInteractiveQuestion> questions;

  const BiliInteractiveNode({
    required this.title,
    required this.edgeId,
    required this.cid,
    required this.isLeaf,
    required this.noBacktracking,
    required this.storyList,
    required this.questions,
  });

                                
  BiliInteractiveQuestion? get activeQuestion {
    for (final q in questions) {
      if (q.shouldShowCard) return q;
    }
    return null;
  }

  factory BiliInteractiveNode.fromJson(Map<String, dynamic> json) {
    final edges = _asMap(json['edges']) ?? const <String, dynamic>{};
    final rawQuestions = (edges['questions'] as List?) ?? const [];
    final questions = rawQuestions
        .map((e) => BiliInteractiveQuestion.fromJson(_asMap(e) ?? const {}))
        .toList();
    final rawStory = (json['story_list'] as List?) ?? const [];
    final storyList = rawStory
        .map((e) => BiliInteractiveStory.fromJson(_asMap(e) ?? const {}))
        .toList();
    BiliInteractiveStory? current;
    for (final s in storyList) {
      if (s.isCurrent) {
        current = s;
        break;
      }
    }
    current ??= storyList.isEmpty ? null : storyList.last;
    return BiliInteractiveNode(
      title: _toStr(json['title']),
      edgeId: _toInt(json['edge_id']),
      cid: current?.cid ?? 0,
      isLeaf: _toInt(json['is_leaf']) == 1,
      noBacktracking: _toInt(json['no_backtracking']) == 1,
      storyList: storyList,
      questions: questions,
    );
  }
}

                                           
                       
                                           

abstract final class BilibiliInteractiveParser {
                                                  
                                      
  static BiliInteractiveNode? parseEdgeInfoData(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['edges'] is! Map) return null;
    final node = BiliInteractiveNode.fromJson(data);
    if (node.edgeId <= 0 && node.questions.isEmpty) return null;
    return node;
  }

                                        
                               
  static int parseGraphVersion(Map<String, dynamic>? data) =>
      _toInt(_asMap(data?['interaction'])?['graph_version']);
}

                                           
           
                                           

abstract final class BilibiliInteractiveService {
  static const String _apiBase = 'https://api.bilibili.com';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                                                
                                              
  static Future<({int graphVersion, String? err})> fetchGraphVersion({
    required int aid,
    required int cid,
  }) async {
    if (aid <= 0 || cid <= 0) {
      return (graphVersion: 0, err: '参数不完整');
    }
    try {
      final uri = Uri.parse('$_apiBase/x/player/v2').replace(
        queryParameters: {'aid': aid.toString(), 'cid': cid.toString()},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (graphVersion: 0, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        final msg = json is Map ? _toStr(json['message']) : '';
        return (graphVersion: 0, err: msg.isEmpty ? '接口返回异常' : msg);
      }
      final version = BilibiliInteractiveParser.parseGraphVersion(
        _asMap(json['data']),
      );
      if (version <= 0) {
        return (graphVersion: 0, err: '该视频不是互动视频或剧情图已失效');
      }
      return (graphVersion: version, err: null);
    } catch (e) {
      debugPrint('[Interactive] 剧情图版本获取失败: $e');
      return (graphVersion: 0, err: '网络异常：${e.runtimeType}');
    }
  }

                                  
                              
  static Future<({BiliInteractiveNode? node, String? err})> fetchEdge({
    required String bvid,
    required int graphVersion,
    int edgeId = 0,
  }) async {
    if (bvid.isEmpty || graphVersion <= 0) {
      return (node: null, err: '参数不完整');
    }
    try {
      final uri = Uri.parse('$_apiBase/x/stein/edgeinfo_v2').replace(
        queryParameters: {
          'bvid': bvid,
          'graph_version': graphVersion.toString(),
          if (edgeId > 0) 'edge_id': edgeId.toString(),
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (node: null, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        final msg = json is Map ? _toStr(json['message']) : '';
        return (node: null, err: msg.isEmpty ? '接口返回 ${json is Map ? json['code'] : ''}' : msg);
      }
      final node = BilibiliInteractiveParser.parseEdgeInfoData(
        _asMap(json['data']),
      );
      if (node == null) {
        return (node: null, err: '节点数据解析失败');
      }
      return (node: node, err: null);
    } catch (e) {
      debugPrint('[Interactive] 节点信息获取失败: $e');
      return (node: null, err: '网络异常：${e.runtimeType}');
    }
  }
}
