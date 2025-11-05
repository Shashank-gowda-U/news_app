// lib/screens/local_anchors_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
// --- NEW IMPORT ---
import 'package:news_app/widgets/location_filter_modal.dart';
// --- END NEW IMPORT ---
import 'package:news_app/widgets/local_anchor_post_card.dart';

class LocalAnchorsScreen extends StatelessWidget {
  const LocalAnchorsScreen({super.key});

  // This function now only shows the SORT filter
  void _showSortFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const FilterModal(isForLocalAnchors: true);
      },
    );
  }

  // --- NEW FUNCTION for the location modal ---
  void _showLocationFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const LocationFilterModal();
      },
    );
  }
  // --- END NEW FUNCTION ---

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local Anchors'),
          actions: [
            // --- CHANGED: onPressed calls _showLocationFilter ---
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () {
                _showLocationFilter(context);
              },
            ),
            // --- CHANGED: onPressed calls _showSortFilter ---
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showSortFilter(context);
              },
            ),
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
            // --- Tab 1: Following ---
            ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                final post = dummyLocalNews[0];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ));
                  },
                  child: LocalAnchorPostCard(post: post),
                );
              },
            ),
            // --- Tab 2: All ---
            ListView.builder(
              itemCount: dummyLocalNews.length,
              itemBuilder: (context, index) {
                final post = dummyLocalNews[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ));
                  },
                  child: LocalAnchorPostCard(post: post),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
