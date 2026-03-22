// lib/services/firebase_service_stub.dart
import 'package:flutter/material.dart';

class FirebaseService {
  static const bool isSupported = false;

  static Future<void> initialize() async {
    debugPrint('🖥️ Firebase disabled on Desktop');
  }

  static dynamic get firestore {
    throw UnsupportedError('Firestore not available on Desktop');
  }

  static Future<void> saveSOS(String docId, Map<String, dynamic> data) async {
    debugPrint('⚠️ Desktop mode: Skipping Firestore save');
    // TODO: Save to local database instead
  }

  static Stream<dynamic>? sosStream(String docId) {
    debugPrint('⚠️ Desktop mode: No Firestore stream');
    return null;
  }

  static Map<String, double> createGeoPoint(double lat, double lng) {
    return {'latitude': lat, 'longitude': lng};
  }
}
