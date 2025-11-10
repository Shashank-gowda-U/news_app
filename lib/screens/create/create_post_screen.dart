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
  // --- NEW: Accept an optional post to edit ---
  final LocalAnchorPost? postToEdit;
  const CreatePostScreen({super.key, this.postToEdit});
  // --- END OF NEW ---

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
  final List<String> _availableTags = [
    'traffic',
    'local',
    'alert',
    'community',
    'good news',
    'event'
  ];
  final Set<String> _selectedTags = {};

  XFile? _selectedImage; // This will hold a NEWLY picked image file
  String? _existingImageUrl; // This will hold the URL of an existing image
  bool _isLoading = false;
  late bool _isEditMode; // To check if we are creating or editing

  @override
  void initState() {
    super.initState();
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

    // --- NEW: Check if we are in Edit Mode ---
    _isEditMode = (widget.postToEdit != null);
    if (_isEditMode) {
      // Pre-fill all the fields from the post we're editing
      _contentController.text = widget.postToEdit!.content;
      _selectedTags.addAll(widget.postToEdit!.tags);
      _existingImageUrl = widget.postToEdit!.imageUrl;
    }
    // --- END OF NEW ---
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image; // User picked a new image
      _existingImageUrl = null; // Remove the old image preview
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
      String? imageUrl = _existingImageUrl; // Start with the old image URL
      String? publicId = widget.postToEdit?.cloudinaryPublicId;

      // 1. Upload new image IF the user picked one
      if (_selectedImage != null) {
        // --- ERROR WAS HERE ---
        // We will NOT attempt to delete the old file.
        // It will just become an "orphan" in Cloudinary.
        // --- END OF FIX ---

        // Now, upload the new one
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedImage!.path,
              resourceType: CloudinaryResourceType.Image),
        );
        imageUrl = response.secureUrl;
        publicId = response.publicId;
      }

      // 2. Get current user details
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) throw Exception("No user logged in.");

      // 3. Prepare the data map
      final Map<String, dynamic> postData = {
        'content': _contentController.text,
        'tags': _selectedTags.toList(),
        'imageUrl': imageUrl,
        'cloudinaryPublicId': publicId,
        'publishedAt': Timestamp.now(), // Always update timestamp on edit
        'anchorId': user.uid,
        'anchorName': user.name,
        'anchorProfilePicUrl': user.profilePicUrl,
        'location': user.location,
        // We don't reset counts on edit
      };

      // 4. Save to Firestore (Update or Add)
      if (_isEditMode) {
        // --- UPDATE existing post ---
        await FirebaseFirestore.instance
            .collection('local_posts')
            .doc(widget.postToEdit!.id)
            .update(postData);
      } else {
        // --- ADD new post ---
        // Add counts only for new posts
        postData['likeCount'] = 0;
        postData['commentCount'] = 0;

        await FirebaseFirestore.instance
            .collection('local_posts')
            .add(postData);

        // Update user's total post count only when creating
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'totalPosts': FieldValue.increment(1),
        });
      }

      if (mounted) {
        Navigator.of(context).pop(); // Go back after success
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

  // --- NEW: Helper to show the image preview ---
  Widget _buildImagePreview() {
    // Case 1: User just picked a new image
    if (_selectedImage != null) {
      return Image.file(
        File(_selectedImage!.path),
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    // Case 2: We are editing and there's an existing image
    if (_existingImageUrl != null) {
      return Image.network(
        _existingImageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    // Case 3: No image
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

            // --- MODIFIED: Image Preview Section ---
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
            // --- END OF MODIFIED SECTION ---

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
