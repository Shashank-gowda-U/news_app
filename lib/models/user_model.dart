// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePicUrl;
  final String location;
  final bool isAnchor;
  final String? dateOfBirth;
  final List<String> followingAnchors;
  final List<String> preferredTags;
  final int totalPosts;
  final int totalFollowers;
  final int totalLikes;
  final bool hasSelectedInitialTags;
  // --- NEW FIELD ---
  final List<String> followedStories;
  // --- NEW FIELD SEARCH NAME ---
  final String searchName;
  final double reputationScore;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePicUrl,
    this.location = "Bengaluru, IN",
    this.isAnchor = false,
    this.dateOfBirth,
    this.followingAnchors = const [],
    this.preferredTags = const [],
    this.totalPosts = 0,
    this.totalFollowers = 0,
    this.totalLikes = 0,
    this.hasSelectedInitialTags = false,
    // --- NEW ---
    this.followedStories = const [],
    this.searchName = "",
    this.reputationScore = 100.0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePicUrl: data['profilePicUrl'] ?? '',
      location: data['location'] ?? 'Bengaluru, IN',
      isAnchor: data['isAnchor'] ?? false,
      dateOfBirth: data['dateOfBirth'],
      followingAnchors: List<String>.from(data['followingAnchors'] ?? []),
      preferredTags: List<String>.from(data['preferredTags'] ?? []),
      totalPosts: data['totalPosts'] ?? 0,
      totalFollowers: data['totalFollowers'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      hasSelectedInitialTags: data['hasSelectedInitialTags'] ?? false,
      // --- NEW ---
      followedStories: List<String>.from(data['followedStories'] ?? []),
      // Ensure we handle missing searchName gracefully
      searchName: data['searchName'] ?? (data['name'] ?? '').toString(),
      reputationScore: (data['reputationScore'] ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePicUrl': profilePicUrl,
      'location': location,
      'isAnchor': isAnchor,
      'dateOfBirth': dateOfBirth,
      'followingAnchors': followingAnchors,
      'preferredTags': preferredTags,
      'totalPosts': totalPosts,
      'totalFollowers': totalFollowers,
      'totalLikes': totalLikes,
      'hasSelectedInitialTags': hasSelectedInitialTags,
      // --- NEW ---
      'followedStories': followedStories,
      'searchName': searchName,
      'reputationScore': reputationScore,
    };
  }
}
