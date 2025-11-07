// lib/models/news_article.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- NEW IMPORT

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String sourceUrl;
  final String imageUrl;
  final DateTime publishedAt;
  final List<String> topicTags;
  final String emotionalTag;
  final int likeCount;
  final int commentCount;
  final int trueVotes;
  final int falseVotes;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceUrl,
    required this.imageUrl,
    required this.publishedAt,
    required this.topicTags,
    required this.emotionalTag,
    required this.likeCount,
    required this.commentCount,
    required this.trueVotes,
    required this.falseVotes,
  });

  // --- NEW FACTORY CONSTRUCTOR ---
  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      summary: data['summary'] ?? 'No Summary',
      sourceUrl: data['sourceUrl'] ?? '',
      imageUrl:
          data['imageUrl'] ?? 'https://picsum.photos/seed/placeholder/600/400',
      // Convert Firestore Timestamp to DateTime
      publishedAt:
          (data['publishedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      topicTags: List<String>.from(data['topicTags'] ?? []),
      emotionalTag: data['emotionalTag'] ?? 'neutral',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      trueVotes: data['trueVotes'] ?? 0,
      falseVotes: data['falseVotes'] ?? 0,
    );
  }
  // --- END OF NEW CONSTRUCTOR ---
}

// We no longer need the dummyAiNews list, but we can keep it
// here for now in case we need it for testing.
final List<NewsArticle> dummyAiNews = [
  // ... (dummy data is still here, but we won't use it)
];
