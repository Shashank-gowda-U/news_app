// lib/screens/local_anchors_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/screens/search_screen.dart'; // <-- NEW IMPORT
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/location_filter_modal.dart';
import 'package:news_app/widgets/local_anchor_post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';

class LocalAnchorsScreen extends StatefulWidget {
  const LocalAnchorsScreen({super.key});

  @override
  State<LocalAnchorsScreen> createState() => _LocalAnchorsScreenState();
}

class _LocalAnchorsScreenState extends State<LocalAnchorsScreen> {
  // --- MODIFIED: Sort by Newest, no other sort options ---
  String _sortField = 'publishedAt';
  bool _sortDescending = true;
  String? _selectedDistrict;
  // --- NEW: Toggle for location filter ---
  bool _filterByLocation = true;
  // --- END OF NEW ---

  void _showLocationFilter(BuildContext context) async {
    final Map<String, String?> currentFilters = {
      // Pass the district, not the state
      'district': _selectedDistrict,
    };

    final newFilters = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // We only pass the district
        return LocationFilterModal(
            currentFilters: {'district': _selectedDistrict});
      },
    );

    if (newFilters != null) {
      setState(() {
        _selectedDistrict = newFilters['district'];
        // Always turn on location filter when a location is picked
        if (_selectedDistrict != null) {
          _filterByLocation = true;
        }
      });
    }
  }

  // --- REMOVED: _showSortFilter is removed ---

  Query _buildAllQuery() {
    Query query = FirebaseFirestore.instance.collection('local_posts');

    // --- MODIFIED: Only filter if toggle is on AND a district is selected ---
    if (_filterByLocation && _selectedDistrict != null) {
      query = query.where('location', isEqualTo: _selectedDistrict);
    }
    // --- END OF MODIFICATION ---

    query = query.orderBy(_sortField, descending: _sortDescending);
    return query;
  }

  Query _buildFollowingQuery(List<String> followedAnchors) {
    Query query = FirebaseFirestore.instance.collection('local_posts');
    query = query.where('anchorId', whereIn: followedAnchors);

    // --- MODIFIED: Also filter by location here ---
    if (_filterByLocation && _selectedDistrict != null) {
      query = query.where('location', isEqualTo: _selectedDistrict);
    }
    // --- END OF MODIFICATION ---

    query = query.orderBy(_sortField, descending: _sortDescending);
    return query;
  }

  @override
  Widget build(BuildContext context) {
    final followedAnchors =
        Provider.of<AuthProvider>(context).user?.followingAnchors ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local Anchors'),
          actions: [
            // --- NEW: Search Button ---
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ));
              },
            ),
            // --- END OF NEW ---
            IconButton(
              icon: Icon(Icons.location_on_outlined,
                  color: _filterByLocation && _selectedDistrict != null
                      ? Colors.blue
                      : null),
              onPressed: () {
                _showLocationFilter(context);
              },
            ),
            // --- NEW: "Show All" Toggle ---
            IconButton(
              icon: Icon(_filterByLocation ? Icons.public_off : Icons.public),
              tooltip: _filterByLocation
                  ? "Show All Locations"
                  : "Filter by Location",
              onPressed: () {
                setState(() {
                  _filterByLocation = !_filterByLocation;
                });
              },
            ),
            // --- END OF NEW ---
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Following'),
              Tab(text: 'All Anchors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: Following (Now with all filters) ---
            if (followedAnchors.isEmpty)
              const Center(
                child: Text('You are not following any anchors yet.'),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: _buildFollowingQuery(followedAnchors).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error. Check console for index link.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No posts found with these filters.'));
                  }
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final post =
                          LocalAnchorPost.fromFirestore(documents[index]);
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => PostDetailScreen(post: post),
                          ));
                        },
                        child: LocalAnchorPostCard(post: post),
                      );
                    },
                  );
                },
              ),

            // --- Tab 2: All (Now with all filters) ---
            StreamBuilder<QuerySnapshot>(
              stream: _buildAllQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error. Check console for index link.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No local posts found for these filters.'));
                }

                final List<DocumentSnapshot> documents = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final post =
                        LocalAnchorPost.fromFirestore(documents[index]);
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PostDetailScreen(post: post),
                        ));
                      },
                      child: LocalAnchorPostCard(post: post),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
