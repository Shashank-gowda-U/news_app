// lib/widgets/filter_modal.dart
import 'package:flutter/material.dart';
// We no longer need cloud_firestore here

class FilterModal extends StatefulWidget {
  final bool isForLocalAnchors;
  final Map<String, dynamic> currentFilters;

  const FilterModal({
    super.key,
    required this.isForLocalAnchors,
    required this.currentFilters,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _selectedSort;
  late String? _selectedMood;
  // We no longer need _selectedTag, _allTags, or _tagsAreLoading

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentFilters['sortField'] == 'publishedAt'
        ? (widget.currentFilters['sortDescending'] ? 'newest' : 'oldest')
        : 'valid';

    _selectedMood = widget.currentFilters['selectedMood'];
    // No need to load tags anymore
  }

  void _applyFilters() {
    String sortField = 'publishedAt';
    bool sortDescending = true;

    if (_selectedSort == 'oldest') {
      sortField = 'publishedAt';
      sortDescending = false;
    } else if (_selectedSort == 'valid') {
      sortField = 'trueVotes'; // Sort by trueVotes
      sortDescending = true;
    }

    // Return the new values
    Navigator.of(context).pop({
      'sortField': sortField,
      'sortDescending': sortDescending,
      'selectedMood': _selectedMood,
      'selectedTag': null, // We no longer use this, so we return null
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            if (!widget.isForLocalAnchors) ...[
              const Divider(height: 32),
              Text(
                'Filter by Mood',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Wrap(
                spacing: 8.0,
                children: ['uplifting', 'neutral', 'bad_news'].map((mood) {
                  // Renamed to avoid conflicts
                  final moodValue = mood == 'bad_news' ? 'bad news' : mood;
                  return FilterChip(
                    label: Text(moodValue),
                    selected: _selectedMood == moodValue,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMood = selected ? moodValue : null;
                      });
                    },
                  );
                }).toList(),
              ),

              // --- "FILTER BY TAG" SECTION HAS BEEN REMOVED ---
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _applyFilters,
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
