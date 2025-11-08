// lib/screens/local_anchors_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/location_filter_modal.dart';
import 'package:news_app/widgets/local_anchor_post_card.dart';

// --- NEW IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
// --- END OF NEW IMPORTS ---

class LocalAnchorsScreen extends StatelessWidget {
  const LocalAnchorsScreen({super.key});

  void _showSortFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const FilterModal(isForLocalAnchors: true);
      },
    );
  }

  void _showLocationFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const LocationFilterModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local Anchors'),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () {
                _showLocationFilter(context);
              },
            ),
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
            // --- Tab 1: Following (Still dummy data) ---
            ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                final post = dummyLocalNews[0]; // Just Jane
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

            // --- Tab 2: All (NOW LIVE) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('local_posts')
                  .orderBy('publishedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No local posts found.'));
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
