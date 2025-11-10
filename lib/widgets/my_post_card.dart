// lib/widgets/my_post_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/screens/create/create_post_screen.dart';

class MyPostCard extends StatelessWidget {
  final LocalAnchorPost post;
  const MyPostCard({super.key, required this.post});

  // --- Function to show the Edit/Delete options ---
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                // Open CreatePostScreen in "Edit Mode"
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CreatePostScreen(postToEdit: post),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Post',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                _confirmDelete(context);
              },
            ),
          ],
        );
      },
    );
  }

  // --- Function to show the "Are you sure?" dialog ---
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text(
              'This will permanently delete the post from the database. This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deletePost(context);
              },
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIED: Function to handle the actual deletion ---
  Future<void> _deletePost(BuildContext context) async {
    try {
      // 1. Delete the post from Firestore
      await FirebaseFirestore.instance
          .collection('local_posts')
          .doc(post.id)
          .delete();

      // --- THIS IS THE NEW LINE TO ADD ---
      // 2. Decrement the user's post count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(post.anchorId) // Use the anchorId from the post
          .update({'totalPosts': FieldValue.increment(-1)});
      // --- END OF NEW LINE ---

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().add_jm().format(post.publishedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Anchor Info
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posted to: ${post.location}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                // --- THIS IS THE MENU BUTTON ---
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context),
                ),
                // --- END OF BUTTON ---
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

            // 4. Tags
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

            // 5. Social Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(
                  icon: Icons.thumb_up_outlined,
                  label: post.likeCount.toString(),
                ),
                _buildSocialButton(
                  icon: Icons.comment_outlined,
                  label: post.commentCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the social buttons (no onPressed needed)
  Widget _buildSocialButton({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
