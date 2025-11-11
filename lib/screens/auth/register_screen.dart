// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/profile_pic_selector.dart';
import 'package:provider/provider.dart';
// --- NEW IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
// --- END OF NEW IMPORTS ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedProfilePic = '';
  bool _isLoading = false;

  // --- NEW: State for location dropdowns ---
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _states = [];
  List<String> _districts = [];
  bool _isLoadingStates = true;
  bool _isLoadingDistricts = false;
  // --- END OF NEW ---

  @override
  void initState() {
    super.initState();
    // Pre-select first profile pic
    _selectedProfilePic = Provider.of<AuthProvider>(context, listen: false)
        .availableProfilePics[0];
    _loadStates();
  }

  // --- NEW: Load states from Firestore ---
  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();
      final states = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      // handle error
    }
  }

  // --- NEW: Load districts for a selected state ---
  Future<void> _loadDistricts(String stateName) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(stateName)
          .get();
      final data = doc.data();
      if (data != null && data['districts'] != null) {
        final districts = List<String>.from(data['districts']);
        setState(() {
          _districts = districts;
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  void _register() async {
    if (_selectedProfilePic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture.')),
      );
      return;
    }
    // --- NEW: Check for location ---
    if (_selectedState == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location.')),
      );
      return;
    }
    // --- END OF NEW ---

    setState(() {
      _isLoading = true;
    });

    // --- MODIFIED: Pass location to the register function ---
    await Provider.of<AuthProvider>(context, listen: false).registerWithEmail(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _selectedProfilePic,
      _selectedDistrict!, // We know this is not null
    );
    // --- END OF MODIFICATION ---

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (ProfilePicSelector, Username, Email, Password fields are the same) ...
            Text(
              'Select a Profile Picture',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ProfilePicSelector(
              availablePics: authProvider.availableProfilePics,
              selectedPic: _selectedProfilePic,
              onPicSelected: (picUrl) {
                setState(() {
                  _selectedProfilePic = picUrl;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min. 6 characters)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            // --- NEW: Location Fields ---
            const SizedBox(height: 24),
            Text(
              'Select Your Location (Permanent)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _isLoadingStates
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedState,
                    hint: const Text('Select a State'),
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedState = value;
                          _selectedDistrict = null; // Reset district
                        });
                        _loadDistricts(value); // Load new districts
                      }
                    },
                  ),
            const SizedBox(height: 16),
            if (_isLoadingDistricts)
              const Center(child: CircularProgressIndicator())
            else if (_selectedState != null)
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                hint: const Text('Select a District'),
                decoration: const InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                ),
                items: _districts.map((district) {
                  return DropdownMenuItem(
                      value: district, child: Text(district));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
              ),
            // --- END OF NEW ---

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Register'),
              ),
          ],
        ),
      ),
    );
  }
}
