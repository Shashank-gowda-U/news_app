// lib/widgets/local_anchor_post_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/public_profile_screen.dart'; // For tapping on name

class LocalAnchorPostCard extends StatefulWidget {
  final LocalAnchorPost post;
  const LocalAnchorPostCard({super.key, required this.post});

  @override
  State<LocalAnchorPostCard> createState() => _LocalAnchorPostCardState();
}

class _LocalAnchorPostCardState extends State<LocalAnchorPostCard> {
  bool _isTogglingFollow = false;

  Future<void> _toggleFollow(
      BuildContext context, String currentUserId, bool isFollowing) async {
    setState(() {
      _isTogglingFollow = true;
    });

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final anchorRef =
        FirebaseFirestore.instance.collection('users').doc(widget.post.anchorId);

    // Use a write batch for an atomic operation
    final batch = FirebaseFirestore.instance.batch();

    try {
      if (isFollowing) {
        batch.update(userRef, {
          'followingAnchors': FieldValue.arrayRemove([widget.post.anchorId])
        });
        batch.update(anchorRef, {'totalFollowers': FieldValue.increment(-1)});
      } else {
        batch.update(userRef, {
          'followingAnchors': FieldValue.arrayUnion([widget.post.anchorId])
        });
        batch.update(anchorRef, {'totalFollowers': FieldValue.increment(1)});
      }

      await batch.commit();

      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    } catch (e, s) {
      // ignore: avoid_print
      print('Error toggling follow: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update follow status. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFollow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(widget.post.publishedAt);

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final bool isFollowing =
        authProvider.user?.followingAnchors.contains(widget.post.anchorId) ??
            false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.post.anchorProfilePicUrl),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          PublicProfileScreen(userId: widget.post.anchorId),
                    ));
                  },
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
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (currentUserId != null &&
                    currentUserId != widget.post.anchorId)
                  _isTogglingFollow
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.0))
                      : IconButton(
                          icon: Icon(
                            isFollowing
                                ? Icons.person_remove_alt_1_outlined
                                : Icons.person_add_alt_1_outlined,
                            color: isFollowing ? Colors.blue : null,
                          ),
                          onPressed: () {
                            _toggleFollow(context, currentUserId, isFollowing);
                          },
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(
                  icon: Icons.thumb_up_outlined,
                  label: widget.post.likeCount.toString(),
                  onPressed: () {/* TODO: Add like logic */},
                ),
                _buildSocialButton(
                  icon: Icons.comment_outlined,
                  label: widget.post.commentCount.toString(),
                  onPressed: () {/* TODO: Add comment logic */},
                ),
                _buildSocialButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () {/* TODO: Add share logic */},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
