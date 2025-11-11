// lib/screens/public_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/detail/post_detail_screen.dart';
import 'package:news_app/widgets/local_anchor_post_card.dart';
import 'package:provider/provider.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  // This is the follow logic from local_anchor_post_card
  Future<void> _toggleFollow(
      BuildContext context, String currentUserId, bool isFollowing) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final anchorRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId); // Use the profile's userId

    try {
      if (isFollowing) {
        await userRef.update({
          'followingAnchors': FieldValue.arrayRemove([userId])
        });
        await anchorRef.update({'totalFollowers': FieldValue.increment(-1)});
      } else {
        await userRef.update({
          'followingAnchors': FieldValue.arrayUnion([userId])
        });
        await anchorRef.update({'totalFollowers': FieldValue.increment(1)});
      }
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final bool isFollowing =
        authProvider.user?.followingAnchors.contains(userId) ?? false;
    final bool isMe = currentUserId == userId;

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        // This stream gets the user's profile data
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = UserModel.fromFirestore(userSnapshot.data!);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(
                  delegate: SliverChildListDelegate([
                    // --- Profile Header ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user.profilePicUrl),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            user.location,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
                          if (!isMe && user.isAnchor && currentUserId != null)
                            ElevatedButton(
                              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                              onPressed: () {
                                _toggleFollow(
                                    context, currentUserId, isFollowing);
                              },
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (user.isAnchor)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Posts by ${user.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                  ]),
                ),
              ];
            },
            // --- User's Post Feed ---
            body: user.isAnchor
                ? StreamBuilder<QuerySnapshot>(
                    // This stream gets all posts by this user
                    stream: FirebaseFirestore.instance
                        .collection('local_posts')
                        .where('anchorId', isEqualTo: userId)
                        .orderBy('publishedAt', descending: true)
                        .snapshots(),
                    builder: (context, postSnapshot) {
                      if (!postSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (postSnapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('This anchor has not posted yet.'));
                      }
                      return ListView.builder(
                        itemCount: postSnapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final post = LocalAnchorPost.fromFirestore(
                              postSnapshot.data!.docs[index]);
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: post),
                              ));
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
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
