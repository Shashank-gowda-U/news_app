// lib/widgets/location_filter_modal.dart
import 'package:flutter/material.dart';

class LocationFilterModal extends StatefulWidget {
  const LocationFilterModal({super.key});

  @override
  State<LocationFilterModal> createState() => _LocationFilterModalState();
}

class _LocationFilterModalState extends State<LocationFilterModal> {
  String? _selectedState = 'Karnataka';
  String? _selectedDistrict = 'Bengaluru Urban';

  // Dummy data for locations
  final List<String> _states = ['Karnataka', 'Tamil Nadu', 'Maharashtra'];
  final Map<String, List<String>> _districts = {
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: const InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(),
            ),
            items: _states.map((state) {
              return DropdownMenuItem(value: state, child: Text(state));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _selectedDistrict = null; // Reset district
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedState != null)
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              items: _districts[_selectedState!]?.map((district) {
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
            onPressed: () {
              // TODO: Add logic to apply location filter
              Navigator.of(context).pop();
            },
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
