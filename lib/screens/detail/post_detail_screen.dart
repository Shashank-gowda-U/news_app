// lib/screens/detail/post_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/comment_card.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final NewsArticle? article;
  final LocalAnchorPost? post;

  const PostDetailScreen({
    super.key,
    this.article,
    this.post,
  }) : assert(article != null || post != null,
            'You must provide either an article or a post.');

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isVoting = false;
  String? _voteError;

  Future<void> _castVote(bool isTrueVote) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to vote.')),
      );
      return;
    }

    final isGlobal = widget.article != null;
    final postId = isGlobal ? widget.article!.id : widget.post!.id;
    final collection = isGlobal ? 'articles' : 'local_posts';

    setState(() {
      _isVoting = true;
      _voteError = null;
    });

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postRef =
            FirebaseFirestore.instance.collection(collection).doc(postId);
        final voteRef = postRef.collection('votes').doc(userId);

        final voteDoc = await transaction.get(voteRef);
        if (voteDoc.exists) {
          throw Exception('You have already voted on this post.');
        }

        // For local anchor posts, we also update reputation
        DocumentReference? anchorRef;
        if (!isGlobal) {
          final postDoc = await transaction.get(postRef);
          final postData = postDoc.data();
          if (postData != null) {
            final anchorId = postData['anchorId'];
            anchorRef =
                FirebaseFirestore.instance.collection('users').doc(anchorId);
          }
        }

        if (isTrueVote) {
          transaction.update(postRef, {'trueVotes': FieldValue.increment(1)});
          if (anchorRef != null) {
            transaction.update(
                anchorRef, {'reputationScore': FieldValue.increment(5.0)});
          }
        } else {
          transaction.update(postRef, {'falseVotes': FieldValue.increment(1)});
          if (anchorRef != null) {
            transaction.update(
                anchorRef, {'reputationScore': FieldValue.increment(-10.0)});
          }
        }

        transaction.set(voteRef, {'voted': isTrueVote ? 'true' : 'false'});
      });
    } catch (e) {
      setState(() {
        _voteError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGlobalNews = (widget.article != null);
    final String title =
        isGlobalNews ? widget.article!.title : widget.post!.anchorName;

    final String imageUrl =
        isGlobalNews ? widget.article!.imageUrl : (widget.post!.imageUrl ?? '');
    final DateTime publishedAt =
        isGlobalNews ? widget.article!.publishedAt : widget.post!.publishedAt;

    final String heroTag = isGlobalNews
        ? 'article_${widget.article!.id}'
        : 'post_${widget.post!.id}';

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
                tag: heroTag,
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
                        isGlobalNews
                            ? widget.article!.title
                            : widget.post!.content,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Published ${DateFormat.yMMMd().add_jm().format(publishedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isGlobalNews) ...[
                        Text(
                          'Source: ${widget.article!.sourceUrl}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[300],
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.article!.summary,
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
                      TruthVoteBar(
                        trueVotes: isGlobalNews
                            ? widget.article!.trueVotes
                            : widget.post!.trueVotes,
                        falseVotes: isGlobalNews
                            ? widget.article!.falseVotes
                            : widget.post!.falseVotes,
                      ),
                      const SizedBox(height: 16),
                      if (_isVoting)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _castVote(true),
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
                                onPressed: () => _castVote(false),
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
                      if (_voteError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: Text(
                              _voteError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
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
