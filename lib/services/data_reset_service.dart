// lib/services/data_reset_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saveplus_plus/services/exchange_rate_service.dart';

class DataResetService {
  static const String _resetConfirmationKey = 'reset_confirmation_';
  
  /// Reset all user data (transactions and goals)
  static Future<bool> resetAllData(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // Delete all transactions
      final transactionsRef = firestore
          .collection('users')
          .doc(userId)
          .collection('transactions');
          
      final transactionsSnapshot = await transactionsRef.get();
      for (final doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete goal
      final goalRef = firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('goal');
      batch.delete(goalRef);
      
      // Execute batch delete
      await batch.commit();
      
      // Clear local cache
      await _clearLocalCache();
      
      return true;
    } catch (e) {
      print('Error resetting data: $e');
      return false;
    }
  }
  
  /// Reset only transactions (keep goals and settings)
  static Future<bool> resetTransactionsOnly(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // Delete all transactions
      final transactionsRef = firestore
          .collection('users')
          .doc(userId)
          .collection('transactions');
          
      final transactionsSnapshot = await transactionsRef.get();
      for (final doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Execute batch delete
      await batch.commit();
      
      // Clear transaction cache only
      await _clearTransactionCache();
      
      return true;
    } catch (e) {
      print('Error resetting transactions: $e');
      return false;
    }
  }
  
  /// Reset only goals (keep transactions and settings)
  static Future<bool> resetGoalsOnly(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Delete goal
      await firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('goal')
          .delete();
      
      return true;
    } catch (e) {
      print('Error resetting goals: $e');
      return false;
    }
  }
  
  /// Get transaction count for confirmation
  static Future<int> getTransactionCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }
  
  /// Get total balance for confirmation
  static Future<double> getTotalBalance(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
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
      print('Error getting total balance: $e');
      return 0;
    }
  }
  
  /// Check if user has data to reset
  static Future<bool> hasDataToReset(String userId) async {
    try {
      // Check transactions
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .limit(1)
          .get();
          
      if (transactionsSnapshot.docs.isNotEmpty) {
        return true;
      }
      
      // Check goals
      final goalSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('goal')
          .get();
          
      if (goalSnapshot.exists) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking data: $e');
      return false;
    }
  }
  
  /// Store reset confirmation timestamp
  static Future<void> storeResetConfirmation(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_resetConfirmationKey$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error storing reset confirmation: $e');
    }
  }
  
  /// Check if reset was recent (within last 5 minutes)
  static Future<bool> wasRecentlyReset(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('$_resetConfirmationKey$userId');
      
      if (timestamp == null) return false;
      
      final resetTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      return now.difference(resetTime).inMinutes < 5;
    } catch (e) {
      print('Error checking reset time: $e');
      return false;
    }
  }
  
  /// Clear all local cache
  static Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear exchange rate cache
      await ExchangeRateService.clearCache();
      
      // Clear any other app-specific cache
      // Note: Don't clear user preferences like currency, timezone, dark mode
      final keysToKeep = [
        'isDarkMode',
        'notificationsEnabled',
        'selectedCurrency',
        'selectedTimezone',
      ];
      
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (!keysToKeep.contains(key) && !key.startsWith('reset_confirmation_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing local cache: $e');
    }
  }
  
  /// Clear transaction-related cache only
  static Future<void> _clearTransactionCache() async {
    try {
      // Clear exchange rate cache since it's transaction-related
      await ExchangeRateService.clearCache();
    } catch (e) {
      print('Error clearing transaction cache: $e');
    }
  }
}