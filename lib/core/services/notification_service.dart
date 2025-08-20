import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/exceptions.dart';

@singleton
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure Firebase messaging
      await _configureFirebaseMessaging();

      _isInitialized = true;
    } catch (e) {
      throw AppException('Failed to initialize notifications: $e');
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // Request Firebase messaging permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Request system-level notification permissions
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw AppException('Failed to request permissions: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();
    } catch (e) {
      throw AppException('Failed to initialize local notifications: $e');
    }
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    try {
      const messageChannel = AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Notifications for new messages',
        importance: Importance.high,
        playSound: true,
      );

      const matchChannel = AndroidNotificationChannel(
        'matches',
        'Matches',
        description: 'Notifications for new matches',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(messageChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(matchChannel);
    } catch (e) {
      throw AppException('Failed to create notification channels: $e');
    }
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message if app was opened from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Set foreground notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      throw AppException('Failed to configure Firebase messaging: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Lumina Chat',
        body: notification.body ?? '',
        payload: message.data['type'] ?? '',
        channelId: _getChannelId(message.data['type']),
      );
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    
  final type = message.data['type'];
    
    // TODO: Navigate to appropriate screen based on notification type
    switch (type) {
      case 'message':
        // Navigate to chat screen
        break;
      case 'match':
        // Navigate to match details
        break;
      case 'like':
        // Navigate to likes screen
        break;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    // TODO: Handle local notification tap
    switch (response.payload) {
      case 'message':
        // Navigate to chat
        break;
      case 'match':
        // Navigate to matches
        break;
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'general',
        'General',
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      throw AppException('Failed to show local notification: $e');
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw AppException('Failed to get FCM token: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw AppException('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw AppException('Failed to unsubscribe from topic: $e');
    }
  }

  // Show new message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await _showLocalNotification(
      title: senderName,
      body: message,
      payload: 'message_$chatId',
      channelId: 'messages',
    );
  }

  // Show new match notification
  Future<void> showMatchNotification({
    required String matchName,
    required String matchId,
  }) async {
    await _showLocalNotification(
      title: 'New Match! 🎉',
      body: 'You and $matchName liked each other!',
      payload: 'match_$matchId',
      channelId: 'matches',
    );
  }

  // Show like notification
  Future<void> showLikeNotification({
    required String likerName,
    required String userId,
  }) async {
    await _showLocalNotification(
      title: 'Someone likes you! ❤️',
      body: '$likerName is interested in you',
      payload: 'like_$userId',
      channelId: 'matches',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      throw AppException('Failed to cancel notifications: $e');
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      throw AppException('Failed to cancel notification: $e');
    }
  }

  // Get channel ID based on notification type
  String _getChannelId(String? type) {
    switch (type) {
      case 'message':
        return 'messages';
      case 'match':
      case 'like':
        return 'matches';
      default:
        return 'general';
    }
  }

  // Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      throw AppException('Failed to delete FCM token: $e');
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Open notification settings
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      throw AppException('Failed to open notification settings: $e');
    }
  }

  // Schedule notification for later
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
  // TODO: Implement scheduled notifications
      // This requires additional setup for timezone handling
  // Example when enabled:
  // await _localNotifications.zonedSchedule(
  //   0,
  //   title,
  //   body,
  //   tz.TZDateTime.from(scheduledDate, tz.local),
  //   const NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'scheduled',
  //       'Scheduled',
  //       channelDescription: 'Scheduled notifications',
  //       importance: Importance.high,
  //       priority: Priority.high,
  //     ),
  //     iOS: DarwinNotificationDetails(),
  //   ),
  //   uiLocalNotificationDateInterpretation:
  //       UILocalNotificationDateInterpretation.absoluteTime,
  //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   payload: payload,
  // );
    } catch (e) {
      throw AppException('Failed to schedule notification: $e');
    }
  }
}

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message
}
