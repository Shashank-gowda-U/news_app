// lib/screens/detail/post_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/models/news_article.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  bool _hasCommentText = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {
        _hasCommentText = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _launchSourceUrl(String url) async {
    if (url.isEmpty) return;
    String safeUrl = url;
    if (!url.startsWith('http')) safeUrl = 'https://$url';
    final Uri uri = Uri.parse(safeUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw 'Could not launch';
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link.')));
    }
  }

  void _shareContent() {
    final String textToShare = widget.article != null
        ? 'Check out this news: ${widget.article!.title}\n\nRead more: ${widget.article!.sourceUrl}'
        : 'Local Update from ${widget.post!.anchorName}: ${widget.post!.content}';
    Share.share(textToShare);
  }

  // --- FIX: Universal Voting Logic ---
  Future<void> _castVote(bool isTrueVote) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in to vote')));
      return;
    }

    setState(() => _isVoting = true);

    final bool isGlobal = widget.article != null;
    final String collection = isGlobal ? 'articles' : 'local_posts';
    final String docId = isGlobal ? widget.article!.id : widget.post!.id;

    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);
    final voteRef = docRef.collection('votes').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        if (!docSnapshot.exists) throw Exception("Post not found!");

        final voteSnapshot = await transaction.get(voteRef);
        if (voteSnapshot.exists) throw Exception('You have already voted!');

        if (isTrueVote) {
          transaction.update(docRef, {'trueVotes': FieldValue.increment(1)});
          // If local, reward anchor
          if (!isGlobal) {
            final anchorRef = FirebaseFirestore.instance
                .collection('users')
                .doc(widget.post!.anchorId);
            transaction.update(
                anchorRef, {'reputationScore': FieldValue.increment(5.0)});
          }
        } else {
          transaction.update(docRef, {'falseVotes': FieldValue.increment(1)});
          // If local, penalize anchor
          if (!isGlobal) {
            final anchorRef = FirebaseFirestore.instance
                .collection('users')
                .doc(widget.post!.anchorId);
            transaction.update(
                anchorRef, {'reputationScore': FieldValue.increment(-10.0)});
          }
        }

        transaction.set(voteRef, {
          'vote': isTrueVote ? 'true' : 'false',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vote recorded')));
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  Future<void> _postComment() async {
    if (!_hasCommentText) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final docId = widget.article?.id ?? widget.post?.id;
    if (docId == null) return;

    setState(() => _isPostingComment = true);

    try {
      final CollectionReference postRef = widget.article != null
          ? FirebaseFirestore.instance.collection('articles')
          : FirebaseFirestore.instance.collection('local_posts');

      await postRef.doc(docId).collection('comments').add({
        'text': _commentController.text.trim(),
        'authorName': user.name,
        'authorPic': user.profilePicUrl,
        'uid': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      await postRef
          .doc(docId)
          .update({'commentCount': FieldValue.increment(1)});
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _toggleCommentLike(DocumentSnapshot commentDoc) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final commentRef = commentDoc.reference;
    final List<dynamic> likedBy = (commentDoc.data() as Map)['likedBy'] ?? [];
    final bool isLiked = likedBy.contains(user.uid);

    try {
      if (isLiked) {
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid])
        });
      } else {
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid])
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGlobalNews = (widget.article != null);

    // Stream logic for Global (to see live votes)
    if (isGlobalNews) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.article!.id)
            .snapshots(),
        builder: (context, snapshot) {
          NewsArticle displayArticle;
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            displayArticle = NewsArticle.fromFirestore(snapshot.data!);
          } else {
            displayArticle = widget.article!;
          }
          return _buildContent(context, displayArticle, null);
        },
      );
    }

    // Stream logic for Local (to see live votes)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('local_posts')
          .doc(widget.post!.id)
          .snapshots(),
      builder: (context, snapshot) {
        LocalAnchorPost displayPost;
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          displayPost = LocalAnchorPost.fromFirestore(snapshot.data!);
        } else {
          displayPost = widget.post!;
        }
        return _buildContent(context, null, displayPost);
      },
    );
  }

  Widget _buildContent(
      BuildContext context, NewsArticle? article, LocalAnchorPost? post) {
    final bool isGlobalNews = (article != null);
    final String title = isGlobalNews ? article!.title : post!.anchorName;
    final String imageUrl =
        isGlobalNews ? article!.imageUrl : (post!.imageUrl ?? '');
    final DateTime publishedAt =
        isGlobalNews ? article!.publishedAt : post!.publishedAt;
    final String heroTag =
        isGlobalNews ? 'article_${article!.id}' : 'post_${post!.id}';
    final String docId = isGlobalNews ? article!.id : post!.id;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 10)
                          ]),
                      onPressed: _shareContent,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8)
                        ])),
                    background: Hero(
                      tag: heroTag,
                      child: Image.network(imageUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.3),
                          colorBlendMode: BlendMode.darken),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isGlobalNews ? article!.title : post!.content,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                              'Published ${DateFormat.yMMMd().add_jm().format(publishedAt)}',
                              style: Theme.of(context).textTheme.bodySmall),
                          if (isGlobalNews) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _launchSourceUrl(article!.sourceUrl),
                              child: Text('Source: ${article!.sourceUrl}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[300],
                                      decoration: TextDecoration.underline,
                                      fontStyle: FontStyle.italic)),
                            ),
                            const SizedBox(height: 16),
                            Text(article!.summary,
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],

                          // --- FIX: Display Tags for Local Posts too ---
                          if (!isGlobalNews && post!.tags.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: post.tags
                                  .map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.blue[100],
                                      labelStyle:
                                          const TextStyle(fontSize: 12)))
                                  .toList(),
                            ),
                          ],

                          const Divider(height: 32),
                          Text('Community Validation',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                              'Cast your vote on the validity of this news.'),
                          const SizedBox(height: 16),
                          TruthVoteBar(
                            trueVotes: isGlobalNews
                                ? article!.trueVotes
                                : post!.trueVotes,
                            falseVotes: isGlobalNews
                                ? article!.falseVotes
                                : post!.falseVotes,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: OutlinedButton.icon(
                                      onPressed: _isVoting
                                          ? null
                                          : () => _castVote(true),
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green),
                                      label: const Text('True'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: OutlinedButton.icon(
                                      onPressed: _isVoting
                                          ? null
                                          : () => _castVote(false),
                                      icon: const Icon(Icons.highlight_off,
                                          color: Colors.red),
                                      label: const Text('False'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red))),
                            ],
                          ),
                          const Divider(height: 32),
                          Text('Comments',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ]),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(isGlobalNews ? 'articles' : 'local_posts')
                      .doc(docId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()));
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty)
                      return const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No comments yet. Be the first!")));
                    final user =
                        Provider.of<AuthProvider>(context, listen: false).user;
                    return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                      final commentDoc = docs[index];
                      final data = commentDoc.data() as Map<String, dynamic>;
                      final likes = data['likes'] ?? 0;
                      final List<dynamic> likedBy = data['likedBy'] ?? [];
                      final bool isLiked =
                          user != null && likedBy.contains(user.uid);
                      return ListTile(
                        leading: CircleAvatar(
                            backgroundImage: NetworkImage(data['authorPic'] ??
                                'https://i.pravatar.cc/150')),
                        title: Text(data['authorName'] ?? 'User',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['text'] ?? ''),
                        trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                  onTap: () => _toggleCommentLike(commentDoc),
                                  child: Icon(
                                      isLiked
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_outlined,
                                      size: 20,
                                      color: isLiked
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey)),
                              Text(likes.toString(),
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                      );
                    }, childCount: docs.length));
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2))
                ]),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                      minLines: 1,
                      maxLines: 3)),
              const SizedBox(width: 8),
              _isPostingComment
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : Container(
                      decoration: BoxDecoration(
                          color: _hasCommentText
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          shape: BoxShape.circle),
                      child: IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                          onPressed: _hasCommentText ? _postComment : null)),
            ]),
          )
        ],
      ),
    );
  }
}
