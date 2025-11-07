// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in our application
/// This model stores user data that comes from Firestore database
class UserModel {
  // Basic user information
  final String uid; // User ID from Firebase Auth
  final String name; // User's display name
  final String email; // User's email address
  final String profilePicUrl; // URL to user's profile picture

  // User preferences and saved data
  final List<String> savedArticles; // List of saved article IDs
  final List<String> followedTopics; // List of topics the user follows

  /// Constructor - creates a new UserModel instance
  ///
  /// Required fields: uid, name, email, profilePicUrl
  /// Optional fields: savedArticles, followedTopics (default to empty lists)
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePicUrl,
    this.savedArticles = const [],
    this.followedTopics = const [],
  });

  /// Converts UserModel to a Map
  /// This is used when saving data to Firestore
  ///
  /// Example:
  /// UserModel user = UserModel(...);
  /// Map<String, dynamic> data = user.toMap();
  /// firestore.collection('users').doc(uid).set(data);
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicUrl': profilePicUrl,
      'savedArticles': savedArticles,
      'followedTopics': followedTopics,
    };
  }

  /// Creates a UserModel from a Firestore document
  /// This is used when reading data from Firestore
  ///
  /// Example:
  /// DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
  /// UserModel user = UserModel.fromFirestore(doc);
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Get the data from the document
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id, // Use document ID as uid
      name: data['name'] ?? '', // Use empty string if name is null
      email: data['email'] ?? '',
      profilePicUrl: data['profilePicUrl'] ?? '',
      // Convert Firestore arrays to List<String>
      savedArticles: List<String>.from(data['savedArticles'] ?? []),
      followedTopics: List<String>.from(data['followedTopics'] ?? []),
    );
  }

  /// Creates a copy of this UserModel with some fields updated
  /// This is useful when you want to update only specific fields
  ///
  /// Example:
  /// UserModel updatedUser = currentUser.copyWith(name: 'New Name');
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? profilePicUrl,
    List<String>? savedArticles,
    List<String>? followedTopics,
  }) {
    return UserModel(
      uid: uid ?? this.uid, // Use new value if provided, otherwise keep current
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      savedArticles: savedArticles ?? this.savedArticles,
      followedTopics: followedTopics ?? this.followedTopics,
    );
  }

  /// Converts UserModel to a string for debugging
  /// Makes it easy to print user data for debugging purposes
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email)';
  }
}
