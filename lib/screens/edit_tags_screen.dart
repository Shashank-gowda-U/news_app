// lib/screens/edit_tags_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';

class EditTagsScreen extends StatefulWidget {
  final bool isInitialSetup;
  const EditTagsScreen({super.key, this.isInitialSetup = false});

  @override
  State<EditTagsScreen> createState() => _EditTagsScreenState();
}

class _EditTagsScreenState extends State<EditTagsScreen> {
  List<String> _allAvailableTags = [];
  bool _tagsAreLoading = true;
  String? _tagLoadErrorMessage;

  final Set<String> _selectedTags = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _selectedTags.addAll(user.preferredTags);
    }
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tags').get();

      final tags = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data.containsKey('name') && data['name'] is String) {
          return data['name'] as String;
        }
        return null;
      }).where((tag) => tag != null).cast<String>().toList();

      if (mounted) {
        setState(() {
          _allAvailableTags = tags;
          _tagsAreLoading = false;
        });
      }
    } catch (e, s) {
      // ignore: avoid_print
      print('Failed to load tags: $e\n$s');
      if (mounted) {
        setState(() {
          _tagsAreLoading = false;
          _tagLoadErrorMessage = "Failed to load tags. Please try again later.";
        });
      }
    }
  }

  Future<void> _saveTags() async {
    if (_selectedTags.isEmpty && widget.isInitialSetup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag to continue.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final Map<String, dynamic> dataToUpdate = {
        'preferredTags': _selectedTags.toList(),
      };

      if (widget.isInitialSetup) {
        dataToUpdate['hasSelectedInitialTags'] = true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(dataToUpdate);

      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

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
        title: Text(
            widget.isInitialSetup ? 'Select Your Interests' : 'My Preferred Tags'),
        automaticallyImplyLeading: !widget.isInitialSetup,
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
              child: Text(widget.isInitialSetup ? 'Continue' : 'Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isInitialSetup
                ? 'Choose some topics to personalize your news feed.'
                : 'Select tags you\'re interested in.'),
            const SizedBox(height: 16),
            if (_tagsAreLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tagLoadErrorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _tagLoadErrorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _tagsAreLoading = true;
                          _tagLoadErrorMessage = null;
                        });
                        _loadTags();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
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
                          if (_selectedTags.length < 9) {
                            _selectedTags.add(tag);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'You can select a maximum of 9 tags.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
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
