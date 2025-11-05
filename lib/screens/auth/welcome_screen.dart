// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/auth/login_screen.dart';
import 'package:news_app/screens/home_screen.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the auth provider
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is logged in and return the correct screen
    if (authProvider.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
