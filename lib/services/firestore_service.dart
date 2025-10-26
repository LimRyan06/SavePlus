// lib/services/firestore_service.dart - Updated with user profile methods

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveplus_plus/models/transaction_model.dart';
import 'package:saveplus_plus/models/goal_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =================== USER PROFILE METHODS ===================
  
  /// Stream user profile data
  Stream<Map<String, dynamic>?> watchUserProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  /// Get user profile data once
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    return _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream user preferences
  Stream<Map<String, dynamic>?> watchUserPreferences(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  /// Update user preferences
  Future<void> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .set(preferences, SetOptions(merge: true));
  }

  // =================== TRANSACTION METHODS ===================

  /// Streams transactions for the given user on a specific date.
  Stream<List<TransactionModel>> watchTransactions(String uid, DateTime date) {
    // build a 24-hour window for the specified date
    final start = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final end = Timestamp.fromDate(
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
    );

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromDoc(doc)).toList());
  }
  
  /// Streams ALL transactions for the given user (for balance calculation)
  Stream<List<TransactionModel>> watchAllTransactions(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromDoc(doc)).toList());
  }
  
  /// Streams transactions for the given user within a date range.
  Stream<List<TransactionModel>> watchTransactionsRange(
    String uid, 
    DateTime startDate, 
    DateTime endDate
  ) {
    // Convert dates to Firestore Timestamps, ensuring we get full days
    final start = Timestamp.fromDate(DateTime(
      startDate.year, 
      startDate.month, 
      startDate.day
    ));
    
    // Add a day to endDate to make the range inclusive
    final end = Timestamp.fromDate(
      DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1)),
    );

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromDoc(doc)).toList());
  }

  /// Adds a new transaction to Firestore with enhanced logging
  Future<void> addTransaction(String uid, TransactionModel txn) async {
    try {
      print('🔵 Saving transaction for user: $uid');
      print('🔵 Transaction data: ${txn.toMap()}');
      
      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add(txn.toMap());
          
      print('Transaction saved successfully to Firestore!');
    } catch (e) {
      print('Error saving transaction to Firestore: $e');
      rethrow;
    }
  }
  
  /// Deletes a transaction from Firestore.
  Future<void> deleteTransaction(String uid, String transactionId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // =================== GOAL METHODS ===================

  /// Streams the user's savings goal (or `null` if none set).
  Stream<GoalModel?> watchGoal(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('goal')
        .snapshots()
        .map((snap) => snap.exists ? GoalModel.fromDoc(snap) : null);
  }

  /// Sets or updates the user's savings goal.
  Future<void> setGoal(String uid, GoalModel goal) async {
    try {
      print('Saving goal for user: $uid');
      print('Goal data: ${goal.toMap()}');
      
      await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('goal')
          .set(goal.toMap());
          
      print('Goal saved successfully to Firestore!');
    } catch (e) {
      print('Error saving goal to Firestore: $e');
      rethrow;
    }
  }

  // =================== ANALYTICS METHODS ===================

  /// Get transaction count for user (useful for analytics/reset confirmation)
  Future<int> getTransactionCount(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }

  /// Get user's total balance
  Future<double> getUserBalance(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();
          
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        total += amount;
      }
      
      return total;
    } catch (e) {
      print('Error calculating user balance: $e');
      return 0;
    }
  }

  /// Check if user has any data (for account management)
  Future<bool> userHasData(String uid) async {
    try {
      // Check if user has any transactions
      final transactionsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .limit(1)
          .get();
          
      if (transactionsSnapshot.docs.isNotEmpty) {
        return true;
      }
      
      // Check if user has a goal
      final goalSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('goal')
          .get();
          
      return goalSnapshot.exists;
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }
}