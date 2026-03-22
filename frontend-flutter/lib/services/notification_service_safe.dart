// lib/services/notification_service_safe.dart
// Cách tiếp cận ĐƠN GIẢN và AN TOÀN nhất

import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import 'firebase_service.dart';

// Chỉ import khi platform hỗ trợ
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.io) 'package:firebase_messaging/firebase_messaging.dart';

import 'package:cloud_firestore/cloud_firestore.dart'
    if (dart.library.html) 'package:cloud_firestore/cloud_firestore.dart'
    if (dart.library.io) 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize(String currentUserId) async {
    if (_isInitialized) return;

    if (!FirebaseService.isSupported) {
      debugPrint('🖥️ Notifications disabled on Desktop');
      _isInitialized = true;
      return;
    }

    try {
      final fcm = FirebaseMessaging.instance;
      final firestore = FirebaseFirestore.instance;

      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await fcm.getToken();
        if (token != null) {
          await firestore.collection('users').doc(currentUserId).update({
            'fcmToken': token,
          });
          debugPrint('✅ FCM Token saved');
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📱 Foreground message: ${message.data}');
          if (message.notification != null) {
            debugPrint('Notification: ${message.notification}');
          }
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Notification init failed: $e');
      _isInitialized = true;
    }
  }

  Future<void> simulateStatusChange(String sosId, SOSStatus newStatus) async {
    if (!FirebaseService.isSupported) {
      debugPrint('⚠️ Desktop mode: Cannot update Firestore');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('sos_alerts').doc(sosId).update({
        'status': newStatus.name,
        'history': FieldValue.arrayUnion([
          {
            'status': newStatus.name,
            'timestamp': DateTime.now().toIso8601String(),
            'note': 'Cập nhật tự động'
          }
        ])
      });
    } catch (e) {
      debugPrint('Error updating SOS: $e');
    }
  }
}
