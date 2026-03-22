//lib/navigation/app_router.dart
import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/voice_sos_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/map_screen.dart';
import '../screens/alerts_list_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String voiceSOS = '/voice-sos';
  static const String weather = '/weather';
  static const String map = '/map';
  static const String alerts = '/alerts';
  static const String profile = '/profile';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case voiceSOS:
        return MaterialPageRoute(builder: (_) => const VoiceSOSScreen());
      case weather:
        return MaterialPageRoute(builder: (_) => const WeatherScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case alerts:
        return MaterialPageRoute(builder: (_) => const AlertsListScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
