// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _focusedDay = context.read<AppState>().selectedDate;
    _selectedDay = _focusedDay;
  }
  
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    
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
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Calendar',
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
              child: Column(
                children: [
                  // Calendar widget
                  Container(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime.now(),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        // Selected day
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(color: Colors.white),
                        
                        // Today
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                        
                        // Default day text
                        defaultTextStyle: TextStyle(
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                        
                        // Weekend
                        weekendTextStyle: TextStyle(
                          color: isDark ? AppColors.orangeAlert : AppColors.orangeAlert,
                        ),
                        
                        // Outside days
                        outsideTextStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        
                        // Week day labels - removed deprecated dowTextFormatter
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        weekendStyle: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  Divider(
                    height: 32,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  
                  // Selected day transactions summary
                  Expanded(
                    child: Container(
                      color: isDark ? const Color(0xFF121212) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Transaction circles
                          Row(
                            children: [
                              _TransactionCircle(
                                label: 'Income',
                                icon: Icons.arrow_upward,
                                color: AppColors.accent,
                                isDark: isDark,
                              ),
                              _TransactionCircle(
                                label: 'Expenses',
                                icon: Icons.arrow_downward,
                                color: AppColors.orangeAlert,
                                isDark: isDark,
                              ),
                              _TransactionCircle(
                                label: 'Transactions',
                                icon: Icons.receipt_long,
                                color: isDark ? Colors.white : AppColors.navy,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // View transactions button
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  // Set the selected date in AppState and navigate back
                                  context.read<AppState>().setSelectedDate(_selectedDay);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'View Transactions for This Day',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  
  const _TransactionCircle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}