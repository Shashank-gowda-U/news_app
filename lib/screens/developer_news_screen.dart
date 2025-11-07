// lib/screens/developer_news_screen.dart
import 'package:flutter/material.dart';

import 'package:news_app/models/dev_update.dart';
import 'package:news_app/widgets/dev_story_card.dart';

class DeveloperNewsScreen extends StatefulWidget {
  const DeveloperNewsScreen({super.key});

  @override
  State<DeveloperNewsScreen> createState() => _DeveloperNewsScreenState();
}

class _DeveloperNewsScreenState extends State<DeveloperNewsScreen> {
  final Set<String> _followedStories = {'story1', 'story2'};

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
    // --- NEW: Filter the list of stories, not posts ---
    final List<DevUpdateStory> followedStories = dummyDevUpdates
        .where((story) => _followedStories.contains(story.id))
        .toList();
    // --- END OF NEW ---

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

            // --- Tab 2: Following (MODIFIED) ---
            // Now shows expandable story cards, just like the "All Stories" tab
            if (followedStories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'You aren\'t following any stories yet. \nTap "Follow" on a story in the "All Stories" tab.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (followedStories.isNotEmpty)
              ListView.builder(
                itemCount: followedStories.length,
                itemBuilder: (context, index) {
                  final story = followedStories[index];
                  // We reuse the same card widget
                  return DevStoryCard(
                    story: story,
                    isFollowed: true, // We know this is true
                    onFollowToggle: () => _toggleFollow(story.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
