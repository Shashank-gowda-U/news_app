// lib/screens/developer_news_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/dev_update.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/dev_story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class DeveloperNewsScreen extends StatefulWidget {
  const DeveloperNewsScreen({super.key});

  @override
  State<DeveloperNewsScreen> createState() => _DeveloperNewsScreenState();
}

class _DeveloperNewsScreenState extends State<DeveloperNewsScreen> {
  Future<void> _toggleFollow(String storyId, bool isCurrentlyFollowing) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      if (isCurrentlyFollowing) {
        // Unfollow
        await userRef.update({
          'followedStories': FieldValue.arrayRemove([storyId])
        });
      } else {
        // Follow
        await userRef.update({
          'followedStories': FieldValue.arrayUnion([storyId])
        });
      }
      // Refresh local state
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating follow: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    // Get the real list from Firestore
    final List<String> followedStoriesList = user?.followedStories ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Developer Updates'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Stories'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: ALL STORIES ---
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('dev_stories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No dev stories found.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final story = DevUpdateStory.fromFirestore(
                          snapshot.data!.docs[index]);

                      final isFollowed = followedStoriesList.contains(story.id);

                      return DevStoryCard(
                        story: story,
                        isFollowed: isFollowed,
                        onFollowToggle: () =>
                            _toggleFollow(story.id, isFollowed),
                      );
                    },
                  );
                }),

            // --- TAB 2: FOLLOWING ---
            if (followedStoriesList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'You aren\'t following any stories yet. \nTap "Follow" on a story in the "All Stories" tab.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('dev_stories')
                    .where(FieldPath.documentId, whereIn: followedStoriesList)
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
                        child:
                            Text('No posts found for the stories you follow.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final story = DevUpdateStory.fromFirestore(
                          snapshot.data!.docs[index]);

                      // In this tab, they are all followed
                      return DevStoryCard(
                        story: story,
                        isFollowed: true,
                        onFollowToggle: () => _toggleFollow(story.id, true),
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
