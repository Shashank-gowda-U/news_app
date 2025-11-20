import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // State for location dropdowns
  String? _selectedState;
  String? _selectedDistrict;

  List<String> _districts = [];
  bool _isLoadingDistricts = false;

  // Fetches districts for the selected state
  Future<void> _onStateSelected(String stateName) async {
    setState(() {
      _selectedState = stateName;
      _selectedDistrict = null; // Reset district
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
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  void _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    if (_selectedState == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).registerWithEmail(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _selectedDistrict!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
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
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            Text(
              'Select Your Location (Permanent)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // State Dropdown
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('locations').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Failed to load states.');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No locations configured.');
                }
                
                final states = snapshot.data!.docs.map((doc) => doc.id).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedState,
                  hint: const Text('Select a State'),
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  items: states.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onStateSelected(value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // District Dropdown
            if (_selectedState != null)
              _isLoadingDistricts
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
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
