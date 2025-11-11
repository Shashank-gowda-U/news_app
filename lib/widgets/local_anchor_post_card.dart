// lib/widgets/local_anchor_post_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
// --- NEW IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/public_profile_screen.dart'; // For tapping on name
// --- END OF NEW IMPORTS ---

class LocalAnchorPostCard extends StatelessWidget {
  final LocalAnchorPost post;
  const LocalAnchorPostCard({super.key, required this.post});

  // --- NEW FUNCTION to handle following/unfollowing ---
  Future<void> _toggleFollow(
      BuildContext context, String currentUserId, bool isFollowing) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final anchorRef =
        FirebaseFirestore.instance.collection('users').doc(post.anchorId);

    try {
      if (isFollowing) {
        // --- Unfollow logic ---
        await userRef.update({
          'followingAnchors': FieldValue.arrayRemove([post.anchorId])
        });
        await anchorRef.update({'totalFollowers': FieldValue.increment(-1)});
      } else {
        // --- Follow logic ---
        await userRef.update({
          'followingAnchors': FieldValue.arrayUnion([post.anchorId])
        });
        await anchorRef.update({'totalFollowers': FieldValue.increment(1)});
      }

      // --- THIS IS THE FIX FOR REAL-TIME UPDATE ---
      // After updating the database, tell our app's provider to
      // refresh its local user data.
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      // --- END OF FIX ---
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(post.publishedAt);

    // --- NEW: Get the current user to see who they follow ---
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    // Check if the current user is already following this post's anchor
    final bool isFollowing =
        authProvider.user?.followingAnchors.contains(post.anchorId) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Anchor Info (Feature #12)
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.anchorProfilePicUrl),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                // --- MODIFIED: Tappable anchor name ---
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          PublicProfileScreen(userId: post.anchorId),
                    ));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.anchorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${post.location} • $formattedDate',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // --- END OF MODIFICATION ---
                const Spacer(),

                // --- MODIFIED: Follow Button ---
                // Don't show follow button if it's our own post
                if (currentUserId != null && currentUserId != post.anchorId)
                  IconButton(
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
                // --- END OF MODIFICATION ---
              ],
            ),
            const SizedBox(height: 12),

            // 2. Post Content
            Text(post.content, style: const TextStyle(fontSize: 14)),

            // 3. Optional Image
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // 4. Tags (Feature #13)
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: post.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        padding: const EdgeInsets.all(2),
                        labelStyle: const TextStyle(fontSize: 10),
                        backgroundColor: Colors.blue[100],
                      ))
                  .toList(),
            ),

            const Divider(height: 16),

            // 5. Social Actions (Will be wired up next)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(
                  icon: Icons.thumb_up_outlined,
                  label: post.likeCount.toString(),
                  onPressed: () {/* TODO: Add like logic */},
                ),
                _buildSocialButton(
                  icon: Icons.comment_outlined,
                  label: post.commentCount.toString(),
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
