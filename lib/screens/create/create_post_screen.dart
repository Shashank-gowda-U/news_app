// lib/screens/create/create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/models/local_anchor_post.dart';

class CreatePostScreen extends StatefulWidget {
  final LocalAnchorPost? postToEdit;
  const CreatePostScreen({super.key, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // --- ADD YOUR CLOUDINARY DETAILS HERE ---
  final String _cloudName = "YOUR_CLOUD_NAME";
  final String _uploadPreset = "YOUR_UPLOAD_PRESET";
  // --- End of Cloudinary Details ---

  late final CloudinaryPublic _cloudinary;
  final _contentController = TextEditingController();

  List<String> _availableTags = [];
  bool _tagsAreLoading = true;

  final Set<String> _selectedTags = {};

  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
    _isEditMode = (widget.postToEdit != null);
    if (_isEditMode) {
      _contentController.text = widget.postToEdit!.content;
      _selectedTags.addAll(widget.postToEdit!.tags);
      _existingImageUrl = widget.postToEdit!.imageUrl;
    }
    _loadTags(); // Load tags from Firestore
  }

  Future<void> _loadTags() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tags').get();
      final tags = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _availableTags = tags;
        _tagsAreLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _tagsAreLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
      _existingImageUrl = null;
    });
  }

  // --- MODIFIED: This function now handles CREATE and UPDATE ---
  Future<void> _uploadPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write some content for your post.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _existingImageUrl;
      String? publicId = widget.postToEdit?.cloudinaryPublicId;

      if (_selectedImage != null) {
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedImage!.path,
              resourceType: CloudinaryResourceType.Image),
        );
        imageUrl = response.secureUrl;
        publicId = response.publicId;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) throw Exception("No user logged in.");

      final Map<String, dynamic> postData = {
        'content': _contentController.text,
        'tags': _selectedTags.toList(),
        'imageUrl': imageUrl,
        'cloudinaryPublicId': publicId,
        'publishedAt': Timestamp.now(),
        'anchorId': user.uid,
        'anchorName': user.name,
        'anchorProfilePicUrl': user.profilePicUrl,
        'location': user.location,
      };

      if (_isEditMode) {
        // --- UPDATE existing post ---
        await FirebaseFirestore.instance
            .collection('local_posts')
            .doc(widget.postToEdit!.id)
            .update(postData);
      } else {
        // --- ADD new post ---
        postData['likeCount'] = 0;
        postData['commentCount'] = 0;

        await FirebaseFirestore.instance
            .collection('local_posts')
            .add(postData);

        // Update user's total post count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'totalPosts': FieldValue.increment(1),
        });
      }

      // --- THIS IS THE FIX ---
      // 5. Refresh the AuthProvider's local user data
      if (context.mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
      // --- END OF FIX ---

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Image.file(
        File(_selectedImage!.path),
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    if (_existingImageUrl != null) {
      return Image.network(
        _existingImageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Post' : 'Create New Post'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _uploadPost,
              child: Text(_isEditMode ? 'Update' : 'Post'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s happening in your area?',
                border: InputBorder.none,
              ),
              maxLines: 8,
              autofocus: true,
            ),
            if (_selectedImage != null || _existingImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImagePreview(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                        _existingImageUrl = null;
                      }),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            const Divider(),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_selectedImage == null && _existingImageUrl == null
                  ? 'Add Image (Optional)'
                  : 'Change Image'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select tags (up to 3)'),
            ),
            const SizedBox(height: 8),
            if (_tagsAreLoading)
              const Center(child: CircularProgressIndicator())
            else
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
