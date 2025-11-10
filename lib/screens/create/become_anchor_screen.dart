// lib/screens/create/become_anchor_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- NEW IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
// --- END OF NEW IMPORTS ---

class BecomeAnchorScreen extends StatefulWidget {
  const BecomeAnchorScreen({super.key});

  @override
  State<BecomeAnchorScreen> createState() => _BecomeAnchorScreenState();
}

class _BecomeAnchorScreenState extends State<BecomeAnchorScreen> {
  final _dobController = TextEditingController();
  final _locationController = TextEditingController(); // <-- NEW
  bool _isLoading = false; // <-- NEW

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005), // Start at 18+ years ago
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'You must be 18 or older',
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat.yMMMd().format(picked);
      });
    }
  }

  // --- NEW FUNCTION: To submit the application ---
  Future<void> _submitApplication() async {
    if (_dobController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      // Should not happen if they are logged in
      return;
    }

    try {
      // Save the application to the new collection
      await FirebaseFirestore.instance.collection('anchor_requests').add({
        'userId': user.uid,
        'userName': user.name,
        'userEmail': user.email,
        'dateOfBirth': _dobController.text,
        'location': _locationController.text,
        'status': 'pending', // You will change this to 'approved'
        'requestedAt': Timestamp.now(),
      });

      if (mounted) {
        // Show a success message and pop the screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Application submitted! Please wait for approval.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- END OF NEW FUNCTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Local Anchor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share news from your community!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Local Anchors are trusted users who share validated news and updates from their locality. To become an anchor, please confirm you are over 18.',
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                labelText: 'Your Date of Birth',
                hintText: 'Select your birthday',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController, // <-- CHANGED
              decoration: const InputDecoration(
                labelText: 'Your Location (e.g., Koramangala, Bengaluru)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // --- NEW: Loading check ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submitApplication, // <-- CHANGED
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Submit Application'),
              ),
            // --- END OF NEW ---
          ],
        ),
      ),
    );
  }
}
