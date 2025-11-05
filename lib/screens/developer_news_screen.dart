// lib/screens/developer_news_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ← ADDED THIS
import 'package:news_app/models/dev_update.dart';
import 'package:news_app/widgets/dev_story_card.dart';

class DeveloperNewsScreen extends StatefulWidget {
  const DeveloperNewsScreen({super.key});

  @override
  State<DeveloperNewsScreen> createState() => _DeveloperNewsScreenState();
}

class _DeveloperNewsScreenState extends State<DeveloperNewsScreen> {
  // We need to manage the "followed" state here.
  // This is a dummy set of IDs. Later, this will come from the user's profile.
  final Set<String> _followedStories = {
    'story2'
  }; // Following 'App Development' by default

  void _toggleFollow(String storyId) {
    setState(() {
      if (_followedStories.contains(storyId)) {
        _followedStories.remove(storyId);
      } else {
        _followedStories.add(storyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get a list of all posts from followed stories and sort them by date
    final List<DevUpdatePost> followedPosts = dummyDevUpdates
        .where((story) => _followedStories.contains(story.id))
        .expand(
            (story) => story.posts) // Get all posts from all followed stories
        .toList();

    // Sort them so the newest is first
    followedPosts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

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
            // --- Tab 1: All Stories ---
            // Shows the expandable list of all available stories
            ListView.builder(
              itemCount: dummyDevUpdates.length,
              itemBuilder: (context, index) {
                final story = dummyDevUpdates[index];
                return DevStoryCard(
                  story: story,
                  isFollowed: _followedStories.contains(story.id),
                  onFollowToggle: () => _toggleFollow(story.id),
                );
              },
            ),

            // --- Tab 2: Following ---
            // Shows a single feed of posts ONLY from followed stories
            followedPosts.isEmpty
                ? const Center(
                    child: Text('You aren\'t following any stories yet.'),
                  )
                : ListView.builder(
                    itemCount: followedPosts.length,
                    itemBuilder: (context, index) {
                      final post = followedPosts[index];
                      // We can reuse the DevStoryCard's inner list tile style
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                DateFormat.yMMMd()
                                    .add_jm()
                                    .format(post.publishedAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(post.content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
