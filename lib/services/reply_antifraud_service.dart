                                            
  
                                                  
  
                                 
                                           
  
                       
                                                       
                                                         
                                                 
                                                        
                                              
                                                             
  
                      
                                                      
  
                                           
                                             
                               
                                   
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:naviflash/main.dart' show globalNavigatorKey;
import 'package:naviflash/services/bilibili_comment_service.dart';

              
enum ReplyAuditStatus {
           
  unknown,

                  
  visible,

                                
  shadowBan,

                      
  invisible,

                             
  suspicious,

                    
  error,
}

class ReplyAuditResult {
  final ReplyAuditStatus status;

                        
  final String message;

  const ReplyAuditResult(this.status, this.message);

  bool get isBan =>
      status == ReplyAuditStatus.shadowBan ||
      status == ReplyAuditStatus.invisible;

  bool get isVisible => status == ReplyAuditStatus.visible;
}

abstract final class ReplyAntifraudService {
                            
  static const int _maxFloorPages = 10;

                                     
     
                                                           
                                                 
  static Future<ReplyAuditResult> check({
    required String oid,
    required int type,
    required String rpid,
    required String root,
    required String message,
  }) async {
    final oidInt = int.tryParse(oid) ?? 0;
    if (oidInt <= 0 || rpid.isEmpty) {
      return const ReplyAuditResult(
        ReplyAuditStatus.error,
        '缺少评论参数，无法检测',
      );
    }
    final typeStr = type.toString();
    final rootRpid = int.tryParse(root) ?? 0;

    try {
      if (rootRpid == 0) {
                              
        final anonPage = await BilibiliCommentService.fetchComments(
          cid: oid,
          sort: 1,                
          forceGuest: true,
        );
        if (anonPage == null) {
          return ReplyAuditResult(
            ReplyAuditStatus.error,
            '获取评论主列表失败：${BilibiliCommentService.lastErrorDetail ?? '未知错误'}',
          );
        }
        final foundAnon = anonPage.comments.any((c) => c.rpid == rpid) ||
            anonPage.topReplies.any((c) => c.rpid == rpid);
        if (foundAnon) {
          return ReplyAuditResult(
            ReplyAuditStatus.visible,
            '无账号状态下找到了你的评论，评论正常！\n\n你的评论：$message',
          );
        }

                                 
        final loginSub = await BilibiliCommentService.fetchSubComments(
          cid: oid,
          root: rpid,
          type: typeStr,
        );
        if (loginSub == null) {
          return ReplyAuditResult(
            ReplyAuditStatus.invisible,
            '无法找到你的评论。\n\n你的评论：$message',
          );
        }

                                                  
        final anonSub = await BilibiliCommentService.fetchSubComments(
          cid: oid,
          root: rpid,
          type: typeStr,
          forceGuest: true,
        );
        if (anonSub == null) {
          final code = BilibiliCommentService.lastErrorCode;
          if (code == 12022) {
            return ReplyAuditResult(
              ReplyAuditStatus.shadowBan,
              '你的评论被 shadow ban（仅自己可见）！\n\n你的评论：$message',
            );
          }
          return ReplyAuditResult(
            ReplyAuditStatus.invisible,
            '评论不可见（code=$code）：$message',
          );
        }
        return ReplyAuditResult(
          ReplyAuditStatus.suspicious,
          '你的评论状态有点可疑：无账号翻评论区找不到，但无账号可通过楼中楼接口读取。\n'
          '疑似评论区被戒严，或者这是你自己的视频。\n\n你的评论：$message',
        );
      }

                                
      for (var i = 1; i <= _maxFloorPages; i++) {
        final page = await BilibiliCommentService.fetchSubComments(
          cid: oid,
          root: root,
          page: i,
          type: typeStr,
          forceGuest: true,
        );
        if (page == null || page.replies.isEmpty) break;
        if (page.replies.any((c) => c.rpid == rpid)) {
          return ReplyAuditResult(
            ReplyAuditStatus.visible,
            '无账号状态下找到了你的评论，评论正常！\n\n你的评论：$message',
          );
        }
      }
      for (var i = 1; i <= _maxFloorPages; i++) {
        final page = await BilibiliCommentService.fetchSubComments(
          cid: oid,
          root: root,
          page: i,
          type: typeStr,
        );
        if (page == null || page.replies.isEmpty) break;
        if (page.replies.any((c) => c.rpid == rpid)) {
          return ReplyAuditResult(
            ReplyAuditStatus.shadowBan,
            '你的评论被 shadow ban（仅自己可见）！\n\n你的评论：$message',
          );
        }
      }
      return ReplyAuditResult(
        ReplyAuditStatus.invisible,
        '评论不可见：$message',
      );
    } catch (e) {
      return ReplyAuditResult(ReplyAuditStatus.error, '检测异常：$e');
    }
  }

                                           
  static String label(ReplyAuditStatus status, {bool curated = false}) {
    switch (status) {
      case ReplyAuditStatus.visible:
        return curated ? '已入选' : '已公开';
      case ReplyAuditStatus.shadowBan:
        return curated ? '未入选' : '仅自己可见';
      case ReplyAuditStatus.invisible:
        return '不可见';
      case ReplyAuditStatus.suspicious:
        return '可疑';
      case ReplyAuditStatus.error:
        return '检测失败';
      case ReplyAuditStatus.unknown:
        return '未检测';
    }
  }

                      
  static String hint(ReplyAuditStatus status, {bool curated = false}) {
    if (!curated) return '';
    switch (status) {
      case ReplyAuditStatus.visible:
        return '已被 UP 选入评论区，其他账号可以读到';
      case ReplyAuditStatus.shadowBan:
        return '尚未被 UP 选入评论区（或审核中），仅自己可见';
      case ReplyAuditStatus.invisible:
        return '评论不可见，可能已被删除或审核拒绝';
      default:
        return '';
    }
  }

                                        
                                   
  static Future<void> showResultDialog(
    ReplyAuditResult result, {
    required bool manual,
    String? oid,
    int? type,
  }) async {
    final context = globalNavigatorKey.currentContext;
    if (context == null) return;
    final cs = Theme.of(context).colorScheme;
    final isBan = result.isBan;
    await showDialog<void>(
      context: context,
      barrierDismissible: manual,
      builder: (ctx) {
        final color = isBan ? cs.error : cs.primary;
        return AlertDialog(
          title: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    isBan
                        ? Icons.highlight_off_outlined
                        : (result.status == ReplyAuditStatus.suspicious
                              ? Icons.help_outline
                              : Icons.check_circle_outline_rounded),
                    size: 22,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' 评论检查结果',
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
          content: SelectableText(result.message),
          actions: [
            if (isBan)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  launchUrl(
                    Uri.parse('https://www.bilibili.com/h5/comment/appeal'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('申诉'),
              ),
            if (!manual)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('关闭', style: TextStyle(color: cs.outline)),
              ),
          ],
        );
      },
    );
  }
}
