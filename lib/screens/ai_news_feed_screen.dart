// lib/screens/ai_news_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/news_article_card.dart';

// --- NEW IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
// --- END OF NEW IMPORTS ---

class AiNewsFeedScreen extends StatelessWidget {
  const AiNewsFeedScreen({super.key});

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const FilterModal(isForLocalAnchors: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterModal(context);
            },
          ),
        ],
      ),
      // --- BODY IS NOW A STREAMBUILDER ---
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the 'articles' collection
        // Order by publish date, newest first
        stream: FirebaseFirestore.instance
            .collection('articles')
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Check for errors
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          // 2. Check if loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 3. Check if there is no data
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No news articles found.'));
          }

          // 4. We have data!
          final List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              // Convert the Firestore document into our NewsArticle object
              final article = NewsArticle.fromFirestore(documents[index]);

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PostDetailScreen(article: article),
                  ));
                },
                child: NewsArticleCard(article: article),
              );
            },
          );
        },
      ),
      // --- END OF STREAMBUILDER ---
    );
  }
}
