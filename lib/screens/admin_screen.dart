import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _approveAnchor(
      BuildContext context, String docId, String userId, String name) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        final requestRef =
            FirebaseFirestore.instance.collection('anchor_requests').doc(docId);

        // 1. Promote user to Anchor
        transaction.update(userRef, {'isAnchor': true});
        // 2. Remove the request
        transaction.delete(requestRef);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Approved $name!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _denyAnchor(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('anchor_requests')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request denied/deleted.')));
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anchor_requests')
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending approvals."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(data['userName'] ?? 'Unknown'),
                      subtitle: Text(
                          "${data['userEmail']}\n${data['location']} • DOB: ${data['dateOfBirth']}"),
                      isThreeLine: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _denyAnchor(context, doc.id),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text("Deny"),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _approveAnchor(context, doc.id,
                                data['userId'], data['userName']),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            child: const Text("Approve"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
