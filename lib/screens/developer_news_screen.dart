// lib/screens/developer_news_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/dev_update.dart';
import 'package:news_app/widgets/dev_story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Note: We don't need the AuthProvider here *yet*
// We will add it when we save the "followed stories" to the user's profile.

class DeveloperNewsScreen extends StatefulWidget {
  const DeveloperNewsScreen({super.key});

  @override
  State<DeveloperNewsScreen> createState() => _DeveloperNewsScreenState();
}

class _DeveloperNewsScreenState extends State<DeveloperNewsScreen> {
  // This is a temporary list to track what the user follows.
  // In our next step, we will move this into the user's
  // profile in Firestore.
  // I've added the document ID for the "App Development Log" you created.
  final Set<String> _followedStories = {
    'YOUR_APP_LOG_DOCUMENT_ID'
  }; // <-- TODO: Replace this with a real ID from your 'dev_stories' collection

  void _toggleFollow(String storyId) {
    setState(() {
      if (_followedStories.contains(storyId)) {
        _followedStories.remove(storyId);
      } else {
        _followedStories.add(storyId);
      }
    });
    // TODO: Save this change to Firestore
  }

  @override
  Widget build(BuildContext context) {
    // We create a list from the set to use in our query
    final followedStoriesList = _followedStories.toList();

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
            // --- Tab 1: All Stories (Reads all dev_stories) ---
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
                      return DevStoryCard(
                        story: story,
                        isFollowed: _followedStories.contains(story.id),
                        onFollowToggle: () => _toggleFollow(story.id),
                      );
                    },
                  );
                }),

            // --- Tab 2: Following (NOW LIVE AND CORRECTED) ---
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
              // This StreamBuilder reads *only* the stories you follow
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
                      return DevStoryCard(
                        story: story,
                        isFollowed: true, // We know this is true
                        onFollowToggle: () => _toggleFollow(story.id),
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
