import 'package:firebase_messaging/firebase_messaging.dart';

import 'backend_client.dart';

class NotificationService {
  const NotificationService._();

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null) {
      try {
        await BackendClient.instance.postJson('/notifications/register', {
          'token': token,
          'platform': 'flutter',
        });
      } catch (_) {
        // Notification registration should not prevent app startup.
      }
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await BackendClient.instance.postJson('/notifications/register', {
          'token': token,
          'platform': 'flutter',
        });
      } catch (_) {}
    });
  }
}
