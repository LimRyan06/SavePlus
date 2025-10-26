// lib/screens/budget_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/alert_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';
import 'package:saveplus_plus/utils/snackbar_helper.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  late BudgetSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  final _dailyBudgetController = TextEditingController();
  final _weeklyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  final _lowBalanceController = TextEditingController();
  final _largeExpenseController = TextEditingController();

  final Map<String, TextEditingController> _categoryControllers = {
    'Food': TextEditingController(),
    'Bills': TextEditingController(),
    'Transport': TextEditingController(),
    'Work': TextEditingController(),
    'Entertainment': TextEditingController(),
    'Other': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF121212) : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Column(
          children: [
            // Custom app bar
            Container(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Budget & Alert Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  if (_isSaving)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _saveSettings,
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Budget Limits Section
                      _SectionHeader(
                        title: 'Budget Limits',
                        subtitle: 'Set spending limits to track your expenses',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _BudgetInput(
                        label: 'Daily Budget',
                        controller: _dailyBudgetController,
                        currencySymbol: appState.currencySymbol,
                        isDark: isDark,
                        enabled: _settings.enableDailyAlerts,
                        onToggle: (value) {
                          setState(() {
                            _settings = _settings.copyWith(enableDailyAlerts: value);
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _BudgetInput(
                        label: 'Weekly Budget',
                        controller: _weeklyBudgetController,
                        currencySymbol: appState.currencySymbol,
                        isDark: isDark,
                        enabled: _settings.enableWeeklyAlerts,
                        onToggle: (value) {
                          setState(() {
                            _settings = _settings.copyWith(enableWeeklyAlerts: value);
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // Category Budgets Section
                      _SectionHeader(
                        title: 'Category Budgets',
                        subtitle: 'Set monthly spending limits per category',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      Column(
                        children: _categoryControllers.entries.map((entry) {
                          final category = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryBudgetInput(
                              category: category,
                              controller: controller,
                              currencySymbol: appState.currencySymbol,
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      _SwitchTile(
                        title: 'Category Budget Alerts',
                        subtitle: 'Get notified when you exceed category budgets',
                        value: _settings.enableCategoryAlerts,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(enableCategoryAlerts: value);
                          });
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Alert Thresholds Section
                      _SectionHeader(
                        title: 'Alert Thresholds',
                        subtitle: 'Customize when you receive warnings',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _ThresholdInput(
                        label: 'Low Balance Warning',
                        controller: _lowBalanceController,
                        currencySymbol: appState.currencySymbol,
                        subtitle: 'Alert when balance drops below this amount',
                        isDark: isDark,
                      ),

                      const SizedBox(height: 16),

                      _ThresholdInput(
                        label: 'Large Expense Alert',
                        controller: _largeExpenseController,
                        currencySymbol: appState.currencySymbol,
                        subtitle: 'Alert for expenses above this amount',
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Goal Alerts Section
                      _SectionHeader(
                        title: 'Goal Alerts',
                        subtitle: 'Notifications about your savings progress',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _SwitchTile(
                        title: 'Goal Progress Alerts',
                        subtitle: 'Get notified about milestones and setbacks',
                        value: _settings.enableGoalAlerts,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(enableGoalAlerts: value);
                          });
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : AppColors.lime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'About Budget Alerts',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Alerts appear as notifications in your app\n'
                              '• You\'ll get warnings at 80% and 100% of budgets\n'
                              '• Category budgets are calculated monthly\n'
                              '• All alerts can be dismissed or turned off',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade300 : AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    await AlertService.initialize();
    setState(() {
      _settings = AlertService.budgetSettings;
      _isLoading = false;
    });

    // Populate controllers
    _dailyBudgetController.text = _settings.dailyBudget?.toStringAsFixed(0) ?? '';
    _weeklyBudgetController.text = _settings.weeklyBudget?.toStringAsFixed(0) ?? '';
    _monthlyBudgetController.text = _settings.monthlyBudget?.toStringAsFixed(0) ?? '';
    _lowBalanceController.text = _settings.lowBalanceThreshold.toStringAsFixed(0);
    _largeExpenseController.text = _settings.largeExpenseThreshold.toStringAsFixed(0);

    for (final entry in _categoryControllers.entries) {
      final category = entry.key;
      final controller = entry.value;
      final budget = _settings.categoryBudgets[category];
      controller.text = budget?.toStringAsFixed(0) ?? '';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // Parse budget values
      final dailyBudget = double.tryParse(_dailyBudgetController.text);
      final weeklyBudget = double.tryParse(_weeklyBudgetController.text);
      final monthlyBudget = double.tryParse(_monthlyBudgetController.text);
      final lowBalance = double.tryParse(_lowBalanceController.text) ?? 100.0;
      final largeExpense = double.tryParse(_largeExpenseController.text) ?? 500.0;

      // Parse category budgets
      final categoryBudgets = <String, double>{};
      for (final entry in _categoryControllers.entries) {
        final category = entry.key;
        final controller = entry.value;
        final budget = double.tryParse(controller.text);
        if (budget != null && budget > 0) {
          categoryBudgets[category] = budget;
        }
      }

      // Create updated settings
      final updatedSettings = _settings.copyWith(
        dailyBudget: dailyBudget,
        weeklyBudget: weeklyBudget,
        monthlyBudget: monthlyBudget,
        categoryBudgets: categoryBudgets,
        lowBalanceThreshold: lowBalance,
        largeExpenseThreshold: largeExpense,
      );

      await AlertService.saveBudgetSettings(updatedSettings);

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Budget settings saved successfully',
          isDark: context.read<AppState>().isDarkMode,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error saving settings: ${e.toString()}',
          isDark: context.read<AppState>().isDarkMode,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    _lowBalanceController.dispose();
    _largeExpenseController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _BudgetInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String currencySymbol;
  final bool isDark;
  final bool enabled;
  final Function(bool) onToggle;

  const _BudgetInput({
    required this.label,
    required this.controller,
    required this.currencySymbol,
    required this.isDark,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.navy,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeColor: AppColors.accent,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.navy,
              ),
              decoration: InputDecoration(
                hintText: '${currencySymbol}0',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBudgetInput extends StatelessWidget {
  final String category;
  final TextEditingController controller;
  final String currencySymbol;
  final bool isDark;

  const _CategoryBudgetInput({
    required this.category,
    required this.controller,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            category,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: '${currencySymbol}0 (monthly)',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThresholdInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String currencySymbol;
  final String subtitle;
  final bool isDark;

  const _ThresholdInput({
    required this.label,
    required this.controller,
    required this.currencySymbol,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: '${currencySymbol}0',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              prefixIcon: Icon(
                Icons.attach_money,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.navy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }
}