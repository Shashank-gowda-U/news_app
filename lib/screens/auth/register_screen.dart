// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/profile_pic_selector.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Logan');
  final _emailController = TextEditingController(text: 'logan@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  String _selectedProfilePic = '';

  void _register() {
    if (_selectedProfilePic.isEmpty) {
      // Show an error if no profile pic is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture.')),
      );
      return;
    }

    Provider.of<AuthProvider>(context, listen: false).register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _selectedProfilePic,
    );

    // Pop back to the login screen, which will then redirect to home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Set default selected pic
    if (_selectedProfilePic.isEmpty) {
      _selectedProfilePic = authProvider.availableProfilePics[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Profile Picture',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ProfilePicSelector(
              availablePics: authProvider.availableProfilePics,
              selectedPic: _selectedProfilePic,
              onPicSelected: (picUrl) {
                setState(() {
                  _selectedProfilePic = picUrl;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
