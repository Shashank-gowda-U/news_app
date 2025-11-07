// lib/main.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/auth/welcome_screen.dart';
import 'package:news_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// --- NEW IMPORTS ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// --- END OF NEW IMPORTS ---

void main() async {
  // --- NEW: Ensure Flutter is ready ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- NEW: Initialize Firebase ---
  // This line connects to your Firebase project using the
  // lib/firebase_options.dart file that was generated.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // --- END OF NEW ---

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'News App',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
