// lib/widgets/comment_card.dart
import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String author;
  final String comment;
  final int likes;
  // Removed "replies" as requested

  const CommentCard({
    super.key,
    required this.author,
    required this.comment,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        title: Text(
          author,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(comment),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              likes.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
