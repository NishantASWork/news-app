import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI in background; opening notification is handled by onMessageOpenedApp when app starts
}

/// Handles FCM: foreground messages show in-app; opening a notification navigates to article.
class NotificationService {
  NotificationService({required GlobalKey<ScaffoldMessengerState> scaffoldKey})
      : _scaffoldKey = scaffoldKey;

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey;
  GoRouter? _router;

  void setGoRouter(GoRouter router) {
    _router = router;
  }

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.subscribeToTopic('news');

    // Foreground: show in-app SnackBar so the app "responds" to a notification from the web
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Update';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(body.isEmpty ? title : '$title: $body'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              final id = message.data['articleId'] ?? message.data['id'];
              if (id != null && id.isNotEmpty) _router?.go('/article/$id');
            },
          ),
        ),
      );
    });

    // User tapped notification (background or terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final id = message.data['articleId'] ?? message.data['id'];
      if (id != null && id.isNotEmpty) _router?.go('/article/$id');
    });

    // Check if app was opened from a notification (terminated state)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final id = initial.data['articleId'] ?? initial.data['id'];
      if (id != null && id.isNotEmpty) {
        // Router may not be set yet; delay slightly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router?.go('/article/$id');
        });
      }
    }
  }
}
