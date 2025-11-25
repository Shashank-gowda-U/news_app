// lib/widgets/local_anchor_post_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/screens/public_profile_screen.dart';
import 'package:news_app/widgets/truth_vote_bar.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LocalAnchorPostCard extends StatefulWidget {
  final LocalAnchorPost post;
  const LocalAnchorPostCard({super.key, required this.post});

  @override
  State<LocalAnchorPostCard> createState() => _LocalAnchorPostCardState();
}

class _LocalAnchorPostCardState extends State<LocalAnchorPostCard> {
  bool _isLiking = false;
  bool _isTogglingFollow = false;

  void _sharePost() {
    Share.share(
        'Local Update from ${widget.post.anchorName}: ${widget.post.content}');
  }

  // --- FIX: Update Anchor's Total Likes ---
  Future<void> _toggleLike() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in to like')));
      return;
    }

    if (_isLiking) return;
    setState(() => _isLiking = true);

    final postRef = FirebaseFirestore.instance
        .collection('local_posts')
        .doc(widget.post.id);

    final anchorRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.post.anchorId);

    final likeRef = postRef.collection('likes').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          // Unlike: Decrement post likes AND anchor total likes
          transaction.delete(likeRef);
          transaction.update(postRef, {'likeCount': FieldValue.increment(-1)});
          transaction
              .update(anchorRef, {'totalLikes': FieldValue.increment(-1)});
        } else {
          // Like: Increment post likes AND anchor total likes
          transaction.set(likeRef, {
            'timestamp': FieldValue.serverTimestamp(),
            'userName': user.name,
          });
          transaction.update(postRef, {'likeCount': FieldValue.increment(1)});
          transaction
              .update(anchorRef, {'totalLikes': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Like failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  // --- FIX: Follow Button Logic ---
  Future<void> _toggleFollow() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isTogglingFollow = true);

    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final anchorRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.post.anchorId);

    final bool isFollowing =
        user.followingAnchors.contains(widget.post.anchorId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (isFollowing) {
          transaction.update(currentUserRef, {
            'followingAnchors': FieldValue.arrayRemove([widget.post.anchorId])
          });
          transaction
              .update(anchorRef, {'totalFollowers': FieldValue.increment(-1)});
        } else {
          transaction.update(currentUserRef, {
            'followingAnchors': FieldValue.arrayUnion([widget.post.anchorId])
          });
          transaction
              .update(anchorRef, {'totalFollowers': FieldValue.increment(1)});
        }
      });
      // Refresh local user data to update UI
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to follow: $e")));
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  void _openDetailScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostDetailScreen(post: widget.post),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(widget.post.publishedAt);

    final user = Provider.of<AuthProvider>(context).user;
    final bool isFollowing =
        user?.followingAnchors.contains(widget.post.anchorId) ?? false;
    final bool isMe = user?.uid == widget.post.anchorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _openDetailScreen,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            PublicProfileScreen(userId: widget.post.anchorId))),
                    child: CircleAvatar(
                      backgroundImage:
                          NetworkImage(widget.post.anchorProfilePicUrl),
                      radius: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PublicProfileScreen(
                              userId: widget.post.anchorId))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.anchorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${widget.post.location} • $formattedDate',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- FOLLOW BUTTON ---
                  if (!isMe)
                    _isTogglingFollow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(
                              isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add_alt_1,
                              color: isFollowing
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                            ),
                            onPressed: _toggleFollow,
                            tooltip: isFollowing ? "Unfollow" : "Follow",
                          ),
                ],
              ),
              const SizedBox(height: 12),

              Text(widget.post.content, style: const TextStyle(fontSize: 14)),

              if (widget.post.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              TruthVoteBar(
                trueVotes: widget.post.trueVotes,
                falseVotes: widget.post.falseVotes,
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: widget.post.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          padding: const EdgeInsets.all(2),
                          labelStyle: const TextStyle(fontSize: 10),
                          backgroundColor: Colors.blue[100],
                        ))
                    .toList(),
              ),
              const Divider(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null
                        ? FirebaseFirestore.instance
                            .collection('local_posts')
                            .doc(widget.post.id)
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
                        label: Text(widget.post.likeCount.toString()),
                        onPressed: _toggleLike,
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.comment_outlined, size: 18),
                    label: Text(widget.post.commentCount.toString()),
                    onPressed: _openDetailScreen,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                    onPressed: _sharePost,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
