import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = User(
          uid: userCredential.user!.uid,
          email: email,
          username: username,
        );

        await _firestore.collection('users').doc(user.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'username': username.toLowerCase(),
          'followers': [],
          'following': [],
          'profileImageUrl': null,
        });
        return user;
      }
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
    return null;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        return User.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
} 