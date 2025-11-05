// lib/screens/create/become_anchor_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BecomeAnchorScreen extends StatefulWidget {
  const BecomeAnchorScreen({super.key});

  @override
  State<BecomeAnchorScreen> createState() => _BecomeAnchorScreenState();
}

class _BecomeAnchorScreenState extends State<BecomeAnchorScreen> {
  final _dobController = TextEditingController();

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
            const TextField(
              decoration: InputDecoration(
                labelText: 'Your Location (e.g., Koramangala, Bengaluru)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Add logic to submit application
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }
}
