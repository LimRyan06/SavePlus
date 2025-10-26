// lib/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // For date range selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    
    // Get transactions for the selected date range
    final transactions = state.todayTxns;
    
    // Calculate total income, expenses, and net
    final totalIncome = transactions
        .where((t) => t.amount > 0)
        .fold<double>(0, (sum, t) => sum + t.amount);
        
    final totalExpenses = transactions
        .where((t) => t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount);
        
    final netAmount = totalIncome + totalExpenses;
    
    // Calculate spending by category
    final Map<String, double> expensesByCategory = {};
    for (final txn in transactions.where((t) => t.amount < 0)) {
      if (expensesByCategory.containsKey(txn.category)) {
        expensesByCategory[txn.category] = expensesByCategory[txn.category]! + txn.amount.abs();
      } else {
        expensesByCategory[txn.category] = txn.amount.abs();
      }
    }
    
    // Calculate percentages for pie chart
    final totalExpensesAbs = totalExpenses.abs();
    final Map<String, double> expensePercentages = {};
    
    if (totalExpensesAbs > 0) {
      expensesByCategory.forEach((category, amount) {
        expensePercentages[category] = (amount / totalExpensesAbs) * 100;
      });
    }
    
    // Generate colors for categories
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.orangeAlert,
      AppColors.navy,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF121212) : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? const Color(0xFF121212) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
                  Text(
                    'Spending Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.date_range,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                    onPressed: _selectDateRange,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Showing data from ${DateFormat('MMM d').format(_startDate)} to ${DateFormat('MMM d').format(_endDate)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the calendar icon to change date range',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Summary cards (now uses selected currency)
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Income',
                            amount: totalIncome,
                            icon: Icons.arrow_upward,
                            color: AppColors.accent,
                            isDark: isDark,
                            currencyFormatter: state.formatCurrency,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expenses',
                            amount: totalExpenses,
                            icon: Icons.arrow_downward,
                            color: AppColors.orangeAlert,
                            isDark: isDark,
                            showAbs: true,
                            currencyFormatter: state.formatCurrency,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _SummaryCard(
                      title: 'Net',
                      amount: netAmount,
                      icon: Icons.account_balance_wallet,
                      color: netAmount >= 0 ? AppColors.accent : AppColors.orangeAlert,
                      isDark: isDark,
                      fullWidth: true,
                      currencyFormatter: state.formatCurrency,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Expenses by category
                    Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (totalExpensesAbs <= 0)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No expenses to display',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade400 : Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Pie Chart
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: List.generate(expensePercentages.length, (i) {
                                  final entry = expensePercentages.entries.elementAt(i);
                                  final colorIndex = i % colors.length;
                                  return PieChartSectionData(
                                    color: colors[colorIndex],
                                    value: entry.value,
                                    title: '${entry.value.toInt()}%',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }),
                                sectionsSpace: 4,
                                centerSpaceRadius: 30,
                              ),
                            ),
                          ),
                    
                          const SizedBox(height: 16),
                    
                          // Legend (now uses selected currency)
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: List.generate(expensePercentages.length, (i) {
                              final entry = expensePercentages.entries.elementAt(i);
                              final category = entry.key;
                              final percentage = entry.value;
                              final amount = expensesByCategory[category] ?? 0;
                              final colorIndex = i % colors.length;
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: colors[colorIndex],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$category (${percentage.toInt()}%): ${state.formatCurrency(amount)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.navy,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Transaction list
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No transactions to display',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade400 : Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length > 10 ? 10 : transactions.length,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          final isExpense = txn.amount < 0;
                          
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(txn.category),
                                color: isExpense ? AppColors.orangeAlert : AppColors.accent,
                              ),
                            ),
                            title: Text(
                              txn.category,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, h:mm a').format(txn.timestamp),
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              state.formatCurrency(txn.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? AppColors.orangeAlert : AppColors.accent,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectDateRange() async {
    final isDark = context.read<AppState>().isDarkMode;
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      
      // TODO: Implement fetching transactions for selected date range
      // This would require modifying the AppState and FirestoreService
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Bills':
        return Icons.receipt_long;
      case 'Transport':
        return Icons.directions_car;
      case 'Work':
        return Icons.work;
      case 'Entertainment':
        return Icons.movie;
      case 'Other':
      default:
        return Icons.help_outline;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool fullWidth;
  final bool showAbs;
  final bool isDark;
  final String Function(double) currencyFormatter;
  
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.currencyFormatter,
    this.fullWidth = false,
    this.showAbs = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final displayAmount = showAbs ? amount.abs() : amount;
    
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter(displayAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}