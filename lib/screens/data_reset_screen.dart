// lib/screens/data_reset_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/data_reset_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class DataResetScreen extends StatefulWidget {
  const DataResetScreen({super.key});

  @override
  State<DataResetScreen> createState() => _DataResetScreenState();
}

class _DataResetScreenState extends State<DataResetScreen> {
  bool _isLoading = true;
  bool _hasData = false;
  int _transactionCount = 0;
  double _totalBalance = 0;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
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
                    'Reset Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasData
                      ? _buildNoDataView(isDark)
                      : _buildResetOptionsView(appState, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data to Reset',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any transactions or goals saved yet. Start using the app to track your finances!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetOptionsView(AppState appState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orangeAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.orangeAlert.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.orangeAlert,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeAlert,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone. Make sure you really want to delete your financial data before proceeding.',
                  style: TextStyle(
                    color: AppColors.orangeAlert,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Current data summary
          Text(
            'Current Data Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),

          Container(
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
              children: [
                _buildSummaryRow(
                  'Total Transactions',
                  '$_transactionCount',
                  Icons.receipt_long,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total Balance',
                  appState.formatCurrency(_totalBalance),
                  Icons.account_balance_wallet,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Savings Goal',
                  appState.goal != null 
                      ? appState.formatCurrency(appState.goal!.amount)
                      : 'Not set',
                  Icons.savings,
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reset options
          Text(
            'Reset Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),

          // Reset transactions only
          _buildResetOption(
            title: 'Reset Transactions Only',
            subtitle: 'Delete all transactions but keep your savings goal',
            icon: Icons.receipt_long,
            color: Colors.orange,
            isDark: isDark,
            onTap: () => _showResetConfirmation(ResetType.transactions),
          ),

          const SizedBox(height: 12),

          // Reset goals only
          _buildResetOption(
            title: 'Reset Goals Only',
            subtitle: 'Delete your savings goal but keep all transactions',
            icon: Icons.savings,
            color: Colors.blue,
            isDark: isDark,
            onTap: () => _showResetConfirmation(ResetType.goals),
          ),

          const SizedBox(height: 12),

          // Reset everything
          _buildResetOption(
            title: 'Reset Everything',
            subtitle: 'Delete all transactions and goals (fresh start)',
            icon: Icons.delete_forever,
            color: Colors.red,
            isDark: isDark,
            onTap: () => _showResetConfirmation(ResetType.everything),
          ),

          const SizedBox(height: 24),

          // Info note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
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
                      'What\'s Preserved',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your app preferences (currency, timezone, dark mode) and account settings will be preserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade300 : AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildResetOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
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
        onTap: _isResetting ? null : onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Future<void> _loadDataSummary() async {
    try {
      final appState = context.read<AppState>();
      if (appState.user == null) return;

      final hasData = await DataResetService.hasDataToReset(appState.uid);
      if (!hasData) {
        setState(() {
          _isLoading = false;
          _hasData = false;
        });
        return;
      }

      final transactionCount = await DataResetService.getTransactionCount(appState.uid);
      final totalBalance = await DataResetService.getTotalBalance(appState.uid);

      setState(() {
        _isLoading = false;
        _hasData = true;
        _transactionCount = transactionCount;
        _totalBalance = totalBalance;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasData = false;
      });
    }
  }

  void _showResetConfirmation(ResetType resetType) {
    final appState = context.read<AppState>();
    final isDark = appState.isDarkMode;

    String title;
    String content;
    String confirmText;

    switch (resetType) {
      case ResetType.transactions:
        title = 'Reset Transactions';
        content = 'This will delete all $_transactionCount transactions but keep your savings goal. Are you sure?';
        confirmText = 'DELETE TRANSACTIONS';
        break;
      case ResetType.goals:
        title = 'Reset Goals';
        content = 'This will delete your savings goal but keep all transactions. Are you sure?';
        confirmText = 'DELETE GOALS';
        break;
      case ResetType.everything:
        title = 'Reset Everything';
        content = 'This will delete ALL your financial data ($_transactionCount transactions and goals). This cannot be undone. Are you sure?';
        confirmText = 'DELETE EVERYTHING';
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orangeAlert,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : AppColors.navy,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAlert,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performReset(resetType);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performReset(ResetType resetType) async {
    setState(() {
      _isResetting = true;
    });

    try {
      final appState = context.read<AppState>();
      bool success = false;

      switch (resetType) {
        case ResetType.transactions:
          success = await DataResetService.resetTransactionsOnly(appState.uid);
          break;
        case ResetType.goals:
          success = await DataResetService.resetGoalsOnly(appState.uid);
          break;
        case ResetType.everything:
          success = await DataResetService.resetAllData(appState.uid);
          break;
      }

      if (success) {
        await DataResetService.storeResetConfirmation(appState.uid);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Data reset successfully',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to reset data. Please try again.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppColors.orangeAlert,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.orangeAlert,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }
}

enum ResetType {
  transactions,
  goals,
  everything,
}