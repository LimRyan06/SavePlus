// lib/screens/currency_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/services/exchange_rate_service.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  String? _selectedCurrency;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = context.read<AppState>().selectedCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    // Filter currencies based on search query
    final filteredCurrencies = ExchangeRateService.supportedCurrencies.entries
        .where((entry) =>
            entry.value['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Sort currencies: selected first, then popular currencies, then alphabetical
    final popularCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'MYR', 'SGD', 'AUD', 'CAD'];
    filteredCurrencies.sort((a, b) {
      // Selected currency first
      if (a.key == _selectedCurrency) return -1;
      if (b.key == _selectedCurrency) return 1;
      
      // Popular currencies next
      final aIsPopular = popularCurrencies.contains(a.key);
      final bIsPopular = popularCurrencies.contains(b.key);
      
      if (aIsPopular && !bIsPopular) return -1;
      if (!aIsPopular && bIsPopular) return 1;
      
      if (aIsPopular && bIsPopular) {
        return popularCurrencies.indexOf(a.key).compareTo(popularCurrencies.indexOf(b.key));
      }
      
      // Alphabetical for non-popular currencies
      return a.key.compareTo(b.key);
    });

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
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCurrency != appState.selectedCurrency)
                    TextButton(
                      onPressed: _saveCurrency,
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
                  hintText: 'Search currencies...',
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

            // Current selection info
            if (_selectedCurrency != null)
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
                        Text(
                          ExchangeRateService.getCurrencyFlag(_selectedCurrency!),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ExchangeRateService.getCurrencyName(_selectedCurrency!),
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_selectedCurrency!} • ${ExchangeRateService.getCurrencySymbol(_selectedCurrency!)}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Popular currencies section
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Popular Currencies',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // Currency list
            Expanded(
              child: ListView.builder(
                itemCount: filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final entry = filteredCurrencies[index];
                  final currencyCode = entry.key;
                  final currencyInfo = entry.value;
                  final isSelected = _selectedCurrency == currencyCode;
                  final isPopular = popularCurrencies.contains(currencyCode) && _searchQuery.isEmpty;

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
                          _selectedCurrency = currencyCode;
                        });
                      },
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark ? const Color(0xFF2A2A2A) : AppColors.grayLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : Text(
                                  currencyInfo['flag']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            currencyCode,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyInfo['name']!,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Symbol: ${currencyInfo['symbol']!}',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Future<void> _saveCurrency() async {
    if (_selectedCurrency == null) return;

    try {
      await context.read<AppState>().setCurrency(_selectedCurrency!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Currency changed to ${ExchangeRateService.getCurrencyName(_selectedCurrency!)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
              'Error updating currency: ${e.toString()}',
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