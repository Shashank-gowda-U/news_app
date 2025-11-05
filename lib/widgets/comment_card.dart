// lib/widgets/comment_card.dart
import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String author;
  final String comment;
  final int likes;
  final int replies;

  const CommentCard({
    super.key,
    required this.author,
    required this.comment,
    required this.likes,
    required this.replies,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(comment),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                ),
                Text(likes.toString()),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.reply_outlined, size: 18),
                ),
                if (replies > 0) Text('$replies Replies'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
