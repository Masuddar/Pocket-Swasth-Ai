import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/storage/local_db_service.dart';
import 'providers/mode_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/health_provider.dart';
import 'services/medical/medical_knowledge_sync_service.dart';
import 'screens/main_shell_screen.dart';
import 'routes/app_routes.dart';

void main() async {
  // Ensure that Flutter bindings are initialized before running service boots
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local key-value database boxes
  final localDb = LocalDbService();
  await localDb.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ModeProvider>(
          create: (_) => ModeProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider<HealthProvider>(
          create: (_) => HealthProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(),
        ),
        ChangeNotifierProvider<MedicalKnowledgeSyncService>(
          create: (_) => MedicalKnowledgeSyncService(),
        ),
      ],
      child: const PocketSwasthApp(),
    ),
  );
}

class PocketSwasthApp extends StatelessWidget {
  const PocketSwasthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Swasth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Setup Initial Entry Screen
      home: const MainShellScreen(),
      
      // Setup Dynamic App Routing
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
