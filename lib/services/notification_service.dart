// lib/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:local_notifier/local_notifier.dart'; // Windows 端保留
import '../l10n/l10n_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _isAppInForeground = true;
  int _notificationId = 0;

//  新增：冷启动 / UI 未就绪时暂存的通知 payload
  Map<String, String?>? _pendingNotificationPayload;

  bool get isInitialized => _isInitialized;
  bool get isAppInForeground => _isAppInForeground;

///  新增：UI 未就绪时缓存通知 payload
  /// （冷启动时 actionStream 重放点击事件，但此时 Navigator 的 context 还是 null）
  void cachePendingPayload(Map<String, String?> payload) {
    _pendingNotificationPayload = payload;
  }

///  新增：取出并清除缓存的 payload（由 _NaviHome 首帧后调用）
  Map<String, String?>? consumePendingNotification() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Platform.isWindows) {
//  Windows 平台继续使用 local_notifier
        await localNotifier.setup(
          appName: 'NaviFlash',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } else {
//  Android / iOS 使用 awesome_notifications
        await AwesomeNotifications().initialize(
          null, // 使用默认应用图标
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
        // 请求通知权限
        bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (!isAllowed) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
        // 注意：新版 awesome_notifications 已移除 getInitialNotification，
        // 冷启动的点击事件会由 main.dart 的 actionStream 自动重放，
        // 若此时 UI 未就绪，则由 navigateToChatFromNotification 缓存到 _pendingNotificationPayload。
      }
      _isInitialized = true;
      if (kDebugMode) print('Notification service initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Notification initialization failed: $e');
      _isInitialized = false;
    }
  }

//  消息通知 (带快捷回复输入框)
  Future<void> showMessageNotification({
    required String senderIP,
    required String nickname,
    required String message,
    String? avatarPath, //  接收头像路径
    int? notificationId,
  }) async {
    if (!_isInitialized) return;
    final id = notificationId ?? ++_notificationId;
    final displayMessage = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;
//  优先显示昵称，如果昵称为空则默认显示 IP
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
//  处理头像路径 (Android/iOS)
      String? largeIcon;
      if (avatarPath != null &&
          avatarPath.isNotEmpty &&
          await File(avatarPath).exists()) {
        // awesome_notifications 读取本地外部文件需要 file:// 前缀
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
          largeIcon: largeIcon, //  传递头像 (Messaging 布局下显示为对话者头像)
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: L10n.current.notificationReply,
            requireInputText: true, //  新版 API，替代已弃用的 ActionType.InputField
          ),
        ],
      );
    }
  }

//  文件通知 (不需要回复按钮)
  Future<void> showFileNotification({
    required String senderIP,
    required String nickname,
    required String fileName,
    required int fileSize,
    String? avatarPath, //  接收头像路径
    int? notificationId,
  }) async {
    if (!_isInitialized) return;
    final id = notificationId ?? ++_notificationId;
//  优先显示昵称，如果昵称为空则默认显示 IP
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
//  处理头像路径
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
          largeIcon: largeIcon, //  传递头像
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
        LocalNotification winNotification = LocalNotification(
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
  Future<void> cancelAllNotifications() async {
    if (!Platform.isWindows) {
      await AwesomeNotifications().cancelAll();
    }
  }
}