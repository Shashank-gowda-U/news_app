// lib/screens/edit_tags_screen.dart
import 'package:flutter/material.dart';

class EditTagsScreen extends StatefulWidget {
  const EditTagsScreen({super.key});

  @override
  State<EditTagsScreen> createState() => _EditTagsScreenState();
}

class _EditTagsScreenState extends State<EditTagsScreen> {
  // Dummy data. Later, this will come from Firebase/Provider
  final List<String> _allAvailableTags = [
    'sports',
    'science',
    'technology',
    'politics',
    'world',
    'finance',
    'energy',
    'social',
    'health',
    'entertainment',
    'local',
  ];

  final Set<String> _selectedTags = {
    'science',
    'technology'
  }; // Dummy pre-selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preferred Tags'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save _selectedTags to Firebase/Provider
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select up to 10 tags you\'re interested in.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _allAvailableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
