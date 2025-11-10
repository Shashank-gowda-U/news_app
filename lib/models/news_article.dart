// lib/models/news_article.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      summary: data['summary'] ?? 'No Summary',
      sourceUrl: data['sourceUrl'] ?? '',
      imageUrl:
          data['imageUrl'] ?? 'https://picsum.photos/seed/placeholder/600/400',
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
} // <-- *** THE CLASS ENDS HERE ***

// --- FIX: The list must be defined OUTSIDE the class ---
final List<NewsArticle> dummyAiNews = [
  NewsArticle(
    id: 'ai1',
    title: 'Major Breakthrough in AI-Powered Fusion Energy',
    summary:
        'Scientists at a leading lab have used a new AI model to sustain a fusion reaction for a record-breaking 10 seconds, paving the way for clean energy.',
    sourceUrl: 'https://example.com/fusion-news',
    imageUrl: 'https://picsum.photos/seed/ai1/600/400',
    publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    topicTags: ['science', 'technology', 'energy'],
    emotionalTag: 'uplifting',
    likeCount: 1204,
    commentCount: 88,
    trueVotes: 210,
    falseVotes: 12,
  ),
  // ... (the other dummy posts)
];
