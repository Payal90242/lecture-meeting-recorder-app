import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/notes_provider.dart';
import 'providers/recorder_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/revenuecat_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SQLite database
  await DatabaseService().database;

  // Initialize RevenueCat SDK
  await RevenueCatService().init();

  runApp(const EchoGeminiApp());
}

class EchoGeminiApp extends StatelessWidget {
  const EchoGeminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => RecorderProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'EchoGemini AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to sleek modern dark theme
        home: const HomeScreen(),
      ),
    );
  }
}
