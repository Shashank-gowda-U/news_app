// lib/widgets/news_article_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';

class NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  const NewsArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(article.publishedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            article.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  article.summary, 
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: ${article.sourceUrl}', 
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[300],
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: article.topicTags
                      .map((tag) => Chip(
                            label: Text(tag),
                            padding: const EdgeInsets.all(2),
                            labelStyle: const TextStyle(fontSize: 10),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TruthVoteBar(
              trueVotes: article.trueVotes,
              falseVotes: article.falseVotes,
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSocialButton(
                  icon: Icons.thumb_up_outlined,
                  label: article.likeCount.toString(),
                  onPressed: () {
                    // TODO: Implement like functionality
                  },
                ),
                _buildSocialButton(
                  icon: Icons.comment_outlined,
                  label: article.commentCount.toString(),
                  onPressed: () {
                    // TODO: Open comment screen
                  },
                ),
                _buildSocialButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () {
                    // TODO: Implement sharing
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the social buttons
  Widget _buildSocialButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return TextButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}
