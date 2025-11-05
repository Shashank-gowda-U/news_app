// lib/widgets/local_anchor_post_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/local_anchor_post.dart';

class LocalAnchorPostCard extends StatelessWidget {
  final LocalAnchorPost post;
  const LocalAnchorPostCard({super.key, required this.post});

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
            // 1. Anchor Info (Feature #12)
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.anchorProfilePicUrl),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.anchorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${post.location} • $formattedDate',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  onPressed: () {
                    // TODO: Implement follow functionality
                  },
                ),
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

            // 5. Social Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(
                  icon: Icons.thumb_up_outlined,
                  label: post.likeCount.toString(),
                  onPressed: () {},
                ),
                _buildSocialButton(
                  icon: Icons.comment_outlined,
                  label: post.commentCount.toString(),
                  onPressed: () {},
                ),
                _buildSocialButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () {},
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
