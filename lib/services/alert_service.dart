// lib/services/alert_service.dart - Updated with Firestore budget sync

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType {
  dailyBudgetExceeded,
  weeklyBudgetExceeded,
  categoryBudgetExceeded,
  lowBalance,
  largeExpense,
  goalDeadlineApproaching,
  goalMilestoneReached,
  goalProgressReminder,
  savingsSlowdown,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  bool isRead;
  bool isDismissed;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    required this.createdAt,
    this.data,
    this.isRead = false,
    this.isDismissed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'severity': severity.index,
      'title': title,
      'message': message,
      'actionText': actionText,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'data': data,
      'isRead': isRead,
      'isDismissed': isDismissed,
    };
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      type: AlertType.values[json['type'] ?? 0],
      severity: AlertSeverity.values[json['severity'] ?? 0],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      actionText: json['actionText'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      isDismissed: json['isDismissed'] ?? false,
    );
  }
}

class BudgetSettings {
  final double? dailyBudget;
  final double? weeklyBudget;
  final double? monthlyBudget;
  final Map<String, double> categoryBudgets;
  final double lowBalanceThreshold;
  final double largeExpenseThreshold;
  final bool enableDailyAlerts;
  final bool enableWeeklyAlerts;
  final bool enableCategoryAlerts;
  final bool enableGoalAlerts;

  BudgetSettings({
    this.dailyBudget,
    this.weeklyBudget,
    this.monthlyBudget,
    this.categoryBudgets = const {},
    this.lowBalanceThreshold = 100.0,
    this.largeExpenseThreshold = 500.0,
    this.enableDailyAlerts = true,
    this.enableWeeklyAlerts = true,
    this.enableCategoryAlerts = true,
    this.enableGoalAlerts = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyBudget': dailyBudget,
      'weeklyBudget': weeklyBudget,
      'monthlyBudget': monthlyBudget,
      'categoryBudgets': categoryBudgets,
      'lowBalanceThreshold': lowBalanceThreshold,
      'largeExpenseThreshold': largeExpenseThreshold,
      'enableDailyAlerts': enableDailyAlerts,
      'enableWeeklyAlerts': enableWeeklyAlerts,
      'enableCategoryAlerts': enableCategoryAlerts,
      'enableGoalAlerts': enableGoalAlerts,
    };
  }

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    return BudgetSettings(
      dailyBudget: json['dailyBudget']?.toDouble(),
      weeklyBudget: json['weeklyBudget']?.toDouble(),
      monthlyBudget: json['monthlyBudget']?.toDouble(),
      categoryBudgets: json['categoryBudgets'] != null 
          ? Map<String, double>.from(json['categoryBudgets'].map((k, v) => MapEntry(k, v.toDouble())))
          : {},
      lowBalanceThreshold: json['lowBalanceThreshold']?.toDouble() ?? 100.0,
      largeExpenseThreshold: json['largeExpenseThreshold']?.toDouble() ?? 500.0,
      enableDailyAlerts: json['enableDailyAlerts'] ?? true,
      enableWeeklyAlerts: json['enableWeeklyAlerts'] ?? true,
      enableCategoryAlerts: json['enableCategoryAlerts'] ?? true,
      enableGoalAlerts: json['enableGoalAlerts'] ?? true,
    );
  }

  // Convert from Firestore document data
  factory BudgetSettings.fromFirestore(Map<String, dynamic> data) {
    return BudgetSettings(
      dailyBudget: data['dailyBudget']?.toDouble(),
      weeklyBudget: data['weeklyBudget']?.toDouble(),
      monthlyBudget: data['monthlyBudget']?.toDouble(),
      categoryBudgets: data['categoryBudgets'] != null 
          ? Map<String, double>.from(data['categoryBudgets'].map((k, v) => MapEntry(k, v.toDouble())))
          : {},
      lowBalanceThreshold: data['lowBalanceThreshold']?.toDouble() ?? 100.0,
      largeExpenseThreshold: data['largeExpenseThreshold']?.toDouble() ?? 500.0,
      enableDailyAlerts: data['enableDailyAlerts'] ?? true,
      enableWeeklyAlerts: data['enableWeeklyAlerts'] ?? true,
      enableCategoryAlerts: data['enableCategoryAlerts'] ?? true,
      enableGoalAlerts: data['enableGoalAlerts'] ?? true,
    );
  }

  // Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'dailyBudget': dailyBudget,
      'weeklyBudget': weeklyBudget,
      'monthlyBudget': monthlyBudget,
      'categoryBudgets': categoryBudgets,
      'lowBalanceThreshold': lowBalanceThreshold,
      'largeExpenseThreshold': largeExpenseThreshold,
      'enableDailyAlerts': enableDailyAlerts,
      'enableWeeklyAlerts': enableWeeklyAlerts,
      'enableCategoryAlerts': enableCategoryAlerts,
      'enableGoalAlerts': enableGoalAlerts,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BudgetSettings copyWith({
    double? dailyBudget,
    double? weeklyBudget,
    double? monthlyBudget,
    Map<String, double>? categoryBudgets,
    double? lowBalanceThreshold,
    double? largeExpenseThreshold,
    bool? enableDailyAlerts,
    bool? enableWeeklyAlerts,
    bool? enableCategoryAlerts,
    bool? enableGoalAlerts,
  }) {
    return BudgetSettings(
      dailyBudget: dailyBudget ?? this.dailyBudget,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      largeExpenseThreshold: largeExpenseThreshold ?? this.largeExpenseThreshold,
      enableDailyAlerts: enableDailyAlerts ?? this.enableDailyAlerts,
      enableWeeklyAlerts: enableWeeklyAlerts ?? this.enableWeeklyAlerts,
      enableCategoryAlerts: enableCategoryAlerts ?? this.enableCategoryAlerts,
      enableGoalAlerts: enableGoalAlerts ?? this.enableGoalAlerts,
    );
  }
}

class AlertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _currentUserId;
  static List<AlertModel> _alerts = [];
  static BudgetSettings _budgetSettings = BudgetSettings();
  
  static List<AlertModel> get alerts => _alerts;
  static BudgetSettings get budgetSettings => _budgetSettings;
  
  /// Initialize the alert service for a specific user
  static Future<void> initialize([String? userId]) async {
    print('AlertService: Initializing for user: $userId');
    
    // If userId is provided, switch to that user
    if (userId != null) {
      _currentUserId = userId;
    }
    
    // Load user-specific data
    await _loadAlerts();
    await _loadBudgetSettings();
    print('AlertService: Initialization complete for user: $_currentUserId');
  }
  
  /// Switch to a different user (clears current data and loads new user's data)
  static Future<void> switchUser(String userId) async {
    print('AlertService: Switching from user $_currentUserId to $userId');
    
    // Clear current data
    _alerts.clear();
    _budgetSettings = BudgetSettings();
    
    // Switch to new user
    _currentUserId = userId;
    
    // Load new user's data
    await _loadAlerts();
    await _loadBudgetSettings();
    
    print('AlertService: Successfully switched to user: $userId');
  }
  
  /// Clear all data (for sign out)
  static void clearUserData() {
    print('AlertService: Clearing user data');
    _currentUserId = null;
    _alerts.clear();
    _budgetSettings = BudgetSettings();
  }
  
  /// Get user-specific storage keys
  static String _getAlertsKey() {
    return _currentUserId != null ? 'user_alerts_$_currentUserId' : 'user_alerts';
  }
  
  /// Load alerts from local storage (user-specific)
  static Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJsonString = prefs.getString(_getAlertsKey());
      
      if (alertsJsonString != null) {
        final List<dynamic> alertsJson = json.decode(alertsJsonString);
        _alerts = alertsJson.map((alertData) => AlertModel.fromJson(alertData)).toList();
        
        // Remove old alerts (older than 7 days)
        final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
        _alerts.removeWhere((alert) => alert.createdAt.isBefore(cutoffDate));
        
        print('AlertService: Loaded ${_alerts.length} alerts for user $_currentUserId');
      } else {
        _alerts = [];
        print('AlertService: No existing alerts found for user $_currentUserId');
      }
    } catch (e) {
      print('AlertService: Error loading alerts: $e');
      _alerts = [];
    }
  }
  
  /// Save alerts to local storage (user-specific)
  static Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts.map((alert) => alert.toJson()).toList();
      final alertsJsonString = json.encode(alertsJson);
      
      await prefs.setString(_getAlertsKey(), alertsJsonString);
      print('AlertService: Saved ${_alerts.length} alerts for user $_currentUserId');
    } catch (e) {
      print('AlertService: Error saving alerts: $e');
    }
  }
  
  /// Load budget settings from Firestore (primary) with local fallback
  static Future<void> _loadBudgetSettings() async {
    if (_currentUserId == null) {
      print('AlertService: No user ID, using default budget settings');
      _budgetSettings = BudgetSettings();
      return;
    }

    try {
      // Try to load from Firestore first
      print('AlertService: Loading budget settings from Firestore for user $_currentUserId');
      final budgetDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('budget')
          .get();

      if (budgetDoc.exists && budgetDoc.data() != null) {
        _budgetSettings = BudgetSettings.fromFirestore(budgetDoc.data()!);
        print('AlertService: ✅ Loaded budget settings from Firestore: Daily=${_budgetSettings.dailyBudget}, Weekly=${_budgetSettings.weeklyBudget}');
        
        // Save to local storage as backup
        await _saveBudgetSettingsLocally(_budgetSettings);
      } else {
        print('AlertService: No budget settings in Firestore, trying local storage');
        await _loadBudgetSettingsFromLocal();
      }
    } catch (e) {
      print('AlertService: Error loading from Firestore, falling back to local: $e');
      await _loadBudgetSettingsFromLocal();
    }
  }

  /// Load budget settings from local storage (fallback)
  static Future<void> _loadBudgetSettingsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsKey = _currentUserId != null ? 'budget_settings_$_currentUserId' : 'budget_settings';
      final settingsJsonString = prefs.getString(settingsKey);
      
      if (settingsJsonString != null) {
        final settingsJson = json.decode(settingsJsonString);
        _budgetSettings = BudgetSettings.fromJson(settingsJson);
        print('AlertService: Loaded budget settings from local storage for user $_currentUserId');
      } else {
        _budgetSettings = BudgetSettings();
        print('AlertService: No local budget settings found, using defaults for user $_currentUserId');
      }
    } catch (e) {
      print('AlertService: Error loading budget settings from local: $e');
      _budgetSettings = BudgetSettings();
    }
  }

  /// Save budget settings to local storage
  static Future<void> _saveBudgetSettingsLocally(BudgetSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsKey = _currentUserId != null ? 'budget_settings_$_currentUserId' : 'budget_settings';
      final settingsJsonString = json.encode(settings.toJson());
      await prefs.setString(settingsKey, settingsJsonString);
      print('AlertService: Budget settings saved to local storage');
    } catch (e) {
      print('AlertService: Error saving budget settings locally: $e');
    }
  }
  
  /// Save budget settings to both Firestore and local storage
  static Future<void> saveBudgetSettings(BudgetSettings settings) async {
    if (_currentUserId == null) {
      print('AlertService: Cannot save budget settings - no user logged in');
      return;
    }

    try {
      print('AlertService: Saving budget settings for user $_currentUserId...');
      print('AlertService: Daily Budget: ${settings.dailyBudget}');
      print('AlertService: Weekly Budget: ${settings.weeklyBudget}');
      print('AlertService: Category budgets: ${settings.categoryBudgets}');
      
      _budgetSettings = settings;

      // Save to Firestore (primary)
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('budget')
          .set(settings.toFirestore());
      
      print('AlertService: ✅ Budget settings saved to Firestore!');
      
      // Save to local storage (backup)
      await _saveBudgetSettingsLocally(settings);
      
      // Verify the save worked by reading it back
      final verifyDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('budget')
          .get();
          
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data()!;
        print('AlertService: ✅ Verification - Daily Budget: ${verifyData['dailyBudget']}');
        print('AlertService: ✅ Verification - Weekly Budget: ${verifyData['weeklyBudget']}');
      }
      
    } catch (e) {
      print('AlertService: ❌ Error saving budget settings: $e');
      print('AlertService: Error type: ${e.runtimeType}');
      
      // Fallback to local storage only
      try {
        await _saveBudgetSettingsLocally(settings);
        print('AlertService: Fallback: Saved to local storage only');
      } catch (localError) {
        print('AlertService: ❌ Even local save failed: $localError');
        rethrow;
      }
    }
  }
  
  /// Add a new alert
  static Future<void> addAlert(AlertModel alert) async {
    try {
      // Check if similar alert already exists (avoid duplicates)
      final existingIndex = _alerts.indexWhere(
        (a) => a.type == alert.type && a.title == alert.title && !a.isDismissed,
      );
      
      if (existingIndex == -1) {
        _alerts.insert(0, alert);
        await _saveAlerts();
        print('AlertService: Added new alert for user $_currentUserId: ${alert.title}');
      } else {
        print('AlertService: Duplicate alert prevented for user $_currentUserId: ${alert.title}');
      }
    } catch (e) {
      print('AlertService: Error adding alert: $e');
    }
  }
  
  /// Mark alert as read
  static Future<void> markAsRead(String alertId) async {
    try {
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex].isRead = true;
        await _saveAlerts();
        print('AlertService: Marked alert as read for user $_currentUserId: $alertId');
      }
    } catch (e) {
      print('AlertService: Error marking alert as read: $e');
    }
  }
  
  /// Dismiss alert
  static Future<void> dismissAlert(String alertId) async {
    try {
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex].isDismissed = true;
        await _saveAlerts();
        print('AlertService: Dismissed alert for user $_currentUserId: $alertId');
      }
    } catch (e) {
      print('AlertService: Error dismissing alert: $e');
    }
  }
  
  /// Clear all alerts
  static Future<void> clearAllAlerts() async {
    try {
      _alerts.clear();
      await _saveAlerts();
      print('AlertService: Cleared all alerts for user $_currentUserId');
    } catch (e) {
      print('AlertService: Error clearing alerts: $e');
    }
  }
  
  /// Get unread alert count
  static int get unreadCount => _alerts.where((a) => !a.isRead && !a.isDismissed).length;
  
  /// Get active alerts (not dismissed)
  static List<AlertModel> get activeAlerts => _alerts.where((a) => !a.isDismissed).toList();
}