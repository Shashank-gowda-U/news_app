// lib/screens/following_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  // This is the same logic from the post card
  Future<void> _unfollow(
      BuildContext context, String currentUserId, String anchorId) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final anchorRef =
        FirebaseFirestore.instance.collection('users').doc(anchorId);

    try {
      await userRef.update({
        'followingAnchors': FieldValue.arrayRemove([anchorId])
      });
      await anchorRef.update({'totalFollowers': FieldValue.increment(-1)});
      // Refresh the provider so the UI updates
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final followingList = authProvider.user?.followingAnchors ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
      ),
      body: followingList.isEmpty
          ? const Center(
              child: Text('You are not following any anchors yet.'),
            )
          : StreamBuilder<QuerySnapshot>(
              // Query the 'users' collection for documents WHERE
              // the document ID is IN our followingList
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

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(anchor.profilePicUrl),
                      ),
                      title: Text(anchor.name),
                      subtitle: Text(anchor.location),
                      trailing: OutlinedButton(
                        child: const Text('Unfollow'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          _unfollow(
                              context, authProvider.user!.uid, anchor.uid);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
