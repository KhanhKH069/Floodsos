//lib/config/app_config.dart
class AppConfig {
  // App Information
  static const String appName = 'FloodSOS';
  static const String appVersion = '2.0.0';

  // API Configuration
  static const String baseUrl = 'http://127.0.0.1:3001/api';
  static const String socketUrl = 'http://your-api-server.com';

  // Map Configuration
  static const double defaultLat = 19.3400; // Hoang Mai, Nghe An
  static const double defaultLon = 105.7100; // Hoang Mai, Nghe An
  static const double defaultZoom = 13.0;

  // Recording Configuration
  static const int maxRecordingDurationSeconds = 10;
  static const int audioSampleRate = 44100;
  static const int audioBitRate = 128000;

  // Alert Configuration
  static const int alertRefreshIntervalSeconds = 30;
  static const double criticalFloodDistanceMeters = 1000.0;

  // Emergency Numbers
  static const String policeNumber = '113';
  static const String fireNumber = '114';
  static const String ambulanceNumber = '115';
}
