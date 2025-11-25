import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/providers/auth_provider.dart'; // Import AuthProvider
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:share_plus/share_plus.dart';

class NewsArticleCard extends StatefulWidget {
  final NewsArticle article;
  const NewsArticleCard({super.key, required this.article});

  @override
  State<NewsArticleCard> createState() => _NewsArticleCardState();
}

class _NewsArticleCardState extends State<NewsArticleCard> {
  bool _isLiking = false;

  void _shareArticle() {
    final textToShare =
        'Check out this news: ${widget.article.title}\n\nRead more: ${widget.article.sourceUrl}';
    Share.share(textToShare);
  }

  Future<void> _toggleLike() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in to like')));
      return;
    }

    if (_isLiking) return;
    setState(() => _isLiking = true);

    final articleRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.article.id);

    final likeRef = articleRef.collection('likes').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction
              .update(articleRef, {'likeCount': FieldValue.increment(-1)});
        } else {
          // Like
          transaction.set(likeRef, {
            'timestamp': FieldValue.serverTimestamp(),
            'userName': user.name,
          });
          transaction
              .update(articleRef, {'likeCount': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Like failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _openDetailScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostDetailScreen(article: widget.article),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(widget.article.publishedAt);

    // Get current user for checking like status
    final user = Provider.of<AuthProvider>(context).user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _openDetailScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.article.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
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
                    widget.article.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.article.summary,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: widget.article.topicTags
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
                trueVotes: widget.article.trueVotes,
                falseVotes: widget.article.falseVotes,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LIKE BUTTON WITH STREAM BUILDER
                  StreamBuilder<DocumentSnapshot>(
                      stream: user != null
                          ? FirebaseFirestore.instance
                              .collection('articles')
                              .doc(widget.article.id)
                              .collection('likes')
                              .doc(user.uid)
                              .snapshots()
                          : null,
                      builder: (context, snapshot) {
                        bool isLiked = false;
                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.exists) {
                          isLiked = true;
                        }
                        return TextButton.icon(
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 18,
                            color: isLiked
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          label: Text(widget.article.likeCount.toString()),
                          onPressed: _toggleLike,
                        );
                      }),

                  TextButton.icon(
                    icon: const Icon(Icons.comment_outlined, size: 18),
                    label: Text(widget.article.commentCount.toString()),
                    onPressed: _openDetailScreen,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                    onPressed: _shareArticle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
