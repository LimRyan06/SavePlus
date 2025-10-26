// lib/screens/settings_screen.dart - Updated with Currency Converter

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/auth_service.dart';
import 'package:saveplus_plus/services/timezone_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/screens/timezone_settings_screen.dart';
import 'package:saveplus_plus/screens/currency_converter_screen.dart';
import 'package:saveplus_plus/screens/currency_selection_screen.dart';
import 'package:saveplus_plus/screens/data_reset_screen.dart';
import 'package:saveplus_plus/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    
    return Scaffold(
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
                  'Settings',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tools Section
                _SectionHeader(
                  title: 'Tools',
                  isDark: isDark,
                ),
                // Currency setting
                _SettingsTile(
                  leading: Icons.monetization_on,
                  title: 'Currency',
                  subtitle: '${appState.currencyName} (${appState.currencySymbol})',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CurrencySelectionScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Currency converter
                _SettingsTile(
                  leading: Icons.currency_exchange,
                  title: 'Currency Converter',
                  subtitle: 'Convert between different currencies',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CurrencyConverterScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Preferences Section
                _SectionHeader(
                  title: 'Preferences',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                
                // Timezone setting
                _SettingsTile(
                  leading: Icons.schedule,
                  title: 'Timezone',
                  subtitle: TimezoneService.supportedTimezones[appState.selectedTimezone] ?? 
                           appState.selectedTimezone,
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimezoneSettingsScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Dark mode toggle
                _SettingsTile(
                  leading: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: 'Dark mode',
                  subtitle: 'Switch between light and dark themes',
                  trailing: Switch.adaptive(
                    value: appState.isDarkMode,
                    onChanged: (_) => appState.toggleDarkMode(),
                    activeColor: AppColors.accent,
                  ),
                  isDark: isDark,
                  onTap: () => appState.toggleDarkMode(),
                ),
                
                const SizedBox(height: 8),
                
                // Notifications toggle
                _SettingsTile(
                  leading: appState.notificationsEnabled 
                      ? Icons.notifications 
                      : Icons.notifications_off,
                  title: 'Weekly spending reminder',
                  subtitle: 'Get notified about your weekly spending',
                  trailing: Switch.adaptive(
                    value: appState.notificationsEnabled,
                    onChanged: (_) => appState.toggleNotifications(),
                    activeColor: AppColors.accent,
                  ),
                  isDark: isDark,
                  onTap: () => appState.toggleNotifications(),
                ),
                
                const SizedBox(height: 32),
                
                // Data Management Section
                _SectionHeader(
                  title: 'Data Management',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                
                // Reset data option
                _SettingsTile(
                  leading: Icons.refresh,
                  title: 'Reset Data',
                  subtitle: 'Clear all transactions and start fresh',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataResetScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // About Section
                _SectionHeader(
                  title: 'About',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                
                // App info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 48,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SavePlus+',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your expenses and achieve your savings goals with multi-currency support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : AppColors.navy,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sign out button
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
                        color: AppColors.orangeAlert.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: AppColors.orangeAlert,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sign out',
                      style: TextStyle(
                        color: AppColors.orangeAlert,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Sign out of your account',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            title: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to sign out?',
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
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.read<AuthService>().signOut();
                                },
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(color: AppColors.orangeAlert),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.navy,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.isDark,
    this.onTap,
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            leading,
            color: isDark ? Colors.white : AppColors.navy,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}