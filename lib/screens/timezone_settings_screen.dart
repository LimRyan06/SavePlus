// lib/screens/timezone_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/timezone_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class TimezoneSettingsScreen extends StatefulWidget {
  const TimezoneSettingsScreen({super.key});

  @override
  State<TimezoneSettingsScreen> createState() => _TimezoneSettingsScreenState();
}

class _TimezoneSettingsScreenState extends State<TimezoneSettingsScreen> {
  String? _selectedTimezone;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTimezone = context.read<AppState>().selectedTimezone;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    // Filter timezones based on search query
    final filteredTimezones = TimezoneService.supportedTimezones.entries
        .where((entry) =>
            entry.value.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
                    'Select Timezone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedTimezone != appState.selectedTimezone)
                    TextButton(
                      onPressed: _saveTimezone,
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

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.navy,
                ),
                decoration: InputDecoration(
                  hintText: 'Search timezones...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Current timezone info
            if (_selectedTimezone != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E1E1E) 
                      : AppColors.lime.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Selection',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            TimezoneService.supportedTimezones[_selectedTimezone] ?? _selectedTimezone!,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UTC${TimezoneService.getTimezoneOffset(_selectedTimezone!) >= 0 ? '+' : ''}${TimezoneService.getTimezoneOffset(_selectedTimezone!)}:00',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Timezone list
            Expanded(
              child: ListView.builder(
                itemCount: filteredTimezones.length,
                itemBuilder: (context, index) {
                  final entry = filteredTimezones[index];
                  final timezoneId = entry.key;
                  final displayName = entry.value;
                  final offset = TimezoneService.getTimezoneOffset(timezoneId);
                  final isSelected = _selectedTimezone == timezoneId;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.1)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedTimezone = timezoneId;
                        });
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.access_time,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : AppColors.navy),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.navy,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'UTC${offset >= 0 ? '+' : ''}$offset:00',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.radio_button_checked,
                              color: AppColors.accent,
                            )
                          : Icon(
                              Icons.radio_button_unchecked,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTimezone() async {
    if (_selectedTimezone == null) return;

    try {
      await context.read<AppState>().setTimezone(_selectedTimezone!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Timezone updated successfully',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating timezone: ${e.toString()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.orangeAlert,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}