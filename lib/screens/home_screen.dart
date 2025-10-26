// lib/screens/home_screen.dart - Complete with enhanced balance card and location support

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/services/timezone_service.dart';
import 'package:saveplus_plus/screens/goal_screen.dart';
import 'package:saveplus_plus/screens/reports_screen.dart';
import 'package:saveplus_plus/screens/settings_screen.dart';
import 'package:saveplus_plus/screens/transaction_form_screen.dart';
import 'package:saveplus_plus/screens/calendar_screen.dart';
import 'package:saveplus_plus/utils/constants.dart';

// Alert system imports
import 'package:saveplus_plus/widgets/alert_widgets.dart';
import 'package:saveplus_plus/screens/budget_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  static const _icons = [
    Icons.home,
    Icons.save,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    final totalBalance = state.totalBalance;
    final isDark = state.isDarkMode;

    final pages = <Widget>[
      _homeTab(context, totalBalance),
      const GoalScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
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
        body: pages[_tab],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: isDark ? Colors.grey : AppColors.navy,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: _icons
              .map((ic) => BottomNavigationBarItem(icon: Icon(ic), label: ''))
              .toList(),
        ),
        floatingActionButton: _tab == 0 ? FloatingActionButton(
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionFormScreen(),
              ),
            );
          },
        ) : null,
      ),
    );
  }

  Widget _homeTab(BuildContext c, double totalBalance) {
    final state = c.watch<AppState>();
    final isDark = state.isDarkMode;
    final cats = ['Food', 'Bills', 'Transport', 'Work', 'Entertainment', 'Other'];
    final icons = [
      Icons.fastfood,
      Icons.receipt_long,
      Icons.directions_car,
      Icons.work,
      Icons.movie,
      Icons.help_outline
    ];

    return Container(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar with logo, date and notifications
          Container(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(c).viewPadding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App logo and name
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.savings,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SavePlus+',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Alert notification icon
                    AlertNotificationIcon(
                      unreadCount: state.unreadAlertCount,
                      isDark: isDark,
                      onTap: () => _showAlertsBottomSheet(c),
                    ),
                    const SizedBox(width: 12),
                    // Calendar chip with timezone info
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(state.selectedDate),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  TimezoneService.supportedTimezones[state.selectedTimezone]?.split(',').first ?? 'Local',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active alerts section (show top 2 alerts)
                  if (state.activeAlerts.isNotEmpty) ...[
                    Column(
                      children: state.activeAlerts
                          .take(2)
                          .map((alert) => AlertBanner(
                                alert: alert,
                                isDark: isDark,
                                onDismiss: () => state.dismissAlert(alert.id),
                                onAction: alert.onAction,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Enhanced total balance card with gradient glow
                  Center(
                    child: Container(
                      width: MediaQuery.of(c).size.width * 0.85,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF2E5B8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          // Main blue glow
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                          // Subtle inner glow
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                          // Top highlight
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total balance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.formatCurrency(totalBalance),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Balance trend indicator
                          Row(
                            children: [
                              Icon(
                                totalBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: totalBalance >= 0 
                                    ? Colors.lightGreenAccent 
                                    : Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                totalBalance >= 0 ? 'Growing' : 'Decreasing',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  
                  // Enhanced date section with tighter spacing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedDate.day == DateTime.now().day &&
                                      state.selectedDate.month == DateTime.now().month &&
                                      state.selectedDate.year == DateTime.now().year
                                  ? 'Today'
                                  : DateFormat('MMM d, yyyy').format(state.selectedDate),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            Text(
                              'Transactions & Activity',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (state.selectedDate.day != DateTime.now().day ||
                            state.selectedDate.month != DateTime.now().month ||
                            state.selectedDate.year != DateTime.now().year)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  state.formatCurrency(state.getBalanceUpToDate(state.selectedDate)),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
      
                  // 2×3 grid of category cards
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.0,
                    children: List.generate(6, (i) {
                      final amt = state.todayTxns
                          .where((t) => t.category == cats[i])
                          .fold<double>(0, (s, t) => s + t.amount);

                      return _CategoryCard(
                        amount: amt != 0 ? state.formatCurrency(amt) : null,
                        icon: icons[i],
                        label: cats[i],
                        isDark: isDark,
                        onTap: () {
                          _showCategoryTransactions(c, cats[i]);
                        },
                      );
                    }),
                  ),
                  
                  // Budget settings quick access
                  const SizedBox(height: 24),
                  Container(
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
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Budget & Alerts',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        'Set spending limits and customize alerts',
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
                      onTap: () {
                        Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (context) => const BudgetSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Recent transactions section
                  if (state.todayTxns.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // List of transactions with location info
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.todayTxns.length > 5 ? 5 : state.todayTxns.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                      itemBuilder: (context, index) {
                        final txn = state.todayTxns[index];
                        final isExpense = txn.amount < 0;
                        
                        // Convert time to user's timezone
                        final localTime = TimezoneService.convertToSelectedTimezone(
                          txn.timestamp, 
                          state.selectedTimezone,
                        );
                        
                        return Dismissible(
                          key: Key(txn.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  title: Text(
                                    'Delete Transaction',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.navy,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this transaction?',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade300 : AppColors.navy,
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            context.read<AppState>().deleteTransaction(txn.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Transaction deleted',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: AppColors.orangeAlert,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: ListTile(
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
                            title: Row(
                              children: [
                                Text(
                                  txn.category,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.navy,
                                  ),
                                ),
                                // Location indicator
                                if (txn.hasLocation) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('h:mm a').format(localTime),
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                // Show location if available
                                if (txn.hasLocation) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    txn.locationName,
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              state.formatCurrency(txn.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? AppColors.orangeAlert : AppColors.accent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryTransactions(BuildContext context, String category) {
    final state = context.read<AppState>();
    final isDark = state.isDarkMode;
    final catTransactions = state.todayTxns
        .where((t) => t.category == category)
        .toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            final total = catTransactions.fold<double>(
                0, (sum, txn) => sum + txn.amount);
                
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            state.formatCurrency(total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: total < 0
                                  ? AppColors.orangeAlert
                                  : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                Expanded(
                  child: catTransactions.isEmpty
                      ? Center(
                          child: Text(
                            "No transactions found",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: catTransactions.length,
                          itemBuilder: (context, index) {
                            final txn = catTransactions[index];
                            final isExpense = txn.amount < 0;
                            
                            // Convert time to user's timezone
                            final localTime = TimezoneService.convertToSelectedTimezone(
                              txn.timestamp, 
                              state.selectedTimezone,
                            );
                            
                            return ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, h:mm a').format(localTime),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.navy,
                                    ),
                                  ),
                                  // Show location in category view
                                  if (txn.hasLocation) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            txn.locationName,
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Text(
                                state.formatCurrency(txn.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? AppColors.orangeAlert
                                      : AppColors.accent,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Alert bottom sheet method
  void _showAlertsBottomSheet(BuildContext context) {
    final appState = context.read<AppState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, __) => AlertBottomSheet(
          alerts: appState.activeAlerts,
          isDark: appState.isDarkMode,
          onDismiss: (alertId) async {
            await appState.dismissAlert(alertId);
          },
          onMarkAsRead: (alertId) async {
            await appState.markAlertAsRead(alertId);
          },
          onClearAll: () async {
            await appState.clearAllAlerts();
          },
        ),
      ),
    );
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

class _CategoryCard extends StatelessWidget {
  final String? amount;
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    this.amount,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (amount != null) ...[
              Text(
                amount!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: amount!.contains('-') 
                      ? AppColors.orangeAlert 
                      : AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Icon(
              icon, 
              size: 32, 
              color: isDark ? Colors.white : AppColors.navy,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}