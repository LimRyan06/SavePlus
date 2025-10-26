// lib/services/auth_service.dart - Updated with user document creation

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign up a new user and create their Firestore document
  Future<User?> signUp(String email, String pw) async {
    try {
      // 1. Create the user account in Firebase Authentication
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: pw
      );
      
      final user = cred.user;
      if (user != null) {
        // 2. Create the user document in Firestore
        await _createUserDocument(user, email);
        print('✅ New user created: ${user.uid}');
        print('✅ User document created in Firestore');
      }
      
      return user;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in existing user
  Future<User?> signIn(String email, String pw) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: pw
      );
      
      final user = cred.user;
      if (user != null) {
        // Check if user document exists, create if it doesn't
        await _ensureUserDocumentExists(user, email);
      }
      
      return user;
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() => _auth.signOut();

  /// Create a new user document in Firestore
  Future<void> _createUserDocument(User user, String email) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      
      // Create the main user document with basic info
      await userDocRef.set({
        'uid': user.uid,
        'email': email,
        'displayName': user.displayName ?? email.split('@')[0], // Use email prefix as default name
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // You can update this as needed
      });

      // Create initial settings document
      await userDocRef.collection('settings').doc('preferences').set({
        'currency': 'MYR', // Default currency
        'timezone': 'Asia/Kuala_Lumpur', // Default timezone
        'darkMode': false,
        'notifications': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create initial budget settings document  
      await userDocRef.collection('settings').doc('budget').set({
        'dailyBudget': null,
        'weeklyBudget': null,
        'monthlyBudget': null,
        'categoryBudgets': {},
        'lowBalanceThreshold': 100.0,
        'largeExpenseThreshold': 500.0,
        'enableDailyAlerts': true,
        'enableWeeklyAlerts': true,
        'enableCategoryAlerts': true,
        'enableGoalAlerts': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ User document structure created for ${user.uid}');
      
    } catch (e) {
      print('Error creating user document: $e');
      // Don't rethrow - user account was created successfully, 
      // document creation failure shouldn't prevent login
    }
  }

  /// Ensure user document exists (for existing users who might not have documents)
  Future<void> _ensureUserDocumentExists(User user, String email) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        print('🔄 User document missing, creating for existing user: ${user.uid}');
        await _createUserDocument(user, email);
      } else {
        // Update last sign in time
        await userDocRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
      // Don't rethrow - user can still use the app
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User profile updated for $uid');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}