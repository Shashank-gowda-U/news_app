// lib/screens/ai_news_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/news_article_card.dart';

class AiNewsFeedScreen extends StatelessWidget {
  const AiNewsFeedScreen({super.key});

  // Function to show the filter modal
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to be taller
      builder: (context) {
        return const FilterModal(isForLocalAnchors: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<NewsArticle> newsFeed = dummyAiNews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // --- CHANGE: Call the function ---
              _showFilterModal(context);
              // --- END OF CHANGE ---
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: newsFeed.length,
        itemBuilder: (context, index) {
          final article = newsFeed[index];
          // --- CHANGE: Wrap card in GestureDetector ---
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                // Navigate to the new detail screen
                builder: (context) => PostDetailScreen(article: article),
              ));
            },
            child: NewsArticleCard(article: article),
          );
          // --- END OF CHANGE ---
        },
      ),
    );
  }
}
