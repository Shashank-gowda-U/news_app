// lib/widgets/filter_modal.dart
import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final bool isForLocalAnchors;
  const FilterModal({super.key, required this.isForLocalAnchors});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String _selectedSort = 'newest';
  String _selectedMood = 'all'; // For the new emotional filter

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Added padding for the safe area (like the phone's notch)
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewPadding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            RadioListTile(
              title: const Text('Newest'),
              value: 'newest',
              groupValue: _selectedSort,
              onChanged: (val) => setState(() => _selectedSort = val!),
            ),
            RadioListTile(
              title: const Text('Oldest'),
              value: 'oldest',
              groupValue: _selectedSort,
              onChanged: (val) => setState(() => _selectedSort = val!),
            ),
            if (!widget.isForLocalAnchors)
              RadioListTile(
                title: const Text('Most Valid (Highest True %)'),
                value: 'valid',
                groupValue: _selectedSort,
                onChanged: (val) => setState(() => _selectedSort = val!),
              ),

            // --- NEW: Emotional/Mood Filter ---
            // This section only shows if it's for Global News
            if (!widget.isForLocalAnchors) ...[
              const Divider(height: 32),
              Text(
                'Filter by Mood',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              RadioListTile(
                title: const Text('All News'),
                value: 'all',
                groupValue: _selectedMood,
                onChanged: (val) => setState(() => _selectedMood = val!),
              ),
              RadioListTile(
                title: const Text('Uplifting News'),
                value: 'uplifting',
                groupValue: _selectedMood,
                onChanged: (val) => setState(() => _selectedMood = val!),
              ),
              RadioListTile(
                title: const Text('Neutral News'),
                value: 'neutral',
                groupValue: _selectedMood,
                onChanged: (val) => setState(() => _selectedMood = val!),
              ),
              RadioListTile(
                title: const Text('Bad News'),
                value: 'bad_news',
                groupValue: _selectedMood,
                onChanged: (val) => setState(() => _selectedMood = val!),
              ),
            ],
            // --- END OF NEW SECTION ---

            // --- REMOVED: Location filter section is gone ---

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add logic to apply filters
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
