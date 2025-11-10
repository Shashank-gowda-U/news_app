// lib/widgets/dev_story_card.dart
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
  // This will hold our posts once they are loaded
  Stream<QuerySnapshot>? _postsStream;

  // This is called when the user taps the expansion tile
  void _onExpansionChanged(bool isExpanded) {
    if (isExpanded && _postsStream == null) {
      // If expanding for the first time, fetch the posts subcollection
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        // --- Header Section ---
        leading: Icon(widget.story.icon, size: 32),
        title: Text(widget.story.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.story.description,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: OutlinedButton(
          onPressed: widget.onFollowToggle,
          child: Text(widget.isFollowed ? 'Following' : 'Follow'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.isFollowed ? Colors.blue : null,
            side: BorderSide(
              color: widget.isFollowed ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        onExpansionChanged: _onExpansionChanged, // <-- NEW
        // --- Expanded Posts Section (now a StreamBuilder) ---
        children: [
          if (_postsStream == null)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )),
          if (_postsStream != null)
            StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading posts.');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No posts found for this story.');
                }

                // We have posts!
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final post = DevUpdatePost.fromFirestore(doc);
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5),
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
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(post.publishedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(post.content),
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
