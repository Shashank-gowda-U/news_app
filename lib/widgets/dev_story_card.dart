import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app/models/dev_update.dart';

class DevStoryCard extends StatefulWidget {
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
  State<DevStoryCard> createState() => _DevStoryCardState();
}

class _DevStoryCardState extends State<DevStoryCard> {
  Stream<QuerySnapshot>? _postsStream;

  void _onExpansionChanged(bool isExpanded) {
    if (isExpanded && _postsStream == null) {
      setState(() {
        _postsStream = FirebaseFirestore.instance
            .collection('dev_stories')
            .doc(widget.story.id)
            .collection('posts')
            .orderBy('publishedAt', descending: true)
            .snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          // FORCE WHITE ICON IN DARK MODE
          child: Icon(
            widget.story.icon,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        title: Text(
          widget.story.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          widget.story.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: OutlinedButton(
          onPressed: widget.onFollowToggle,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: BorderSide(
              // FORCE WHITE BORDER IN DARK MODE
              color: isDark
                  ? Colors.white
                  : (widget.isFollowed ? primaryColor : Colors.grey),
            ),
            // FORCE WHITE TEXT IN DARK MODE
            foregroundColor: isDark
                ? Colors.white
                : (widget.isFollowed
                    ? primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color),
          ),
          child: Text(widget.isFollowed ? 'Following' : 'Follow'),
        ),
        onExpansionChanged: _onExpansionChanged,
        childrenPadding: const EdgeInsets.only(bottom: 12, top: 4),
        children: [
          if (_postsStream == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (_postsStream != null)
            StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Error loading posts.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No updates yet.'),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final post = DevUpdatePost.fromFirestore(doc);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 6.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: isDark ? Colors.white : primaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat.MMMd().format(post.publishedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
