// lib/screens/local_anchors_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/location_filter_modal.dart';
import 'package:news_app/widgets/local_anchor_post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
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
    // --- NEW: Get the list of followed anchors from our provider ---
    final followedAnchors =
        Provider.of<AuthProvider>(context).user?.followingAnchors ?? [];
    // --- END OF NEW ---

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
            // --- Tab 1: Following (NOW LIVE) ---
            if (followedAnchors.isEmpty)
              const Center(
                child: Text('You are not following any anchors yet.'),
              )
            else
              StreamBuilder<QuerySnapshot>(
                // Query for posts WHERE the 'anchorId' is IN our list
                stream: FirebaseFirestore.instance
                    .collection('local_posts')
                    .where('anchorId', whereIn: followedAnchors)
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
                    return const Center(
                        child: Text('No posts from the anchors you follow.'));
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

            // --- Tab 2: All (Already live) ---
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
