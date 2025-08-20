import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }

  Future<void> logSetUsername(String username) async {
    await _analytics.logEvent(name: 'set_username', parameters: {
      'username': username,
    });
  }

  Future<void> logStartChat({required String targetUid}) async {
    await _analytics.logEvent(name: 'start_chat', parameters: {
      'target_uid': targetUid,
    });
  }

  Future<void> logOpenChat(String chatId) async {
    await _analytics.logEvent(name: 'open_chat', parameters: {
      'chat_id': chatId,
    });
  }

  Future<void> logSendMessage({required String chatId, required String type}) async {
    await _analytics.logEvent(name: 'send_message', parameters: {
      'chat_id': chatId,
      'type': type,
    });
  }
}

// Simple singleton instance for convenience
final analyticsService = AnalyticsService();
