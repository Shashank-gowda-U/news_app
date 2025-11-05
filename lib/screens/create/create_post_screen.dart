// lib/screens/create/create_post_screen.dart
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final List<String> _availableTags = [
    'traffic',
    'local',
    'alert',
    'community',
    'good news'
  ];
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Add logic to save post to Firebase
              Navigator.of(context).pop();
            },
            child: const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'What\'s happening in your area?',
                border: InputBorder.none,
              ),
              maxLines: 8,
              autofocus: true,
            ),
            const Divider(),
            // --- Image Upload Button ---
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Add logic to pick image from gallery
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add Image (Optional)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            // --- Tag Selection ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select tags (up to 3)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _availableTags.map((tag) {
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
