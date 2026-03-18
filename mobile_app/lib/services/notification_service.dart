import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI in background; opening notification is handled by onMessageOpenedApp when app starts
}

/// Handles FCM: get device token, save to Firestore; foreground messages show in-app; opening navigates to article.
class NotificationService {
  NotificationService({required GlobalKey<ScaffoldMessengerState> scaffoldKey})
      : _scaffoldKey = scaffoldKey;

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey;
  GoRouter? _router;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setGoRouter(GoRouter router) {
    _router = router;
  }

  /// Request push permission, then persist FCM token only if granted (authorized or provisional).
  Future<void> saveTokenForUser(String uid) async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final status = settings.authorizationStatus;
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    final tokenId = sha256.convert(utf8.encode(token)).toString();
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(tokenId)
        .set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await saveTokenForUser(user.uid);

    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) await saveTokenForUser(u.uid);
    });

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) await saveTokenForUser(user.uid);
    });

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
