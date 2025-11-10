// lib/models/local_anchor_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalAnchorPost {
  final String id;
  final String anchorId;
  final String anchorName;
  final String anchorProfilePicUrl;
  final String content;
  final String? imageUrl;
  final String? cloudinaryPublicId;
  final DateTime publishedAt;
  final String location;
  final List<String> tags;
  final int likeCount;
  final int commentCount;

  LocalAnchorPost({
    required this.id,
    required this.anchorId,
    required this.anchorName,
    required this.anchorProfilePicUrl,
    required this.content,
    this.imageUrl,
    this.cloudinaryPublicId,
    required this.publishedAt,
    required this.location,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
  });

  factory LocalAnchorPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LocalAnchorPost(
      id: doc.id,
      anchorId: data['anchorId'] ?? '',
      anchorName: data['anchorName'] ?? '',
      anchorProfilePicUrl: data['anchorProfilePicUrl'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      cloudinaryPublicId: data['cloudinaryPublicId'],
      publishedAt:
          (data['publishedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      location: data['location'] ?? 'Unknown',
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
    );
  }
} // <-- *** THE CLASS ENDS HERE ***

// --- FIX: The list must be defined OUTSIDE the class ---
final List<LocalAnchorPost> dummyLocalNews = [
  LocalAnchorPost(
    id: 'local1',
    anchorId: 'anchor_jane',
    anchorName: 'Jane in Bengaluru',
    anchorProfilePicUrl: 'https://i.pravatar.cc/100?u=jane',
    content:
        'Heads up! Major water pipeline burst near Koramangala 4th Block. Traffic is being rerouted. Avoid the area if you can!',
    imageUrl: 'https://picsum.photos/seed/local1/600/400',
    publishedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    location: 'Bengaluru, IN',
    tags: ['traffic', 'local', 'alert'],
    likeCount: 92,
    commentCount: 14,
  ),
  LocalAnchorPost(
    id: 'local2',
    anchorId: 'anchor_raj',
    anchorName: 'Raj Reports',
    anchorProfilePicUrl: 'https://i.pravatar.cc/100?u=raj',
    content:
        'The new community park in HSR Layout is officially open! Great place for kids and morning walks. They\'ve even got an open-air gym.',
    imageUrl: null, // Post without an image
    publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
    location: 'Bengaluru, IN',
    tags: ['community', 'good news'],
    likeCount: 156,
    commentCount: 22,
  ),
];
