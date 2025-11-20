// lib/models/dev_update.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Helper to convert string to icon
IconData _getIconFromString(String iconName) {
  switch (iconName) {
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'developer_mode':
      return Icons.developer_mode;
    case 'sports_cricket':
      return Icons.sports_cricket;
    default:
      return Icons.article;
  }
}


// Represents a single post within a story (e.g., "Day 1 Update")
class DevUpdatePost {
  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;

  const DevUpdatePost({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
  });

  // --- NEW: fromFirestore constructor ---
  factory DevUpdatePost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DevUpdatePost(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      content: data['content'] ?? 'No Content',
      publishedAt:
          (data['publishedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}

// Represents the overall story (e.g., "Football WC Coverage")
class DevUpdateStory {
  final String id;
  final String title;
  final String description;
  final IconData icon;


  const DevUpdateStory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,

  });

  // --- NEW: fromFirestore constructor ---
  factory DevUpdateStory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DevUpdateStory(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      icon: _getIconFromString(data['icon'] ?? 'article'),
    );
  }
}


