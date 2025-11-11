// lib/screens/ai_news_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/filter_modal.dart';
import 'package:news_app/widgets/news_article_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
// --- END OF NEW IMPORTS ---

class AiNewsFeedScreen extends StatefulWidget {
  const AiNewsFeedScreen({super.key});

  @override
  State<AiNewsFeedScreen> createState() => _AiNewsFeedScreenState();
}

class _AiNewsFeedScreenState extends State<AiNewsFeedScreen> {
  String _sortField = 'publishedAt';
  bool _sortDescending = true;
  String? _selectedMood;
  // We no longer need _selectedTag here

  // --- MODIFIED: This function now takes the user's tags ---
  Query _buildQuery(List<String> preferredTags) {
    Query query = FirebaseFirestore.instance.collection('articles');

    // 1. --- NEW: Automatic Tag Filtering ---
    // If the user has preferred tags, use them.
    // This finds any post that contains AT LEAST ONE of the user's tags.
    if (preferredTags.isNotEmpty) {
      query = query.where('topicTags', arrayContainsAny: preferredTags);
    } else {
      // If user has no tags, show all news
      // (or we could show nothing, this is a design choice)
      // For now, let's just show all news (no query)
    }

    // 2. Filter by Mood (if selected)
    if (_selectedMood != null) {
      query = query.where('emotionalTag', isEqualTo: _selectedMood);
    }

    // 3. Add sorting
    query = query.orderBy(_sortField, descending: _sortDescending);

    return query;
  }

  void _showFilterModal(BuildContext context) async {
    final Map<String, dynamic> currentFilters = {
      'sortField': _sortField,
      'sortDescending': _sortDescending,
      'selectedMood': _selectedMood,
      'selectedTag': null, // We don't use this anymore
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
        // _selectedTag is no longer set
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get the preferredTags from the provider ---
    // We use "watch" so if the user changes their tags in the
    // profile, this screen will automatically rebuild!
    final preferredTags =
        Provider.of<AuthProvider>(context).user?.preferredTags ?? [];
    // --- END OF NEW ---

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
        // --- Pass the tags to our query builder ---
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
