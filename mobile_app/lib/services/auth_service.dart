import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  AuthService() {
    _loadRole(_auth.currentUser).then((_) => notifyListeners());
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _isAdmin = false;
        notifyListeners();
        return;
      }
      await _loadRole(user);
      notifyListeners();
    });
  }

  Future<void> _loadRole(User? user) async {
    if (user == null) {
      _isAdmin = false;
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      _isAdmin = (doc.data()?['role'] == 'admin');
    } catch (_) {
      _isAdmin = false;
    }
  }

  Future<UserProfile?> get currentUserProfile async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      return UserProfile(
        uid: user.uid,
        email: d['email'] as String? ?? user.email,
        displayName: d['displayName'] as String? ?? user.displayName,
        photoURL: d['photoURL'] as String? ?? user.photoURL,
      );
    }
    return UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    if (userCred.user != null) {
      await _upsertUser(userCred.user!);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (userCred.user != null) await _upsertUser(userCred.user!);
  }

  Future<void> registerWithEmail(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (userCred.user != null) await _upsertUser(userCred.user!);
  }

  Future<void> _upsertUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
