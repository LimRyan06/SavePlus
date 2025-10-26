// lib/screens/currency_converter_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/exchange_rate_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _fromAmountController = TextEditingController(text: '1.00');
  final _toAmountController = TextEditingController();
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'MYR';
  
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  Map<String, double>? _currentRates;

  @override
  void initState() {
    super.initState();
    if (ExchangeRateService.isConfigured) {
      _convertCurrency();
    } else {
      _errorMessage = 'Please configure API key in ExchangeRateService';
    }
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
                    'Currency Converter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Error message with retry button
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.orangeAlert.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.orangeAlert.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: AppColors.orangeAlert, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppColors.orangeAlert,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orangeAlert,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: _isLoading ? null : () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                  _convertCurrency();
                                },
                                child: Text(_isLoading ? 'Retrying...' : 'Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // From Currency Section
                    _CurrencyInputCard(
                      title: 'From',
                      controller: _fromAmountController,
                      selectedCurrency: _fromCurrency,
                      isDark: isDark,
                      onCurrencyChanged: (currency) {
                        setState(() {
                          _fromCurrency = currency;
                        });
                        _convertCurrency();
                      },
                      onAmountChanged: (_) => _convertCurrency(),
                    ),

                    // Swap button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _swapCurrencies,
                        ),
                      ),
                    ),

                    // To Currency Section
                    _CurrencyInputCard(
                      title: 'To',
                      controller: _toAmountController,
                      selectedCurrency: _toCurrency,
                      isDark: isDark,
                      isReadOnly: true,
                      onCurrencyChanged: (currency) {
                        setState(() {
                          _toCurrency = currency;
                        });
                        _convertCurrency();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Exchange rate info
                    if (_currentRates != null && _currentRates!.containsKey(_toCurrency))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : AppColors.lime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Exchange Rate',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1 $_fromCurrency = ${_currentRates![_toCurrency]!.toStringAsFixed(4)} $_toCurrency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                            if (_lastUpdated != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Updated: ${_formatDateTime(_lastUpdated!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Popular currency rates
                    if (_currentRates != null)
                      _PopularRatesCard(
                        fromCurrency: _fromCurrency,
                        rates: _currentRates!,
                        isDark: isDark,
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

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      
      // Swap amounts
      final fromAmount = _fromAmountController.text;
      _fromAmountController.text = _toAmountController.text;
      _toAmountController.text = fromAmount;
    });
    _convertCurrency();
  }

  Future<void> _convertCurrency() async {
    if (_fromAmountController.text.isEmpty) return;

    final amount = double.tryParse(_fromAmountController.text);
    if (amount == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rates = await ExchangeRateService.getExchangeRates(
        baseCurrency: _fromCurrency,
      );

      if (rates != null) {
        setState(() {
          _currentRates = rates;
          _lastUpdated = DateTime.now();
          
          if (rates.containsKey(_toCurrency)) {
            final convertedAmount = amount * rates[_toCurrency]!;
            _toAmountController.text = convertedAmount.toStringAsFixed(2);
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch exchange rates';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }
}

class _CurrencyInputCard extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String selectedCurrency;
  final bool isDark;
  final bool isReadOnly;
  final Function(String) onCurrencyChanged;
  final Function(String)? onAmountChanged;

  const _CurrencyInputCard({
    required this.title,
    required this.controller,
    required this.selectedCurrency,
    required this.isDark,
    this.isReadOnly = false,
    required this.onCurrencyChanged,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Currency selector
              GestureDetector(
                onTap: () => _showCurrencyPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ExchangeRateService.getCurrencyFlag(selectedCurrency),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedCurrency,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Amount input
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  onChanged: onAmountChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Column(
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
                // Title
                Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                // Currency list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: ExchangeRateService.supportedCurrencies.length,
                    itemBuilder: (context, index) {
                      final entry = ExchangeRateService.supportedCurrencies.entries.elementAt(index);
                      final code = entry.key;
                      final info = entry.value;
                      final isSelected = code == selectedCurrency;
                      
                      return ListTile(
                        leading: Text(
                          info['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.navy,
                          ),
                        ),
                        subtitle: Text(
                          info['name']!,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.accent)
                            : null,
                        onTap: () {
                          onCurrencyChanged(code);
                          Navigator.pop(context);
                        },
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
}

class _PopularRatesCard extends StatelessWidget {
  final String fromCurrency;
  final Map<String, double> rates;
  final bool isDark;

  const _PopularRatesCard({
    required this.fromCurrency,
    required this.rates,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final popularCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'MYR', 'SGD'];
    final filteredCurrencies = popularCurrencies
        .where((currency) => currency != fromCurrency && rates.containsKey(currency))
        .toList();

    if (filteredCurrencies.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
            'Popular Rates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          ...filteredCurrencies.map((currency) {
            final rate = rates[currency]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        ExchangeRateService.getCurrencyFlag(currency),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currency,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    rate.toStringAsFixed(4),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}