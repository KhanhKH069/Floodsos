//lib/config/app_config.dart
class AppConfig {
  // App Information
  static const String appName = 'FloodSOS';
  static const String appVersion = '2.0.0';

  // API Configuration
  static const String baseUrl = 'http://192.168.1.14:3002/api';
  static const String socketUrl = 'http://192.168.1.14:3002';

  // Map Configuration
  static const double defaultLatitude = 16.4637; // Hue
  static const double defaultLongitude = 107.5909; // Hue
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
