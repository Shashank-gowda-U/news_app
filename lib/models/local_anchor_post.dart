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
  // --- NEW FIELDS ---
  final int trueVotes;
  final int falseVotes;

  const LocalAnchorPost({
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
    // --- NEW CONSTRUCTOR ARGS ---
    this.trueVotes = 0,
    this.falseVotes = 0,
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
      // --- NEW MAPPING ---
      trueVotes: data['trueVotes'] ?? 0,
      falseVotes: data['falseVotes'] ?? 0,
    );
  }
}
