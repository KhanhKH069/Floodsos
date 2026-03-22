import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sos_model.dart';
import 'firebase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  // Kiểm tra xem thiết bị có hỗ trợ Firebase Messaging không
  // Windows hiện chưa được hỗ trợ chính thức bởi plugin này
  bool get _isSupported =>
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<void> initialize(String currentUserId) async {
    if (_isInitialized) return;

    // Nếu đang chạy trên Windows, bỏ qua việc khởi tạo Messaging
    if (!_isSupported) {
      debugPrint(
          '🖥️ Desktop Mode: Notification Service disabled (Windows detected)');
      _isInitialized = true;
      return;
    }

    try {
      final fcm = FirebaseMessaging.instance;

      // Xin quyền thông báo
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Lấy token
        String? token = await fcm.getToken();
        if (token != null) {
          await _saveTokenToFirestore(currentUserId, token);
        }

        // Lắng nghe tin nhắn khi app đang mở
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📱 Foreground message: ${message.data}');
          if (message.notification != null) {
            debugPrint('Notification: ${message.notification!.title}');
          }
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Notification init failed: $e');
      // Không throw lỗi để app vẫn chạy tiếp được
      _isInitialized = true;
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    if (!FirebaseService.isSupported) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      debugPrint('✅ FCM Token saved');
    } catch (e) {
      debugPrint('⚠️ Save token failed: $e');
    }
  }

  Future<void> simulateStatusChange(String sosId, SOSStatus newStatus) async {
    if (!FirebaseService.isSupported) {
      debugPrint('⚠️ Desktop mode: Cannot update Firestore');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(sosId)
          .update({
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
