// lib/main.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/auth/welcome_screen.dart';
import 'package:news_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    // We use MultiProvider to provide both Theme and Auth state
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
      // --- CHANGE HERE: The app now starts at the WelcomeScreen ---
      home: const WelcomeScreen(),
      // --- END OF CHANGE ---
      debugShowCheckedModeBanner: false,
    );
  }
}
