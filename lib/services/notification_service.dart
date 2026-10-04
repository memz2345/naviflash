                                         
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:local_notifier/local_notifier.dart';               
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../l10n/l10n_helper.dart';

class NotificationService {
                                       
                                                
  static const MethodChannel _winToastChannel =
      MethodChannel('com.memz2345.navi.flash/toast');

                                                  
  static const int _maxWinToastImageBytes = 2 * 1024 * 1024;
                                                          
  static const int _kWinToastMaxSide = 1024;
  static const int _kWinToastJpegQuality = 85;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _isAppInForeground = true;
  int _notificationId = 0;

                                 
  Map<String, String?>? _pendingNotificationPayload;

  bool get isInitialized => _isInitialized;
  bool get isAppInForeground => _isAppInForeground;

                           
                                                                
  void cachePendingPayload(Map<String, String?> payload) {
    _pendingNotificationPayload = payload;
  }

                                           
  Map<String, String?>? consumePendingNotification() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Platform.isWindows) {
                                 
        await localNotifier.setup(
          appName: 'NaviFlash',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } else {
                                          
        await AwesomeNotifications().initialize(
          null,            
          [
            NotificationChannel(
              channelKey: 'navi_flash',
              channelName: L10n.current.notificationChannelName,
              channelDescription: L10n.current.notificationChannelDesc,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Public,
              enableVibration: true,
              playSound: true,
            )
          ],
        );
                 
        bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (!isAllowed) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
                                                                  
                                                    
                                                                                        
      }
      _isInitialized = true;
      if (kDebugMode) print('Notification service initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Notification initialization failed: $e');
      _isInitialized = false;
    }
  }

                   
  Future<void> showMessageNotification({
    required String senderIP,
    required String nickname,
    required String message,
    String? avatarPath,           
    int? notificationId,
  }) async {
    if (!_isInitialized) return;
    final id = notificationId ?? ++_notificationId;
    final displayMessage = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;
                         
    final displayTitle = (nickname.trim().isEmpty) ? senderIP : nickname;

    if (Platform.isWindows) {
      try {
        LocalNotification winNotification = LocalNotification(
          title: displayTitle,
          body: displayMessage,
        );
        await winNotification.show();
      } catch (e) {
        if (kDebugMode) print('Failed to send Windows Toast: $e');
      }
    } else {
                        
      String? largeIcon;
      if (avatarPath != null &&
          avatarPath.isNotEmpty &&
          await File(avatarPath).exists()) {
                                                      
        largeIcon = 'file://$avatarPath';
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'navi_flash',
          title: displayTitle,
          body: displayMessage,
          payload: {'senderIP': senderIP},
          category: NotificationCategory.Message,
          notificationLayout: NotificationLayout.Messaging,
          largeIcon: largeIcon,                                 
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: L10n.current.notificationReply,
            requireInputText: true,                                        
          ),
        ],
      );
    }
  }

                  
  Future<void> showFileNotification({
    required String senderIP,
    required String nickname,
    required String fileName,
    required int fileSize,
    String? avatarPath,           
    int? notificationId,
  }) async {
    if (!_isInitialized) return;
    final id = notificationId ?? ++_notificationId;
                         
    final displayTitle = (nickname.trim().isEmpty) ? senderIP : nickname;

    if (Platform.isWindows) {
      try {
        LocalNotification winNotification = LocalNotification(
          title: displayTitle,
          body: L10n.current.homeFileMessage(fileName),
        );
        await winNotification.show();
      } catch (e) {
        if (kDebugMode) print('Failed to send Windows Toast: $e');
      }
    } else {
          
      String? largeIcon;
      if (avatarPath != null &&
          avatarPath.isNotEmpty &&
          await File(avatarPath).exists()) {
        largeIcon = 'file://$avatarPath';
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'navi_flash',
          title: displayTitle,
          body: L10n.current.homeFileMessage(fileName),
          payload: {'senderIP': senderIP},
          category: NotificationCategory.Message,
          largeIcon: largeIcon,         
        ),
      );
    }
  }

  void setAppForeground(bool inForeground) {
    _isAppInForeground = inForeground;
  }

  Future<void> cancelNotification(int id) async {
    if (!Platform.isWindows) {
      await AwesomeNotifications().cancel(id);
    }
  }
 Future<void> showScreenshotNotification({
    required String imagePath,
    required String message,
  }) async {
    if (!_isInitialized) return;
    final id = ++_notificationId;

    if (Platform.isWindows) {
                                             
                                                            
                                                       
                                                 
      try {
        final thumbPath = await _prepareWinToastImage(imagePath);
        if (thumbPath != null) {
          final shown = await _winToastChannel.invokeMethod<bool>(
            'showImage',
            <String, dynamic>{
              'title': L10n.current.screenshotSavedTitle,
              'body': message,
              'imagePath': thumbPath,
            },
          );
          if (shown == true) return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('WinRT 大图 toast 失败，回退 local_notifier: $e');
        }
      }
                     
      try {
        final winNotification = LocalNotification(
          title: L10n.current.screenshotSavedTitle,
          body: message,
        );
        await winNotification.show();
      } catch (e) {
        if (kDebugMode) print('Failed to send Windows Toast: $e');
      }
    } else {
      String? bigPicture;
      if (imagePath.isNotEmpty && await File(imagePath).exists()) {
        bigPicture = 'file://$imagePath';
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'navi_flash',
          title: L10n.current.screenshotSavedToAlbum,
          body: message,
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: bigPicture,
          largeIcon: bigPicture,
          category: NotificationCategory.Status,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS_SCREENSHOT',
            label: L10n.current.notificationConfirm,
          ),
        ],
      );
    }
  }
                                                               
                                                         
                                             
  static Future<String?> _prepareWinToastImage(String imagePath) async {
    try {
      if (imagePath.isEmpty) return null;
      final src = File(imagePath);
      if (!await src.exists()) return null;

      final decoded = img.decodeImage(await src.readAsBytes());
      if (decoded == null) return null;

      var resized = decoded;
      if (decoded.width > _kWinToastMaxSide ||
          decoded.height > _kWinToastMaxSide) {
                           
        resized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _kWinToastMaxSide : null,
          height: decoded.height > decoded.width ? _kWinToastMaxSide : null,
        );
      }

      var quality = _kWinToastJpegQuality;
      var bytes = img.encodeJpg(resized, quality: quality);
                                  
      while (bytes.length > _maxWinToastImageBytes && quality > 30) {
        quality -= 15;
        bytes = img.encodeJpg(resized, quality: quality);
      }
      if (bytes.length > _maxWinToastImageBytes) return null;

      final dir = await getTemporaryDirectory();
      final out =
          File('${dir.path}${Platform.pathSeparator}navi_toast_thumb.jpg');
      await out.writeAsBytes(bytes);
      return out.path;
    } catch (e) {
      if (kDebugMode) print('生成 WinRT toast 缩略图失败: $e');
      return null;
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!Platform.isWindows) {
      await AwesomeNotifications().cancelAll();
    }
  }
}