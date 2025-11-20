// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/user_model.dart'; // Import our new model

class AuthProvider with ChangeNotifier {
  // Firebase service instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // The Firebase user object (from Auth)
  User? _firebaseUser;
  // Our custom user data object (from Firestore)
  UserModel? _userModel;
  bool _hasError = false;

  bool get isLoggedIn => _firebaseUser != null;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  bool get hasError => _hasError;

  // This is the dummy list of profile pics for the register screen
  final List<String> availableProfilePics = const [
    'https://i.pravatar.cc/150?img=1',
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=5',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=8',
    'https://i.pravatar.cc/150?img=10',
    'https://i.pravatar.cc/150?img=11',
    'https://i.pravatar.cc/150?img=12',
  ];

  // Constructor
  AuthProvider() {
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Private method to handle auth changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user == null) {
      // User is logged out
      _userModel = null;
      _hasError = false;
    } else {
      // User is logged in, fetch their profile from Firestore
      await _fetchUserModel(user.uid);
    }
    notifyListeners();
  }

  // Private method to get user data from Firestore
  Future<void> _fetchUserModel(String uid) async {
    _hasError = false;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        _hasError = true; // User record not found in Firestore
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching user model: $e");
      _hasError = true;
    }
    notifyListeners();
  }

  Future<void> retryLoadUser() async {
    if (_firebaseUser != null) {
      await _fetchUserModel(_firebaseUser!.uid);
    }
  }

  // Call this to manually refetch user data from Firestore
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _fetchUserModel(_firebaseUser!.uid);
    }
  }

  // --- PUBLIC METHODS FOR UI TO CALL ---

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User user = userCredential.user!;

      // Check if this is a new user
      if (userCredential.additionalUserInfo!.isNewUser) {
        // Create a new user profile in Firestore
        final name = user.displayName ?? 'New User';
        final newUser = UserModel(
          uid: user.uid,
          name: name,
          email: user.email!,
          profilePicUrl:
              user.photoURL ?? availableProfilePics[0], // Use Google pic
          searchName: name.toLowerCase(),
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        _userModel = newUser;
        notifyListeners();
      } else {
        // --- TASK 3 & 2 FIX ---
        // For existing users, update their profile picture and search name
        await _firestore.collection('users').doc(user.uid).update({
          'profilePicUrl': user.photoURL ?? _userModel?.profilePicUrl,
          'searchName': (user.displayName ?? _userModel?.name ?? '').toLowerCase(),
        });
        // The auth listener will fetch the updated model
        // --- END OF FIX ---
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error signing in with Google: $e");
    }
  }

  // Register with Email/Password
  Future<void> registerWithEmail(
      String name, String email, String password, String location) async {
    try {
      // 1. Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User user = userCredential.user!;

      // 2. Create our user profile model, assigning a default pic
      // TASK 2 FIX: The constructor now handles searchName automatically
      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        profilePicUrl: availableProfilePics[0], // Assign default
        location: location,
        searchName: name.toLowerCase(),
      );

      // 3. Save the profile to Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      _userModel = newUser;
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print("Error registering with email: $e");
      rethrow; // Re-throw the error so the UI can catch it
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
