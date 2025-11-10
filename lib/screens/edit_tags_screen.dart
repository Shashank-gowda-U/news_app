// lib/screens/edit_tags_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';

class EditTagsScreen extends StatefulWidget {
  const EditTagsScreen({super.key});

  @override
  State<EditTagsScreen> createState() => _EditTagsScreenState();
}

class _EditTagsScreenState extends State<EditTagsScreen> {
  // --- MODIFIED ---
  List<String> _allAvailableTags = [];
  bool _tagsAreLoading = true;
  // --- END ---

  final Set<String> _selectedTags = {};
  bool _isLoading = false; // For saving

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _selectedTags.addAll(user.preferredTags);
    }
    _loadTags(); // Load tags from Firestore
  }

  // --- MODIFIED: This function is now correct ---
  Future<void> _loadTags() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tags').get();
      // FIX 1: Added .docs before .map
      // FIX 2: Added 'as String' to be safe
      final tags = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _allAvailableTags = tags;
        _tagsAreLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _tagsAreLoading = false;
      });
    }
  }
  // --- END OF MODIFICATION ---

  Future<void> _saveTags() async {
    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'preferredTags': _selectedTags.toList()});

      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save tags: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preferred Tags'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _saveTags,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select tags you\'re interested in.'),
            const SizedBox(height: 16),
            if (_tagsAreLoading)
              const Center(child: CircularProgressIndicator())
            else
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
