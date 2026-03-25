import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/permission_screen.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // AdMob é inicializado no PermissionScreen com consentimento GDPR
  runApp(const InstaCleanApp());
}

class InstaCleanApp extends StatelessWidget {
  const InstaCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaClean PMC',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService().observer],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00BCD4),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const PermissionScreen(),
    );
  }
}
