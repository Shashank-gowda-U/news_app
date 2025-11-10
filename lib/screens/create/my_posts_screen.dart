// lib/screens/create/my_posts_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_app/models/local_anchor_post.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/widgets/my_post_card.dart'; // We will create this next
import 'package:provider/provider.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID to filter the posts
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Published Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query 'local_posts' but ONLY where 'anchorId' matches our ID
        stream: FirebaseFirestore.instance
            .collection('local_posts')
            .where('anchorId', isEqualTo: userId)
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('You have not published any posts yet.'),
            );
          }

          final List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final post = LocalAnchorPost.fromFirestore(documents[index]);
              // Use our new "MyPostCard" widget
              return MyPostCard(post: post);
            },
          );
        },
      ),
    );
  }
}
