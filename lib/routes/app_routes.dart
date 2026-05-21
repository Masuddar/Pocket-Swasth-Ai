import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
import '../screens/verify_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/report_screen.dart';
import '../screens/doctor_twin_screen.dart';

class AppRoutes {
  static const String chat = '/';
  static const String verify = '/verify';
  static const String profile = '/profile';
  static const String report = '/report';
  static const String doctorTwin = '/doctor_twin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case verify:
        return MaterialPageRoute(builder: (_) => const VerifyScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case doctorTwin:
        return MaterialPageRoute(builder: (_) => const DoctorTwinScreen());
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
