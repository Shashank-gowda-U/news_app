// lib/models/dev_update.dart
import 'package:flutter/material.dart';

// Represents a single post within a story (e.g., "Day 1 Update")
class DevUpdatePost {
  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;

  DevUpdatePost({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
  });
}

// Represents the overall story (e.g., "Football WC Coverage")
class DevUpdateStory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<DevUpdatePost> posts;

  DevUpdateStory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.posts,
  });
}

// --- DUMMY DATA ---

final List<DevUpdateStory> dummyDevUpdates = [
  DevUpdateStory(
    id: 'story1',
    title: 'Football WC 2026 Coverage',
    description: 'Daily updates and commentary on the World Cup.',
    icon: Icons.sports_soccer,
    posts: [
      DevUpdatePost(
        id: 'p1a',
        title: 'Day 1: Opening Ceremony',
        content: 'The ceremony was spectacular, with all teams present.',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DevUpdatePost(
        id: 'p1b',
        title: 'Day 2: First Matches',
        content: 'Brazil vs Germany was a nail-biter, ending in a 2-2 draw.',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  DevUpdateStory(
    id: 'story2',
    title: 'App Development Log',
    description: 'Follow along with the development of this app.',
    icon: Icons.developer_mode,
    posts: [
      DevUpdatePost(
        id: 'p2a',
        title: 'v1.0.1: UI Refinements',
        content:
            'Added new filter options and redesigned the developer updates tab.',
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DevUpdatePost(
        id: 'p2b',
        title: 'v1.0.0: Initial UI Scaffolding',
        content: 'Successfully built the main UI, login flow, and navigation.',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  DevUpdateStory(
    id: 'story3',
    title: 'Cricket WC 2027',
    description: 'Live commentary and news from the Cricket World Cup.',
    icon: Icons.sports_cricket,
    posts: [
      DevUpdatePost(
        id: 'p3a',
        title: 'Team Previews',
        content: 'India is looking strong, but Australia is the favorite.',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  ),
];
