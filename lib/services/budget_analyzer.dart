// lib/services/budget_analyzer.dart - Fixed version

import 'package:saveplus_plus/models/transaction_model.dart';
import 'package:saveplus_plus/models/goal_model.dart';
import 'package:saveplus_plus/services/alert_service.dart';

class BudgetAnalyzer {
  /// Analyze spending and generate appropriate alerts
  static Future<List<AlertModel>> analyzeSpendingAndGoals({
    required List<TransactionModel> allTransactions,
    required GoalModel? currentGoal,
    required double currentBalance,
    required BudgetSettings budgetSettings,
    required String Function(double) formatCurrency,
  }) async {
    final alerts = <AlertModel>[];
    
    // Only analyze if we have transactions and reasonable balance
    if (allTransactions.isEmpty || currentBalance < -10000) {
      return alerts; // Skip analysis if data looks wrong
    }
    
    // 1. Budget Spending Alerts
    if (budgetSettings.enableDailyAlerts || budgetSettings.enableWeeklyAlerts) {
      alerts.addAll(await _analyzeBudgetSpending(
        allTransactions, 
        budgetSettings, 
        formatCurrency
      ));
    }
    
    // 2. Category Budget Alerts
    if (budgetSettings.enableCategoryAlerts) {
      alerts.addAll(await _analyzeCategoryBudgets(
        allTransactions, 
        budgetSettings, 
        formatCurrency
      ));
    }
    
    // 3. Low Balance Alerts (only if balance is reasonable)
    if (currentBalance > -1000) { // Avoid false alarms
      alerts.addAll(await _analyzeLowBalance(
        currentBalance, 
        budgetSettings, 
        formatCurrency
      ));
    }
    
    // 4. Goal-Related Alerts
    if (budgetSettings.enableGoalAlerts && currentGoal != null && currentBalance > 0) {
      alerts.addAll(await _analyzeGoalProgress(
        currentGoal, 
        currentBalance, 
        allTransactions, 
        formatCurrency
      ));
    }
    
    return alerts;
  }
  
  /// Analyze daily and weekly budget spending
  static Future<List<AlertModel>> _analyzeBudgetSpending(
    List<TransactionModel> transactions,
    BudgetSettings settings,
    String Function(double) formatCurrency,
  ) async {
    final alerts = <AlertModel>[];
    final now = DateTime.now();
    
    // Daily budget check
    if (settings.enableDailyAlerts && settings.dailyBudget != null) {
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayExpenses = transactions
          .where((t) => t.amount < 0 && t.timestamp.isAfter(todayStart))
          .fold<double>(0, (sum, t) => sum + t.amount.abs());
      
      final dailyBudget = settings.dailyBudget!;
      
      if (dailyBudget > 0 && todayExpenses > 0) {
        final percentUsed = (todayExpenses / dailyBudget) * 100;
        
        if (percentUsed >= 100) {
          alerts.add(AlertModel(
            id: 'daily_budget_exceeded_${now.day}',
            type: AlertType.dailyBudgetExceeded,
            severity: AlertSeverity.critical,
            title: 'Daily Budget Exceeded!',
            message: 'You\'ve spent ${formatCurrency(todayExpenses)} today, exceeding your daily budget of ${formatCurrency(dailyBudget)} by ${formatCurrency(todayExpenses - dailyBudget)}.',
            actionText: 'Review Spending',
            createdAt: now,
            data: {
              'spent': todayExpenses,
              'budget': dailyBudget,
              'overage': todayExpenses - dailyBudget,
            },
          ));
        } else if (percentUsed >= 80) {
          alerts.add(AlertModel(
            id: 'daily_budget_warning_${now.day}',
            type: AlertType.dailyBudgetExceeded,
            severity: AlertSeverity.warning,
            title: 'Daily Budget Warning',
            message: 'You\'ve used ${percentUsed.toInt()}% of your daily budget (${formatCurrency(todayExpenses)} of ${formatCurrency(dailyBudget)}).',
            actionText: 'Check Budget',
            createdAt: now,
            data: {
              'spent': todayExpenses,
              'budget': dailyBudget,
              'percentage': percentUsed,
            },
          ));
        }
      }
    }
    
    // Weekly budget check
    if (settings.enableWeeklyAlerts && settings.weeklyBudget != null) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      final weekExpenses = transactions
          .where((t) => t.amount < 0 && t.timestamp.isAfter(weekStartDay))
          .fold<double>(0, (sum, t) => sum + t.amount.abs());
      
      final weeklyBudget = settings.weeklyBudget!;
      
      if (weeklyBudget > 0 && weekExpenses > 0) {
        final percentUsed = (weekExpenses / weeklyBudget) * 100;
        
        if (percentUsed >= 100) {
          alerts.add(AlertModel(
            id: 'weekly_budget_exceeded_${weekStart.day}',
            type: AlertType.weeklyBudgetExceeded,
            severity: AlertSeverity.critical,
            title: 'Weekly Budget Exceeded!',
            message: 'You\'ve spent ${formatCurrency(weekExpenses)} this week, exceeding your weekly budget of ${formatCurrency(weeklyBudget)}.',
            actionText: 'Review Week',
            createdAt: now,
            data: {
              'spent': weekExpenses,
              'budget': weeklyBudget,
              'overage': weekExpenses - weeklyBudget,
            },
          ));
        } else if (percentUsed >= 80) {
          alerts.add(AlertModel(
            id: 'weekly_budget_warning_${weekStart.day}',
            type: AlertType.weeklyBudgetExceeded,
            severity: AlertSeverity.warning,
            title: 'Weekly Budget Warning', 
            message: 'You\'ve used ${percentUsed.toInt()}% of your weekly budget this week.',
            actionText: 'Check Budget',
            createdAt: now,
            data: {
              'spent': weekExpenses,
              'budget': weeklyBudget,
              'percentage': percentUsed,
            },
          ));
        }
      }
    }
    
    return alerts;
  }
  
  /// Analyze category-specific budget spending
  static Future<List<AlertModel>> _analyzeCategoryBudgets(
    List<TransactionModel> transactions,
    BudgetSettings settings,
    String Function(double) formatCurrency,
  ) async {
    final alerts = <AlertModel>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    for (final entry in settings.categoryBudgets.entries) {
      final category = entry.key;
      final budget = entry.value;
      
      if (budget <= 0) continue; // Skip invalid budgets
      
      final categoryExpenses = transactions
          .where((t) => t.amount < 0 && 
                       t.category == category && 
                       t.timestamp.isAfter(monthStart))
          .fold<double>(0, (sum, t) => sum + t.amount.abs());
      
      if (categoryExpenses > 0) {
        final percentUsed = (categoryExpenses / budget) * 100;
        
        if (percentUsed >= 100) {
          alerts.add(AlertModel(
            id: 'category_budget_exceeded_${category}_${now.month}',
            type: AlertType.categoryBudgetExceeded,
            severity: AlertSeverity.critical,
            title: '$category Budget Exceeded!',
            message: 'You\'ve spent ${formatCurrency(categoryExpenses)} on $category this month, exceeding your budget of ${formatCurrency(budget)}.',
            actionText: 'Review $category',
            createdAt: now,
            data: {
              'category': category,
              'spent': categoryExpenses,
              'budget': budget,
              'overage': categoryExpenses - budget,
            },
          ));
        } else if (percentUsed >= 80) {
          alerts.add(AlertModel(
            id: 'category_budget_warning_${category}_${now.month}',
            type: AlertType.categoryBudgetExceeded,
            severity: AlertSeverity.warning,
            title: '$category Budget Warning',
            message: 'You\'ve used ${percentUsed.toInt()}% of your $category budget this month.',
            actionText: 'Check $category',
            createdAt: now,
            data: {
              'category': category,
              'spent': categoryExpenses,
              'budget': budget,
              'percentage': percentUsed,
            },
          ));
        }
      }
    }
    
    return alerts;
  }
  
  /// Analyze low balance situations - FIXED
  static Future<List<AlertModel>> _analyzeLowBalance(
    double currentBalance,
    BudgetSettings settings,
    String Function(double) formatCurrency,
  ) async {
    final alerts = <AlertModel>[];
    final now = DateTime.now();
    
    // Only create alerts for reasonable balance values
    if (currentBalance <= 0 && currentBalance > -1000) {
      alerts.add(AlertModel(
        id: 'balance_zero_${now.day}',
        type: AlertType.lowBalance,
        severity: AlertSeverity.critical,
        title: 'Account Balance Critical',
        message: 'Your account balance is ${formatCurrency(currentBalance)}. Add income to continue spending.',
        actionText: 'Add Income',
        createdAt: now,
        data: {'balance': currentBalance},
      ));
    } else if (currentBalance > 0 && currentBalance <= settings.lowBalanceThreshold) {
      alerts.add(AlertModel(
        id: 'balance_low_${now.day}',
        type: AlertType.lowBalance,
        severity: AlertSeverity.warning,
        title: 'Low Balance Warning',
        message: 'Your account balance is ${formatCurrency(currentBalance)}, which is below your threshold of ${formatCurrency(settings.lowBalanceThreshold)}.',
        actionText: 'Add Income',
        createdAt: now,
        data: {
          'balance': currentBalance,
          'threshold': settings.lowBalanceThreshold,
        },
      ));
    }
    
    return alerts;
  }
  
  /// Analyze goal progress and generate relevant alerts - FIXED
  static Future<List<AlertModel>> _analyzeGoalProgress(
    GoalModel goal,
    double currentBalance,
    List<TransactionModel> transactions,
    String Function(double) formatCurrency,
  ) async {
    final alerts = <AlertModel>[];
    final now = DateTime.now();
    
    // Calculate savings (positive balance only)
    final totalSavings = currentBalance > 0 ? currentBalance : 0.0;
    final progress = goal.amount > 0 ? (totalSavings / goal.amount) : 0.0;
    final percentageComplete = (progress * 100).clamp(0, 100);
    
    // Goal milestone alerts
    if (percentageComplete >= 100) {
      alerts.add(AlertModel(
        id: 'goal_achieved_${goal.createdAt.millisecondsSinceEpoch}',
        type: AlertType.goalMilestoneReached,
        severity: AlertSeverity.info,
        title: '🎉 Goal Achieved!',
        message: 'Congratulations! You\'ve reached your savings goal of ${formatCurrency(goal.amount)}!',
        actionText: 'Set New Goal',
        createdAt: now,
        data: {
          'goalAmount': goal.amount,
          'currentSavings': totalSavings,
          'percentage': percentageComplete,
        },
      ));
    } else if (percentageComplete >= 75 && percentageComplete < 80) {
      alerts.add(AlertModel(
        id: 'goal_milestone_75_${goal.createdAt.millisecondsSinceEpoch}',
        type: AlertType.goalMilestoneReached,
        severity: AlertSeverity.info,
        title: '📈 Great Progress!',
        message: 'You\'re ${percentageComplete.toInt()}% of the way to your savings goal! Only ${formatCurrency(goal.amount - totalSavings)} to go.',
        actionText: 'View Goal',
        createdAt: now,
        data: {
          'goalAmount': goal.amount,
          'currentSavings': totalSavings,
          'percentage': percentageComplete,
        },
      ));
    } else if (percentageComplete >= 50 && percentageComplete < 55) {
      alerts.add(AlertModel(
        id: 'goal_milestone_50_${goal.createdAt.millisecondsSinceEpoch}',
        type: AlertType.goalMilestoneReached,
        severity: AlertSeverity.info,
        title: '🎯 Halfway There!',
        message: 'You\'ve reached the halfway point of your savings goal! Keep up the great work.',
        actionText: 'View Progress',
        createdAt: now,
        data: {
          'goalAmount': goal.amount,
          'currentSavings': totalSavings,
          'percentage': percentageComplete,
        },
      ));
    }
    
    // FIXED: Savings slowdown alert - better calculation
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final lastWeekTransactions = transactions.where((t) => 
      t.timestamp.isAfter(oneWeekAgo)
    ).toList();
    
    if (lastWeekTransactions.isNotEmpty) {
      final lastWeekIncome = lastWeekTransactions
          .where((t) => t.amount > 0)
          .fold<double>(0, (sum, t) => sum + t.amount);
      
      final lastWeekExpenses = lastWeekTransactions
          .where((t) => t.amount < 0)
          .fold<double>(0, (sum, t) => sum + t.amount.abs());
      
      final lastWeekSavings = lastWeekIncome - lastWeekExpenses;
      
      // Only show slowdown if there were actual transactions and negative savings
      if (lastWeekSavings < 0 && percentageComplete < 100 && (lastWeekIncome > 0 || lastWeekExpenses > 0)) {
        alerts.add(AlertModel(
          id: 'savings_slowdown_${now.day}',
          type: AlertType.savingsSlowdown,
          severity: AlertSeverity.warning,
          title: '📉 Savings Slowdown',
          message: 'Your savings progress has slowed this week. You spent ${formatCurrency(lastWeekExpenses)} but only earned ${formatCurrency(lastWeekIncome)}.',
          actionText: 'Review Spending',
          createdAt: now,
          data: {
            'weeklyIncome': lastWeekIncome,
            'weeklyExpenses': lastWeekExpenses,
            'weeklySavings': lastWeekSavings,
          },
        ));
      }
    }
    
    return alerts;
  }
  
  /// Check for large expense alerts
  static Future<AlertModel?> checkLargeExpense(
    TransactionModel transaction,
    BudgetSettings settings,
    String Function(double) formatCurrency,
  ) async {
    if (transaction.amount >= 0 || 
        transaction.amount.abs() < settings.largeExpenseThreshold) {
      return null;
    }
    
    return AlertModel(
      id: 'large_expense_${transaction.id}',
      type: AlertType.largeExpense,
      severity: AlertSeverity.warning,
      title: 'Large Expense Alert',
      message: 'You just spent ${formatCurrency(transaction.amount.abs())} on ${transaction.category}${transaction.hasLocation ? ' at ${transaction.locationName}' : ''}.',
      actionText: 'Review Transaction',
      createdAt: DateTime.now(),
      data: {
        'transactionId': transaction.id,
        'amount': transaction.amount.abs(),
        'category': transaction.category,
        'location': transaction.locationName,
      },
    );
  }
}