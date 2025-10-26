// lib/screens/transaction_form_screen.dart - Fixed version

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:saveplus_plus/models/transaction_model.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/services/simple_location_service.dart';
import 'package:saveplus_plus/utils/constants.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isSaving = false;
  
  // Location-related state
  SimpleLocationData? _currentLocation;
  bool _isLoadingLocation = false;
  bool _locationEnabled = true; // User can toggle this
  String? _locationError;

  final List<String> _categories = ['Food', 'Bills', 'Transport', 'Work', 'Entertainment', 'Other'];
  
  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final balanceUpToDate = appState.getBalanceUpToDate(_selectedDate);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.navy,
        elevation: 0,
        title: Text(
          'Add Transaction',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.navy,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Location toggle button
          IconButton(
            icon: Icon(
              _locationEnabled ? Icons.location_on : Icons.location_off,
              color: _locationEnabled ? AppColors.accent : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _locationEnabled = !_locationEnabled;
                if (_locationEnabled) {
                  _loadCurrentLocation();
                } else {
                  _currentLocation = null;
                  _locationError = null;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available balance display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedDate.day == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year
                        ? 'Available Balance'
                        : 'Balance on ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.formatCurrency(balanceUpToDate.clamp(0, double.infinity)),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: balanceUpToDate > 0 
                          ? AppColors.accent 
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                  if (balanceUpToDate <= 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add income to start spending',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Location display section
            if (_locationEnabled) ...[
              _buildLocationSection(isDark),
              const SizedBox(height: 24),
            ],
            
            // Transaction type toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isExpense 
                          ? AppColors.orangeAlert 
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      foregroundColor: _isExpense 
                          ? Colors.white 
                          : (isDark ? Colors.white : AppColors.navy),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpense = true;
                        _updateCategorySuggestion();
                      });
                    },
                    child: const Text('Expense'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isExpense 
                          ? AppColors.accent 
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      foregroundColor: !_isExpense 
                          ? Colors.white 
                          : (isDark ? Colors.white : AppColors.navy),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpense = false;
                      });
                    },
                    child: const Text('Income'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Amount field
            Text(
              'Amount', 
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.navy,
              ),
              decoration: InputDecoration(
                hintText: '${appState.currencySymbol}0.00',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                border: const OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to update validation
              },
            ),
            
            // Balance validation for expenses
            if (_isExpense && _amountController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSpendingValidation(balanceUpToDate, isDark, appState),
            ],
            
            const SizedBox(height: 24),
            
            // Category dropdown with suggestion
            Row(
              children: [
                Text(
                  'Category', 
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
                if (_currentLocation != null && _isExpense) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Auto-suggested',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date picker
            Text(
              'Date', 
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
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
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSaveTransaction(balanceUpToDate) 
                      ? AppColors.accent 
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving || !_canSaveTransaction(balanceUpToDate) 
                    ? null 
                    : () => _saveTransaction(appState),
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_getButtonText(balanceUpToDate)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.navy,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (_isLoadingLocation)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              if (_currentLocation != null)
                Icon(
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentLocation != null) ...[
            Text(
              _currentLocation!.shortName,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_currentLocation!.address.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _currentLocation!.address,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ] else if (_locationError != null) ...[
            Text(
              _locationError!,
              style: TextStyle(
                color: AppColors.orangeAlert,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadCurrentLocation,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ] else if (_isLoadingLocation) ...[
            Text(
              'Getting your location...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              'Location not available',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadCurrentLocation() async {
    if (!_locationEnabled) return;
    
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await SimpleLocationService.getCurrentLocation();
      if (position != null) {
        final locationData = await SimpleLocationService.getLocationInfo(
          position.latitude, 
          position.longitude
        );

        if (locationData != null) {
          setState(() {
            _currentLocation = locationData;
            _isLoadingLocation = false;
          });
          
          // Auto-suggest category based on location
          _updateCategorySuggestion();
        } else {
          setState(() {
            _locationError = 'Could not get address information';
            _isLoadingLocation = false;
          });
        }
      } else {
        setState(() {
          _locationError = 'Location permission denied or unavailable';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  void _updateCategorySuggestion() {
    if (_currentLocation != null && _isExpense) {
      final suggestedCategory = SimpleLocationService.suggestCategory(_currentLocation!);
      if (_categories.contains(suggestedCategory)) {
        setState(() {
          _selectedCategory = suggestedCategory;
        });
      }
    }
  }

  Widget _buildSpendingValidation(double currentBalance, bool isDark, AppState appState) {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final double? amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) return const SizedBox.shrink();
    
    final remaining = currentBalance - amount;
    
    if (amount > currentBalance) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orangeAlert.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.orangeAlert.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: AppColors.orangeAlert, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insufficient Funds',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.orangeAlert,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'You need ${appState.formatCurrency(amount - currentBalance)} more to make this purchase',
                    style: TextStyle(color: AppColors.orangeAlert, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (remaining <= 50) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                remaining == 0 
                    ? 'This will use all your available balance'
                    : 'Low balance after purchase: ${appState.formatCurrency(remaining)} remaining',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Balance after purchase: ${appState.formatCurrency(remaining)}',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  bool _canSaveTransaction(double currentBalance) {
    if (!_isExpense) return true;
    
    final amountText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final double? amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) return false;
    return amount <= currentBalance;
  }

  String _getButtonText(double currentBalance) {
    if (_isExpense) {
      final amountText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
      final double? amount = double.tryParse(amountText);
      
      if (amount != null && amount > 0) {
        if (amount > currentBalance) {
          return 'Insufficient Funds';
        }
      }
    }
    return 'Save Transaction';
  }

  void _saveTransaction(AppState appState) async {
    final balanceUpToDate = appState.getBalanceUpToDate(_selectedDate);
    
    final amountText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final double? amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount', appState);
      return;
    }

    if (_isExpense && amount > balanceUpToDate) {
      _showErrorDialog('Insufficient funds. Add income first or reduce the expense amount.', appState);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double finalAmount = _isExpense ? -amount : amount;
      
      final transaction = TransactionModel(
        id: '',
        amount: finalAmount,
        category: _selectedCategory,
        timestamp: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
        location: _locationEnabled ? _currentLocation : null,
      );
      
      await appState.addTransaction(transaction);
      
      if (mounted) {
        final locationText = _currentLocation != null 
            ? ' at ${_currentLocation!.shortName}'
            : '';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isExpense 
                  ? 'Expense of ${appState.formatCurrency(amount)} recorded$locationText'
                  : 'Income of ${appState.formatCurrency(amount)} added$locationText',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error saving transaction: ${e.toString()}', appState);
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorDialog(String message, AppState appState) {
    final isDark = appState.isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Transaction Failed',
            style: TextStyle(color: isDark ? Colors.white : AppColors.navy),
          ),
          content: Text(
            message,
            style: TextStyle(color: isDark ? Colors.grey.shade300 : AppColors.navy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}