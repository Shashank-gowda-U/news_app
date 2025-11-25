import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';

class BecomeAnchorScreen extends StatefulWidget {
  const BecomeAnchorScreen({super.key});

  @override
  State<BecomeAnchorScreen> createState() => _BecomeAnchorScreenState();
}

class _BecomeAnchorScreenState extends State<BecomeAnchorScreen> {
  final _dobController = TextEditingController();

  // Location State
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _districts = [];
  bool _isLoadingDistricts = false;
  bool _isLoading = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'You must be 18 or older',
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat.yMMMd().format(picked);
      });
    }
  }

  // Fetch districts when a state is selected
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

  Future<void> _submitApplication() async {
    if (_dobController.text.isEmpty ||
        _selectedState == null ||
        _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    // Format Location consistently: "District, State"
    final String finalLocation = "$_selectedDistrict, $_selectedState";

    try {
      await FirebaseFirestore.instance.collection('anchor_requests').add({
        'userId': user.uid,
        'userName': user.name,
        'userEmail': user.email,
        'dateOfBirth': _dobController.text,
        'location': finalLocation, // Saved from dropdowns
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Application submitted! Please wait for approval.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Local Anchor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share news from your community!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Local Anchors are trusted users who share validated news and updates from their locality. To become an anchor, please confirm you are over 18.',
            ),
            const SizedBox(height: 32),

            // Date of Birth Field
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                labelText: 'Your Date of Birth',
                hintText: 'Select your birthday',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Location Dropdowns
            const Text("Your Location",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('locations').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading locations.');
                }

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
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      hint: const Text('Select District'),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: _districts
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDistrict = val),
                    ),

            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submitApplication,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Submit Application'),
              ),
          ],
        ),
      ),
    );
  }
}
