// lib/screens/create/create_post_screen.dart
import 'dart.io'; // <-- NEW IMPORT
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- NEW IMPORT
import 'package:cloudinary_public/cloudinary_public.dart'; // <-- NEW IMPORT
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- NEW IMPORT
import 'package:provider/provider.dart'; // <-- NEW IMPORT
import 'package:news_app/providers/auth_provider.dart'; // <-- NEW IMPORT

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // --- ADD YOUR CLOUDINARY DETAILS HERE ---
  // (Find these on your Cloudinary Dashboard)
  final String _cloudName = "dpnbaiwbw";
  final String _uploadPreset = "news";
  // For signed uploads (more secure, but requires backend)
  // final String _apiKey = "YOUR_API_KEY";
  // final String _apiSecret = "YOUR_API_SECRET";

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

  XFile? _selectedImage; // This will hold the image file
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  // Function to upload the post
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
      String? imageUrl;
      String? publicId;

      // 1. Upload image to Cloudinary (if one was selected)
      if (_selectedImage != null) {
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

      if (user == null) {
        throw Exception("No user logged in.");
      }

      // 3. Save post data to Firestore
      await FirebaseFirestore.instance.collection('local_posts').add({
        'content': _contentController.text,
        'tags': _selectedTags.toList(),
        'imageUrl': imageUrl, // This will be null if no image was picked
        'cloudinaryPublicId': publicId, // Good to save this for future deletes
        'publishedAt': Timestamp.now(), // Use server timestamp
        'anchorId': user.uid,
        'anchorName': user.name,
        'anchorProfilePicUrl': user.profilePicUrl,
        'location': user.location,
        'likeCount': 0,
        'commentCount': 0,
      });

      // 4. Update user's total post count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'totalPosts': FieldValue.increment(1),
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        actions: [
          // Show a loading spinner or the Post button
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
              child: const Text('Post'),
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

            // --- NEW: Image Preview ---
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
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
            // --- END OF PREVIEW ---

            const Divider(),
            OutlinedButton.icon(
              onPressed: _pickImage, // Call our new function
              icon: const Icon(Icons.image_outlined),
              label: Text(_selectedImage == null
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
