// lib/widgets/dev_story_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/dev_update.dart';

class DevStoryCard extends StatelessWidget {
  final DevUpdateStory story;
  final bool isFollowed;
  final VoidCallback onFollowToggle;

  const DevStoryCard({
    super.key,
    required this.story,
    required this.isFollowed,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        // --- Header Section ---
        leading: Icon(story.icon, size: 32),
        title: Text(story.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(story.description,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: OutlinedButton(
          onPressed: onFollowToggle,
          child: Text(isFollowed ? 'Following' : 'Follow'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isFollowed ? Colors.blue : null,
            side: BorderSide(
              color: isFollowed ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        // --- Expanded Posts Section ---
        children: story.posts.map((post) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(post.publishedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(post.content),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
