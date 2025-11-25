import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CreatePostScreen extends StatefulWidget {
  final LocalAnchorPost? postToEdit;
  const CreatePostScreen({super.key, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // --- CONFIGURATION ---
  // TODO: Replace with your actual Cloudinary credentials
  final String _cloudName = "";
  final String _uploadPreset = "";

  // TODO: Replace with your actual Gemini API Key
  final String _geminiApiKey = "";

  late final CloudinaryPublic _cloudinary;
  final _contentController = TextEditingController();

  List<String> _availableTags = [];
  bool _tagsAreLoading = true;
  final Set<String> _selectedTags = {};

  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  late bool _isEditMode;

  // Location State
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _districts = [];
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
    _isEditMode = (widget.postToEdit != null);

    if (_isEditMode) {
      _contentController.text = widget.postToEdit!.content;
      _selectedTags.addAll(widget.postToEdit!.tags);
      _existingImageUrl = widget.postToEdit!.imageUrl;
      // Note: For editing, we aren't parsing the old "State, District" string back into dropdowns
      // for simplicity. The user will need to re-select location if they want to change it.
    }
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tags').get();

      // Handle cases where the 'name' field might be missing or not a string
      final tags = snapshot.docs
          .map((doc) => doc.data()['name'])
          .where((name) => name != null && name is String)
          .cast<String>()
          .toList();

      if (mounted) {
        setState(() {
          _availableTags = tags;
          _tagsAreLoading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error loading tags: $e");
      if (mounted) {
        setState(() {
          _tagsAreLoading = false;
        });
      }
    }
  }

  Future<void> _onStateSelected(String stateName) async {
    setState(() {
      _selectedState = stateName;
      _selectedDistrict = null;
      _isLoadingDistricts = true;
      _districts = [];
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(stateName)
          .get();
      final data = doc.data();
      if (mounted && data != null && data['districts'] != null) {
        setState(() {
          _districts = List<String>.from(data['districts']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load districts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<bool> _analyzeContentSafety(String content) async {
    if (_geminiApiKey == "YOUR_GEMINI_API_KEY") {
      // Bypass check if key is not set yet, so you can test UI
      return true;
    }

    try {
      final model =
          GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiApiKey);
      final prompt = '''
        You are a content moderator. Analyze this text for:
        1. Hate speech / Violence
        2. Explicit content
        3. Dangerous misinformation
        
        Text: "$content"
        
        Return valid JSON only: {"safe": boolean}
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Simple string check for JSON response
      if (text.contains('"safe": true')) return true;
      if (text.contains('"safe": false')) return false;

      // Default to safe if response is weird
      return true;
    } catch (e) {
      // Fail open (allow post) if API fails to avoid blocking user during outages
      return true;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some content.')),
      );
      return;
    }

    // Validation: Ensure Location is selected (unless editing and keeping old)
    if (!_isEditMode && (_selectedState == null || _selectedDistrict == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. AI Safety Check
    bool isSafe = await _analyzeContentSafety(_contentController.text);
    if (!isSafe) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Content Warning'),
            content: const Text(
                'Our AI system flagged this post as potentially unsafe or harmful. Please revise your content.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
      return;
    }

    try {
      String? imageUrl = _existingImageUrl;
      String? publicId = widget.postToEdit?.cloudinaryPublicId;

      // 2. Image Upload
      if (_selectedImage != null) {
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedImage!.path,
              resourceType: CloudinaryResourceType.Image),
        );
        imageUrl = response.secureUrl;
        publicId = response.publicId;
      }

      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) throw Exception("No user logged in.");

      // Use new selection if made, otherwise fallback (mostly for edit mode logic)
      String finalLocation;
      if (_selectedState != null && _selectedDistrict != null) {
        finalLocation = "$_selectedDistrict, $_selectedState";
      } else if (_isEditMode) {
        finalLocation = widget.postToEdit!.location;
      } else {
        finalLocation = "Unknown";
      }

      final Map<String, dynamic> postData = {
        'content': _contentController.text,
        'tags': _selectedTags.toList(),
        'imageUrl': imageUrl,
        'cloudinaryPublicId': publicId,
        'publishedAt': Timestamp.now(),
        'anchorId': user.uid,
        'anchorName': user.name,
        'anchorProfilePicUrl': user.profilePicUrl,
        'location': finalLocation,
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('local_posts')
            .doc(widget.postToEdit!.id)
            .update(postData);
      } else {
        // New Post Defaults
        postData['likeCount'] = 0;
        postData['commentCount'] = 0;
        postData['trueVotes'] = 0;
        postData['falseVotes'] = 0;

        await FirebaseFirestore.instance
            .collection('local_posts')
            .add(postData);

        // Increment user post count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'totalPosts': FieldValue.increment(1),
        });
      }

      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Image.file(File(_selectedImage!.path),
          width: double.infinity, height: 200, fit: BoxFit.cover);
    }
    if (_existingImageUrl != null) {
      return Image.network(_existingImageUrl!,
          width: double.infinity, height: 200, fit: BoxFit.cover);
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
                    width: 24, height: 24, child: CircularProgressIndicator()))
          else
            TextButton(
                onPressed: _uploadPost,
                child: Text(_isEditMode ? 'Update' : 'Post')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s happening in your area?',
                border: InputBorder.none,
              ),
              maxLines: 6,
            ),

            const SizedBox(height: 16),

            if (_selectedImage != null || _existingImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImagePreview()),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                        _existingImageUrl = null;
                      }),
                      child: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, color: Colors.white)),
                    ),
                  ),
                ],
              ),

            const Divider(height: 32),

            // Location Dropdowns
            if (!_isEditMode) ...[
              const Text("Location",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance.collection('locations').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final states = snapshot.data!.docs.map((d) => d.id).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedState,
                    hint: const Text('Select State'),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: states
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => _onStateSelected(val!),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedState != null)
                _isLoadingDistricts
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        hint: const Text('Select District'),
                        decoration:
                            const InputDecoration(border: OutlineInputBorder()),
                        items: _districts
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDistrict = val),
                      ),
              const SizedBox(height: 24),
            ],

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Add Image'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),

            const SizedBox(height: 24),
            const Text('Select Tags (Max 3)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_tagsAreLoading)
              const Center(child: CircularProgressIndicator())
            else if (_availableTags.isEmpty)
              const Text("No tags available.")
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
                          if (_selectedTags.length < 3) {
                            _selectedTags.add(tag);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'You can only select up to 3 tags.')));
                          }
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }
}
