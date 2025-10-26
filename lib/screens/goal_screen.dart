// lib/screens/goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


import 'package:saveplus_plus/models/goal_model.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _ctrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Savings Goal');
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill with existing goal if any
    final amt = context.read<AppState>().goal?.amount ?? 0.0;
    _ctrl.text = amt > 0 ? amt.toStringAsFixed(0) : '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final currentGoal = state.goal?.amount ?? 0.0;
    
    // Calculate total savings (net positive balance, not just positive transactions)
    final totalBalance = state.totalBalance;
    final totalSavings = totalBalance > 0 ? totalBalance : 0.0;
    
    // Calculate progress percentage
    final double progress = currentGoal > 0 ? (totalSavings / currentGoal).clamp(0.0, 1.0) : 0.0;
    
    // keep controller in sync if the goal changes elsewhere:
    _ctrl.text = currentGoal > 0 ? currentGoal.toStringAsFixed(0) : '';

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
            // Custom app bar (without back button)
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
                    'Savings Goal',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal name field
                    Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Goal Name',
                        hintStyle: TextStyle(
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

                    const SizedBox(height: 24),

                    // Amount field (now shows selected currency)
                    Text(
                      'Target Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                      decoration: InputDecoration(
                        hintText: '${state.currencySymbol}0',
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

                    const SizedBox(height: 24),

                    // Progress display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.navy,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Progress bar
                    LinearProgressIndicator(
                      value: progress,
                      color: AppColors.accent,
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                      minHeight: 8,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount progress (now uses selected currency)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.formatCurrency(totalSavings),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.navy,
                          ),
                        ),
                        Text(
                          currentGoal > 0 ? state.formatCurrency(currentGoal) : '-',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    
                    // Summary card (now uses selected currency)
                    if (currentGoal > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved so far',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade300 : AppColors.navy,
                                  ),
                                ),
                                Text(
                                  state.formatCurrency(totalSavings),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Still needed',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade300 : AppColors.navy,
                                  ),
                                ),
                                Text(
                                  state.formatCurrency((currentGoal - totalSavings).clamp(0, double.infinity)),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                final txt = _ctrl.text.replaceAll(RegExp(r'[^\d]'), '');
                                final val = double.tryParse(txt) ?? 0.0;
                                if (val > 0) {
                                  setState(() => _saving = true);
                                  await state.setGoal(
                                    GoalModel(
                                      amount: val,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Goal saved'),
                                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
                                      ),
                                    );
                                    setState(() => _saving = false);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please enter a valid amount'),
                                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
                                    ),
                                  );
                                }
                              },
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Goal'),
                      ),
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
  
  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }
}