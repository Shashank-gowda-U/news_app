// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/auth/welcome_screen.dart';
import 'package:news_app/screens/edit_tags_screen.dart';
import 'package:news_app/screens/home_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;

    if (authProvider.isLoggedIn) {
      if (authProvider.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load user data.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => authProvider.retryLoadUser(),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        );
      }

      if (user != null) {
        // If user is logged in and we have their data
        if (user.hasSelectedInitialTags) {
          // If they have selected tags, show the main app
          return const HomeScreen();
        } else {
          // If they haven't, force them to the EditTagsScreen
          return const EditTagsScreen(isInitialSetup: true);
        }
      } else {
        // If user is logged in but we don't have their data yet (loading state)
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      // If user is not logged in, show the welcome screen
      return const WelcomeScreen();
    }
  }
}
