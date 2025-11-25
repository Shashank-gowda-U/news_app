// lib/screens/public_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/local_anchor_post_card.dart';
import 'package:provider/provider.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isTogglingFollow = false;

  Future<void> _toggleFollow(bool isFollowing) async {
    setState(() => _isTogglingFollow = true);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final anchorRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (isFollowing) {
          transaction.update(userRef, {
            'followingAnchors': FieldValue.arrayRemove([widget.userId])
          });
          transaction
              .update(anchorRef, {'totalFollowers': FieldValue.increment(-1)});
        } else {
          transaction.update(userRef, {
            'followingAnchors': FieldValue.arrayUnion([widget.userId])
          });
          transaction
              .update(anchorRef, {'totalFollowers': FieldValue.increment(1)});
        }
      });
      if (mounted)
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;
    final bool isFollowing =
        currentUser?.followingAnchors.contains(widget.userId) ?? false;
    final bool isMe = currentUser?.uid == widget.userId;

    return Scaffold(
      appBar: AppBar(title: const Text("Anchor Profile")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final user = UserModel.fromFirestore(userSnapshot.data!);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  NetworkImage(user.profilePicUrl)),
                          const SizedBox(height: 12),
                          Text(user.name,
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text(user.location,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          if (user.isAnchor)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                    'Posts', user.totalPosts.toString()),
                                _buildStatColumn('Followers',
                                    user.totalFollowers.toString()),
                                _buildStatColumn(
                                    'Total Likes', user.totalLikes.toString()),
                              ],
                            ),
                          const SizedBox(height: 16),

                          // --- NEW: Follow Button ---
                          if (!isMe && user.isAnchor && currentUser != null)
                            _isTogglingFollow
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: () => _toggleFollow(isFollowing),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? Colors.grey
                                          : Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(120, 40),
                                    ),
                                    child: Text(
                                        isFollowing ? 'Unfollow' : 'Follow'),
                                  ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ]),
                ),
              ];
            },
            body: user.isAnchor
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('local_posts')
                        .where('anchorId', isEqualTo: widget.userId)
                        .orderBy('publishedAt', descending: true)
                        .snapshots(),
                    builder: (context, postSnapshot) {
                      if (!postSnapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      if (postSnapshot.data!.docs.isEmpty)
                        return const Center(
                            child: Text('This anchor has not posted yet.'));
                      return ListView.builder(
                        itemCount: postSnapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final post = LocalAnchorPost.fromFirestore(
                              postSnapshot.data!.docs[index]);
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailScreen(post: post)));
                            },
                            child: LocalAnchorPostCard(post: post),
                          );
                        },
                      );
                    },
                  )
                : const Center(child: Text('This user is not an anchor.')),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
