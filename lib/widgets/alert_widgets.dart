// lib/widgets/alert_widgets.dart

import 'package:flutter/material.dart';
import 'package:saveplus_plus/services/alert_service.dart';
import 'package:saveplus_plus/utils/constants.dart';

class AlertBanner extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final bool isDark;

  const AlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            if (alert.actionText != null && onAction != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: _getActionColor(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      alert.actionText!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return isDark 
            ? AppColors.orangeAlert.withOpacity(0.15)
            : AppColors.orangeAlert.withOpacity(0.1);
      case AlertSeverity.warning:
        return isDark
            ? Colors.orange.withOpacity(0.15)
            : Colors.orange.withOpacity(0.1);
      case AlertSeverity.info:
        return isDark
            ? AppColors.accent.withOpacity(0.15)
            : AppColors.accent.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.orangeAlert.withOpacity(0.3);
      case AlertSeverity.warning:
        return Colors.orange.withOpacity(0.3);
      case AlertSeverity.info:
        return AppColors.accent.withOpacity(0.3);
    }
  }

  IconData _getIcon() {
    switch (alert.type) {
      case AlertType.dailyBudgetExceeded:
      case AlertType.weeklyBudgetExceeded:
      case AlertType.categoryBudgetExceeded:
        return Icons.warning_amber_rounded;
      case AlertType.lowBalance:
        return Icons.account_balance_wallet_outlined;
      case AlertType.largeExpense:
        return Icons.receipt_long;
      case AlertType.goalMilestoneReached:
        return Icons.emoji_events;
      case AlertType.goalDeadlineApproaching:
        return Icons.schedule;
      case AlertType.goalProgressReminder:
        return Icons.trending_up;
      case AlertType.savingsSlowdown:
        return Icons.trending_down;
    }
  }

  Color _getIconColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.orangeAlert;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return AppColors.accent;
    }
  }

  Color _getActionColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.orangeAlert;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return AppColors.accent;
    }
  }
}

class AlertBottomSheet extends StatelessWidget {
  final List<AlertModel> alerts;
  final Function(String) onDismiss;
  final Function(String) onMarkAsRead;
  final VoidCallback onClearAll;
  final bool isDark;

  const AlertBottomSheet({
    super.key,
    required this.alerts,
    required this.onDismiss,
    required this.onMarkAsRead,
    required this.onClearAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.all(16),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: isDark ? Colors.white : AppColors.navy,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alerts & Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
                const Spacer(),
                if (alerts.isNotEmpty)
                  TextButton(
                    onPressed: onClearAll,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: AppColors.orangeAlert,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Alerts list
          Flexible(
            child: alerts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 48,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Dismissible(
                        key: Key(alert.id),
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orangeAlert,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => onDismiss(alert.id),
                        child: AlertBanner(
                          alert: alert,
                          isDark: isDark,
                          onDismiss: () => onDismiss(alert.id),
                          onAction: alert.onAction,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AlertNotificationIcon extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final bool isDark;

  const AlertNotificationIcon({
    super.key,
    required this.unreadCount,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : AppColors.navy,
            size: 24,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.orangeAlert,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AlertSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isDark;

  const AlertSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
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
        onTap: onTap,
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
        trailing: onTap != null
            ? Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              )
            : null,
      ),
    );
  }
}