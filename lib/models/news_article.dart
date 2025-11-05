// lib/models/news_article.dart
class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String sourceUrl;
  final String imageUrl;
  final DateTime publishedAt;
  final List<String> topicTags; // Feature #7: "sports", "science"
  final String emotionalTag; // Feature #8: "bad news", "uplifting"
  final int likeCount;
  final int commentCount;
  final int trueVotes; // Feature #6
  final int falseVotes; // Feature #6

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
}

// This is your dummy data for the AI News feed
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
  NewsArticle(
    id: 'ai2',
    title: 'Global Markets React to New Interest Rate Hike',
    summary:
        'Central banks around the world have raised interest rates to combat inflation, causing a ripple effect across stock markets and housing sectors.',
    sourceUrl: 'https://example.com/market-news',
    imageUrl: 'https://picsum.photos/seed/ai2/600/400',
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    topicTags: ['finance', 'world', 'politics'],
    emotionalTag: 'neutral',
    likeCount: 302,
    commentCount: 45,
    trueVotes: 50,
    falseVotes: 3,
  ),
  NewsArticle(
    id: 'ai3',
    title: 'Controversial "Fake News" Bill Sparks Widespread Protests',
    summary:
        'A new bill aimed at curbing misinformation is being called an attack on free speech by critics, leading to massive protests in the nation\'s capital.',
    sourceUrl: 'https://example.com/protest-news',
    imageUrl: 'https://picsum.photos/seed/ai3/600/400',
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    topicTags: ['politics', 'social'],
    emotionalTag: 'bad news',
    likeCount: 5200,
    commentCount: 1300,
    trueVotes: 150,
    falseVotes: 450,
  ),
];
