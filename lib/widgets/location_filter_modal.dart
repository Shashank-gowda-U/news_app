// lib/widgets/location_filter_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationFilterModal extends StatefulWidget {
  final Map<String, String?> currentFilters;
  const LocationFilterModal({super.key, required this.currentFilters});

  @override
  State<LocationFilterModal> createState() => _LocationFilterModalState();
}

class _LocationFilterModalState extends State<LocationFilterModal> {
  late String? _selectedState;
  late String? _selectedDistrict;

  List<String> _states = [];
  List<String> _districts = [];
  bool _isLoadingStates = true;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.currentFilters['state'];
    _selectedDistrict = widget.currentFilters['district'];
    _loadStates();
    if (_selectedState != null) {
      _loadDistricts(_selectedState!);
    }
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();
      final states = snapshot.docs.map((doc) => doc.id).toList();
      if (mounted) {
        setState(() {
          _states = states;
          _isLoadingStates = false;
        });
      }
    } catch (e, s) {
      // ignore: avoid_print
      print('Error loading states: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load states. Please try again.')),
        );
        setState(() {
          _isLoadingStates = false;
        });
      }
    }
  }

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
        if (mounted) {
          setState(() {
            _districts = districts;
          });
        }
      }
    } catch (e, s) {
      // ignore: avoid_print
      print('Error loading districts: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load districts. Please try again.')),
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

  void _applyFilters() {
    Navigator.of(context).pop<Map<String, String?>>({
      'state': _selectedState,
      'district': _selectedDistrict,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
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
                return DropdownMenuItem(value: district, child: Text(district));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                });
              },
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Apply Location'),
          ),
        ],
      ),
    );
  }
}
