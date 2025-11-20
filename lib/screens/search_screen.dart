// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/user_model.dart';
import 'package:news_app/screens/public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Stream<QuerySnapshot>? _resultsStream;

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _resultsStream = null;
      });
      return;
    }


    setState(() {
      _resultsStream = FirebaseFirestore.instance
          .collection('users')
          .where('isAnchor', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for users...',
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _resultsStream == null
          ? const Center(child: Text('Enter a name to search.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _resultsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                          'Error. You may need to create a Firestore index for "users" on the "name" field.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final user =
                        UserModel.fromFirestore(snapshot.data!.docs[index]);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.profilePicUrl),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.location),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              PublicProfileScreen(userId: user.uid),
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
