// lib/screens/detail/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/widgets/comment_card.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';

class PostDetailScreen extends StatelessWidget {
  final NewsArticle? article;
  final LocalAnchorPost? post;

  const PostDetailScreen({
    super.key,
    this.article,
    this.post,
  }) : assert(article != null || post != null,
            'You must provide either an article or a post.');
  @override
  Widget build(BuildContext context) {
    final bool isGlobalNews = (article != null);
    final String title = isGlobalNews ? article!.title : post!.anchorName;

    final String imageUrl =
        isGlobalNews ? article!.imageUrl : (post!.imageUrl ?? '');
    final DateTime publishedAt =
        isGlobalNews ? article!.publishedAt : post!.publishedAt;

    final String heroTag =
        isGlobalNews ? 'article_${article!.id}' : 'post_${post!.id}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)]),
              ),
              background: Hero(
                tag:
                    heroTag, 
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGlobalNews ? article!.title : post!.content,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Published ${DateFormat.yMMMd().add_jm().format(publishedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isGlobalNews) ...[
                        Text(
                          'Source: ${article!.sourceUrl}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[300],
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          article!.summary,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],

                      const Divider(height: 32),

                      Text(
                        'Community Validation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'Cast your vote on the validity of this news.'),
                      const SizedBox(height: 16),
                      if (isGlobalNews)
                        TruthVoteBar(
                          trueVotes: article!.trueVotes,
                          falseVotes: article!.falseVotes,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Add Firebase logic to vote true
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.green),
                              label: const Text('True'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Add Firebase logic to vote false
                              },
                              icon: const Icon(Icons.highlight_off,
                                  color: Colors.red),
                              label: const Text('False'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      Text(
                        'Comments (3)', // Dummy count
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const CommentCard(
                        author: 'Jane',
                        comment: 'This is a huge breakthrough!',
                        likes: 15,
                        replies: 2,
                      ),
                      const CommentCard(
                        author: 'Raj',
                        comment:
                            'I\'m skeptical. We\'ve heard this before. Need to see more data.',
                        likes: 42,
                        replies: 0,
                      ),
                      const CommentCard(
                        author: 'User123',
                        comment: 'First!',
                        likes: 0,
                        replies: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
