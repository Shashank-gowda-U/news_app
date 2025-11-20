// lib/screens/ai_news_feed_screen.dart

// ARCHITECTURE NOTE:
// This screen fetches news articles from the 'articles' collection in Firestore.
// It does NOT make a direct call to a news API from within the app.
//
// A separate backend service (e.g., a Cloud Function or a standalone script)
// is responsible for:
// 1. Calling a news API (like NewsAPI.org) to get the latest articles.
// 2. Calling the Gemini API to generate a summary for each article.
// 3. Storing the final, processed NewsArticle object (including the summary)
//    into the 'articles' collection in Firestore.
//
// Therefore, your API keys for the news service and Gemini should be handled
// securely in your backend service, not in this Flutter application.

import 'package:flutter/material.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/news_article_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';

class AiNewsFeedScreen extends StatefulWidget {
  const AiNewsFeedScreen({super.key});

  @override
  State<AiNewsFeedScreen> createState() => _AiNewsFeedScreenState();
}

class _AiNewsFeedScreenState extends State<AiNewsFeedScreen> {
  String _sortField = 'publishedAt';
  bool _sortDescending = true;
  String? _selectedMood;



  Query _buildQuery(List<String> preferredTags) {
    Query query = FirebaseFirestore.instance.collection('articles');

    if (preferredTags.isNotEmpty) {
      // Firestore 'array-contains-any' has a limit of 10 items.
      // We'll take the first 10 tags if the user has more.
      // A more advanced implementation might show a warning to the user.
      final tagsToQuery =
          preferredTags.length > 10 ? preferredTags.sublist(0, 10) : preferredTags;
      query = query.where('topicTags', arrayContainsAny: tagsToQuery);
    }

    if (_selectedMood != null) {
      query = query.where('emotionalTag', isEqualTo: _selectedMood);
    }

    query = query.orderBy(_sortField, descending: _sortDescending);

    return query;
  }

  void _showFilterModal(BuildContext context) async {
    final Map<String, dynamic> currentFilters = {
      'sortField': _sortField,
      'sortDescending': _sortDescending,
      'selectedMood': _selectedMood,

    };

    final newFilters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FilterModal(
          isForLocalAnchors: false,
          currentFilters: currentFilters,
        );
      },
    );

    if (newFilters != null) {
      setState(() {
        _sortField = newFilters['sortField'];
        _sortDescending = newFilters['sortDescending'];
        _selectedMood = newFilters['selectedMood'];

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferredTags =
        Provider.of<AuthProvider>(context).user?.preferredTags ?? [];

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
      body: StreamBuilder<QuerySnapshot>(

        stream: _buildQuery(preferredTags).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text(
                    'Error. You may need to create a Firestore index. Check your debug console for a link.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No news articles found for your preferences.'));
          }

          final List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
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
    );
  }
}
