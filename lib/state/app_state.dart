// lib/state/app_state.dart - Updated with better Firestore sync

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saveplus_plus/services/auth_service.dart';
import 'package:saveplus_plus/services/firestore_service.dart';
import 'package:saveplus_plus/services/timezone_service.dart';
import 'package:saveplus_plus/services/exchange_rate_service.dart';
import 'package:saveplus_plus/services/alert_service.dart';
import 'package:saveplus_plus/services/budget_analyzer.dart';
import 'package:saveplus_plus/models/transaction_model.dart';
import 'package:saveplus_plus/models/goal_model.dart';

class AppState extends ChangeNotifier {
  final AuthService _auth;
  final FirestoreService _dbSvc;

  AppState(this._auth, this._dbSvc) {
    // 1) Watch for sign-in / sign-out
    _auth.authStateChanges.listen(_onAuthStateChanged);
    // 2) Load preferences
    _loadPreferences();
    // 3) Initialize alert service (will be user-specific once user signs in)
    AlertService.initialize();
  }

  User? _user;
  GoalModel? _goal;
  List<TransactionModel> _todayTxns = [];
  List<TransactionModel> _allTxns = [];
  List<TransactionModel> _dateRangeTxns = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedTimezone = 'Asia/Kuala_Lumpur';
  String _selectedCurrency = 'MYR'; // Default to Malaysian Ringgit
  Map<String, dynamic>? _userProfile;
  
  StreamSubscription<GoalModel?>? _goalSub;
  StreamSubscription<List<TransactionModel>>? _txnSub;
  StreamSubscription<List<TransactionModel>>? _allTxnSub;
  StreamSubscription<List<TransactionModel>>? _dateRangeTxnSub;
  StreamSubscription<Map<String, dynamic>?>? _userProfileSub;
  StreamSubscription<Map<String, dynamic>?>? _userPreferencesSub;

  // -----------------
  // PUBLIC GETTERS
  // -----------------
  User? get user => _user;
  String get uid => _user!.uid;
  GoalModel? get goal => _goal;
  List<TransactionModel> get todayTxns => _todayTxns;
  List<TransactionModel> get allTxns => _allTxns;
  List<TransactionModel> get dateRangeTxns => _dateRangeTxns;
  DateTime get selectedDate => _selectedDate;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedTimezone => _selectedTimezone;
  String get selectedCurrency => _selectedCurrency;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Alert-related getters
  List<AlertModel> get activeAlerts => AlertService.activeAlerts;
  int get unreadAlertCount => AlertService.unreadCount;
  BudgetSettings get budgetSettings => AlertService.budgetSettings;

  // Get currency symbol for display
  String get currencySymbol => ExchangeRateService.getCurrencySymbol(_selectedCurrency);
  
  // Get currency name for display
  String get currencyName => ExchangeRateService.getCurrencyName(_selectedCurrency);

  // Calculate total balance from all transactions
  double get totalBalance {
    return _allTxns.fold<double>(0, (sum, txn) => sum + txn.amount);
  }

  // Calculate balance up to a specific date
  double getBalanceUpToDate(DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _allTxns
        .where((txn) => txn.timestamp.isBefore(endOfDay) || txn.timestamp.isAtSameMomentAs(endOfDay))
        .fold<double>(0, (sum, txn) => sum + txn.amount);
  }

  // Format DateTime according to selected timezone
  String formatTimeWithTimezone(DateTime dateTime) {
    return TimezoneService.formatWithTimezone(dateTime, _selectedTimezone);
  }

  // Format currency amount with selected currency
  String formatCurrency(double amount) {
    return ExchangeRateService.formatCurrency(amount, _selectedCurrency);
  }

  // Format currency amount with custom decimals
  String formatCurrencyWithDecimals(double amount, {int decimals = 2}) {
    final symbol = currencySymbol;
    
    if (_selectedCurrency == 'JPY' || _selectedCurrency == 'KRW' || _selectedCurrency == 'VND') {
      // No decimal places for these currencies
      return '$symbol${amount.toStringAsFixed(0)}';
    } else {
      return '$symbol${amount.toStringAsFixed(decimals)}';
    }
  }

  // -----------------
  // PUBLIC API
  // -----------------
  Future<void> addTransaction(TransactionModel txn) async {
    if (_user == null) return;
    
    // Add transaction to Firestore
    await _dbSvc.addTransaction(_user!.uid, txn);
    
    // Check for large expense alert
    if (txn.amount < 0) {
      final largeExpenseAlert = await BudgetAnalyzer.checkLargeExpense(
        txn,
        budgetSettings,
        formatCurrency,
      );
      
      if (largeExpenseAlert != null) {
        await AlertService.addAlert(largeExpenseAlert);
        notifyListeners();
      }
    }
    
    // Trigger budget analysis after a short delay to allow Firestore to update
    Future.delayed(const Duration(milliseconds: 500), () {
      _analyzeBudgetAndGoals();
    });
  }
  
  Future<void> deleteTransaction(String transactionId) async {
    if (_user == null) return;
    await _dbSvc.deleteTransaction(_user!.uid, transactionId);
    
    // Trigger budget analysis after deletion
    Future.delayed(const Duration(milliseconds: 500), () {
      _analyzeBudgetAndGoals();
    });
  }

  Future<void> setGoal(GoalModel goalModel) async {
    if (_user == null) return;
    await _dbSvc.setGoal(_user!.uid, goalModel);
    
    // Trigger goal analysis
    Future.delayed(const Duration(milliseconds: 500), () {
      _analyzeBudgetAndGoals();
    });
  }
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _updateTransactionsForDate();
    notifyListeners();
  }
  
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _updateTransactionsForDateRange();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    // Save to both local storage and Firestore
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    if (_user != null) {
      try {
        await _dbSvc.updateUserPreferences(_user!.uid, {
          'darkMode': _isDarkMode,
        });
      } catch (e) {
        print('Failed to sync dark mode preference to Firestore: $e');
      }
    }
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    
    // Save to both local storage and Firestore
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    
    if (_user != null) {
      try {
        await _dbSvc.updateUserPreferences(_user!.uid, {
          'notifications': _notificationsEnabled,
        });
      } catch (e) {
        print('Failed to sync notification preference to Firestore: $e');
      }
    }
  }

  Future<void> setTimezone(String timezone) async {
    _selectedTimezone = timezone;
    await TimezoneService.setSelectedTimezone(timezone);
    notifyListeners();
    
    if (_user != null) {
      try {
        await _dbSvc.updateUserPreferences(_user!.uid, {
          'timezone': timezone,
        });
      } catch (e) {
        print('Failed to sync timezone preference to Firestore: $e');
      }
    }
  }

  Future<void> setCurrency(String currency) async {
    _selectedCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);
    notifyListeners();
    
    if (_user != null) {
      try {
        await _dbSvc.updateUserPreferences(_user!.uid, {
          'currency': currency,
        });
      } catch (e) {
        print('Failed to sync currency preference to Firestore: $e');
      }
    }
  }

  // Alert-related methods
  Future<void> markAlertAsRead(String alertId) async {
    await AlertService.markAsRead(alertId);
    notifyListeners();
  }

  Future<void> dismissAlert(String alertId) async {
    await AlertService.dismissAlert(alertId);
    notifyListeners();
  }

  Future<void> clearAllAlerts() async {
    await AlertService.clearAllAlerts();
    notifyListeners();
  }

  Future<void> updateBudgetSettings(BudgetSettings settings) async {
    print('AppState: Updating budget settings...');
    await AlertService.saveBudgetSettings(settings);
    notifyListeners();
    
    // Re-analyze budget after settings change
    Future.delayed(const Duration(milliseconds: 100), () {
      _analyzeBudgetAndGoals();
    });
  }

  // Trigger budget and goal analysis
  Future<void> _analyzeBudgetAndGoals() async {
    if (_user == null) return;
    
    try {
      final alerts = await BudgetAnalyzer.analyzeSpendingAndGoals(
        allTransactions: _allTxns,
        currentGoal: _goal,
        currentBalance: totalBalance,
        budgetSettings: budgetSettings,
        formatCurrency: formatCurrency,
      );
      
      // Add new alerts
      for (final alert in alerts) {
        await AlertService.addAlert(alert);
      }
      
      if (alerts.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      print('Error analyzing budget and goals: $e');
    }
  }

  Future<void> signOut() => _auth.signOut();

  // -----------------
  // INTERNAL
  // -----------------
  void _onAuthStateChanged(User? user) async {
    final previousUser = _user;
    _user = user;
    
    if (_user != null) {
      // User signed in
      if (previousUser?.uid != _user!.uid) {
        // Different user or first sign in
        print('AppState: User signed in: ${_user!.uid}');
        
        // Initialize/switch alert service to new user
        await AlertService.switchUser(_user!.uid);
        
        _startFirestoreListeners(_user!.uid);
      }
    } else {
      // User signed out
      print('AppState: User signed out');
      
      // Clear alert service data
      AlertService.clearUserData();
      
      _stopFirestoreListeners();
    }
    
    notifyListeners();
  }

  void _startFirestoreListeners(String uid) {
    // 1) Listen for user profile changes
    _userProfileSub = _dbSvc.watchUserProfile(uid).listen((profile) {
      _userProfile = profile;
      notifyListeners();
    });

    // 2) Listen for user preferences changes
    _userPreferencesSub = _dbSvc.watchUserPreferences(uid).listen((preferences) {
      if (preferences != null) {
        _syncPreferencesFromFirestore(preferences);
      }
    });

    // 3) Listen for goal changes
    _goalSub = _dbSvc.watchGoal(uid).listen((g) {
      _goal = g;
      notifyListeners();
      
      // Analyze goals when goal changes
      Future.delayed(const Duration(milliseconds: 100), () {
        _analyzeBudgetAndGoals();
      });
    });

    // 4) Listen for ALL transactions (for balance calculation)
    _allTxnSub = _dbSvc.watchAllTransactions(uid).listen((list) {
      _allTxns = list;
      notifyListeners();
      
      // Analyze budget when transactions change
      Future.delayed(const Duration(milliseconds: 100), () {
        _analyzeBudgetAndGoals();
      });
    });

    // 5) Listen for today's transactions
    _updateTransactionsForDate();
    
    // 6) Listen for date range transactions
    _updateTransactionsForDateRange();
  }

  /// Sync preferences from Firestore to local state
  void _syncPreferencesFromFirestore(Map<String, dynamic> preferences) {
    bool hasChanges = false;

    // Sync currency
    final firestoreCurrency = preferences['currency'] as String?;
    if (firestoreCurrency != null && firestoreCurrency != _selectedCurrency) {
      _selectedCurrency = firestoreCurrency;
      hasChanges = true;
      // Also save to local storage
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('selectedCurrency', firestoreCurrency);
      });
    }

    // Sync timezone
    final firestoreTimezone = preferences['timezone'] as String?;
    if (firestoreTimezone != null && firestoreTimezone != _selectedTimezone) {
      _selectedTimezone = firestoreTimezone;
      hasChanges = true;
      TimezoneService.setSelectedTimezone(firestoreTimezone);
    }

    // Sync dark mode
    final firestoreDarkMode = preferences['darkMode'] as bool?;
    if (firestoreDarkMode != null && firestoreDarkMode != _isDarkMode) {
      _isDarkMode = firestoreDarkMode;
      hasChanges = true;
      // Also save to local storage
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', firestoreDarkMode);
      });
    }

    // Sync notifications
    final firestoreNotifications = preferences['notifications'] as bool?;
    if (firestoreNotifications != null && firestoreNotifications != _notificationsEnabled) {
      _notificationsEnabled = firestoreNotifications;
      hasChanges = true;
      // Also save to local storage
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('notificationsEnabled', firestoreNotifications);
      });
    }

    if (hasChanges) {
      print('AppState: Synced preferences from Firestore');
      notifyListeners();
    }
  }
  
  void _updateTransactionsForDate() {
    if (_user == null) return;
    
    _txnSub?.cancel();
    _txnSub = _dbSvc.watchTransactions(_user!.uid, _selectedDate).listen((list) {
      _todayTxns = list;
      notifyListeners();
    });
  }
  
  void _updateTransactionsForDateRange() {
    if (_user == null) return;
    
    _dateRangeTxnSub?.cancel();
    _dateRangeTxnSub = _dbSvc.watchTransactionsRange(
      _user!.uid, 
      _startDate, 
      _endDate
    ).listen((list) {
      _dateRangeTxns = list;
      notifyListeners();
    });
  }

  void _stopFirestoreListeners() {
    _goalSub?.cancel();
    _txnSub?.cancel();
    _allTxnSub?.cancel();
    _dateRangeTxnSub?.cancel();
    _userProfileSub?.cancel();
    _userPreferencesSub?.cancel();
    
    // Clear data
    _goal = null;
    _todayTxns = [];
    _allTxns = [];
    _dateRangeTxns = [];
    _userProfile = null;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _selectedTimezone = await TimezoneService.getSelectedTimezone();
    _selectedCurrency = prefs.getString('selectedCurrency') ?? 'MYR'; // Default to MYR
    notifyListeners();
  }
}