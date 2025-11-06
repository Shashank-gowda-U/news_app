// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';

// A dummy model for our user.
// Later, this will come from Firebase.
class DummyUser {
  final String uid;
  final String name;
  final String email;
  final String profilePicUrl;
  final String location;
  final bool isAnchor;
  final String? dateOfBirth; // For anchors
  final List<String> followingAnchors; // List of anchor IDs
  final List<String> preferredTags;

  // --- NEW STATS ---
  final int totalPosts;
  final int totalFollowers;
  final int totalLikes;
  // --- END OF NEW STATS ---

  DummyUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePicUrl,
    this.location = "Bengaluru, IN",
    this.isAnchor = false,
    this.dateOfBirth,
    this.followingAnchors = const ['anchor_jane'], // Following Jane by default
    this.preferredTags = const ['science', 'technology'],
    // --- NEW STATS ---
    this.totalPosts = 0,
    this.totalFollowers = 0,
    this.totalLikes = 0,
    // --- END OF NEW STATS ---
  });
}

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  DummyUser? _user;

  bool get isLoggedIn => _isLoggedIn;
  DummyUser? get user => _user;

  // This is a dummy list of profile pics for the register screen
  final List<String> availableProfilePics = [
    'https://i.pravatar.cc/150?img=1',
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=5',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=8',
    'https://i.pravatar.cc/150?img=10',
    'https://i.pravatar.cc/150?img=11',
    'https://i.pravatar.cc/150?img=12',
  ];

  void login(String email, String password) {
    // In a real app, you'd call Firebase here.
    // For now, we just log in successfully.
    _isLoggedIn = true;
    _user = DummyUser(
      uid: 'dummy_user_123',
      name: 'Logan (Your Name)',
      email: email,
      profilePicUrl: 'https://i.pravatar.cc/150?img=12',
      isAnchor: true, // Let's make the dummy user an anchor
      dateOfBirth: 'Jan 1, 2000',
      // --- ADDED DUMMY STATS ---
      totalPosts: 32,
      totalFollowers: 125,
      totalLikes: 1400,
      // --- END OF DUMMY STATS ---
    );
    notifyListeners(); // Tell the app to rebuild
  }

  void register(
      String name, String email, String password, String profilePicUrl) {
    // Dummy register logic
    _isLoggedIn = true;
    _user = DummyUser(
      uid: 'dummy_user_123',
      name: name,
      email: email,
      profilePicUrl: profilePicUrl,
      isAnchor: false, // New users are not anchors by default
    );
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _user = null;
    notifyListeners(); // Tell the app to rebuild
  }
}
