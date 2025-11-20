// lib/screens/following_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/public_profile_screen.dart';
import 'package:provider/provider.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final Set<String> _loadingAnchors = {};

  Future<void> _unfollow(
      BuildContext context, String currentUserId, String anchorId) async {
    setState(() {
      _loadingAnchors.add(anchorId);
    });

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final anchorRef =
        FirebaseFirestore.instance.collection('users').doc(anchorId);

    try {
      await userRef.update({
        'followingAnchors': FieldValue.arrayRemove([anchorId])
      });
      await anchorRef.update({'totalFollowers': FieldValue.increment(-1)});
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfollow: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAnchors.remove(anchorId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final followingList = authProvider.user?.followingAnchors ?? [];
    final currentUserId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
      ),
      body: followingList.isEmpty
          ? const Center(
              child: Text('You are not following any anchors yet.'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: followingList)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final anchorDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: anchorDocs.length,
                  itemBuilder: (context, index) {
                    final anchor = UserModel.fromFirestore(anchorDocs[index]);
                    final bool isLoading = _loadingAnchors.contains(anchor.uid);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(anchor.profilePicUrl),
                      ),
                      title: Text(anchor.name),
                      subtitle: Text(anchor.location),
                      trailing: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.0))
                          : OutlinedButton(
                              child: const Text('Unfollow'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                if (currentUserId != null) {
                                  _unfollow(context, currentUserId, anchor.uid);
                                }
                              },
                            ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              PublicProfileScreen(userId: anchor.uid),
                        ));
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
