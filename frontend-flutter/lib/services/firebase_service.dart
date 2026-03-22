// lib/services/firebase_service.dart
// Export conditional implementation
export 'firebase_service_stub.dart'
    if (dart.library.io) 'firebase_service_mobile.dart'
    if (dart.library.html) 'firebase_service_mobile.dart';
