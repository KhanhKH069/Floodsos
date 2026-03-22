// lib/services/firebase_service_mobile.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static const bool isSupported = true;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized (Mobile/Web)');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Firebase init failed: $e');
      _initialized = true;
    }
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> saveSOS(String docId, Map<String, dynamic> data) async {
    try {
      await firestore.collection('sos_alerts').doc(docId).set(data);
    } catch (e) {
      debugPrint('Error saving SOS: $e');
      rethrow;
    }
  }

  static Stream<DocumentSnapshot>? sosStream(String docId) {
    try {
      return firestore.collection('sos_alerts').doc(docId).snapshots();
    } catch (e) {
      debugPrint('Error streaming SOS: $e');
      return null;
    }
  }

  static GeoPoint createGeoPoint(double lat, double lng) {
    return GeoPoint(lat, lng);
  }
}
