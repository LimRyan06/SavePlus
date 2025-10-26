// lib/services/exchange_rate_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangeratesapi.io/v1';
  static const String _apiKey = '84a7fbd89df9d450c50e19e33205cbfa';
  static const String _defaultBaseCurrency = 'USD';
  static const String _cacheKeyPrefix = 'exchange_rate_';
  static const Duration _cacheExpiry = Duration(hours: 1); // Cache rates for 1 hour
  
  // Popular currencies with their symbols
  static const Map<String, Map<String, String>> supportedCurrencies = {
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    'EUR': {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
    'CHF': {'name': 'Swiss Franc', 'symbol': 'Fr', 'flag': '🇨🇭'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
    'SEK': {'name': 'Swedish Krona', 'symbol': 'kr', 'flag': '🇸🇪'},
    'NZD': {'name': 'New Zealand Dollar', 'symbol': 'NZ\$', 'flag': '🇳🇿'},
    'MXN': {'name': 'Mexican Peso', 'symbol': '\$', 'flag': '🇲🇽'},
    'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    'HKD': {'name': 'Hong Kong Dollar', 'symbol': 'HK\$', 'flag': '🇭🇰'},
    'NOK': {'name': 'Norwegian Krone', 'symbol': 'kr', 'flag': '🇳🇴'},
    'KRW': {'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
    'TRY': {'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
    'RUB': {'name': 'Russian Ruble', 'symbol': '₽', 'flag': '🇷🇺'},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
    'BRL': {'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
    'ZAR': {'name': 'South African Rand', 'symbol': 'R', 'flag': '🇿🇦'},
    'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    'THB': {'name': 'Thai Baht', 'symbol': '฿', 'flag': '🇹🇭'},
    'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
    'PHP': {'name': 'Philippine Peso', 'symbol': '₱', 'flag': '🇵🇭'},
    'VND': {'name': 'Vietnamese Dong', 'symbol': '₫', 'flag': '🇻🇳'},
  };

  /// Get current exchange rates from base currency to target currencies
  static Future<Map<String, double>?> getExchangeRates({
    String baseCurrency = _defaultBaseCurrency,
    List<String>? targetCurrencies,
  }) async {
    try {
      // Check cache first
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      // Build URL - Note: Free plan only supports EUR as base currency
      String url = '$_baseUrl/latest?access_key=$_apiKey';
      if (targetCurrencies != null && targetCurrencies.isNotEmpty) {
        url += '&symbols=${targetCurrencies.join(',')}';
      }

      print('Fetching from URL: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          Map<String, double> rates = Map<String, double>.from(
            data['rates'].map((key, value) => MapEntry(key, value.toDouble()))
          );
          
          // If we need a different base currency, convert the rates
          if (baseCurrency != 'EUR' && rates.containsKey(baseCurrency)) {
            rates = _convertRatesFromEUR(rates, baseCurrency);
          }
          
          // Cache the rates
          await _cacheRates(baseCurrency, rates);
          
          return rates;
        } else {
          final errorInfo = data['error'] != null ? data['error']['info'] : 'Unknown error';
          print('API Error: $errorInfo');
          throw Exception('API Error: $errorInfo');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exchange rate fetch error: $e');
      
      // Try to return cached data even if expired as fallback
      final cachedRates = await _getCachedRatesIgnoreExpiry(baseCurrency);
      if (cachedRates != null) {
        print('Using expired cache as fallback');
        return cachedRates;
      }
      
      return null;
    }
  }

  /// Convert rates from EUR base to another base currency
  static Map<String, double> _convertRatesFromEUR(Map<String, double> eurRates, String newBaseCurrency) {
    if (!eurRates.containsKey(newBaseCurrency)) {
      return eurRates;
    }

    final baseRate = eurRates[newBaseCurrency]!;
    final convertedRates = <String, double>{};

    // Add EUR to the rates (1 unit of newBaseCurrency = ? EUR)
    convertedRates['EUR'] = 1.0 / baseRate;

    // Convert all other rates
    for (final entry in eurRates.entries) {
      if (entry.key != newBaseCurrency) {
        convertedRates[entry.key] = entry.value / baseRate;
      }
    }

    return convertedRates;
  }

  /// Convert amount from one currency to another
  static Future<double?> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    try {
      // Get rates with fromCurrency as base
      final rates = await getExchangeRates(
        baseCurrency: fromCurrency,
        targetCurrencies: [toCurrency],
      );

      if (rates != null && rates.containsKey(toCurrency)) {
        return amount * rates[toCurrency]!;
      }
      
      return null;
    } catch (e) {
      print('Currency conversion error: $e');
      return null;
    }
  }

  /// Get historical rates for a specific date
  static Future<Map<String, double>?> getHistoricalRates({
    required DateTime date,
    String baseCurrency = _defaultBaseCurrency,
    List<String>? targetCurrencies,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      
      String url = '$_baseUrl/$dateString?access_key=$_apiKey';
      if (targetCurrencies != null && targetCurrencies.isNotEmpty) {
        url += '&symbols=${targetCurrencies.join(',')}';
      }

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return Map<String, double>.from(
            data['rates'].map((key, value) => MapEntry(key, value.toDouble()))
          );
        } else {
          throw Exception('API Error: ${data['error']['info']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Historical rates fetch error: $e');
      return null;
    }
  }

  /// Get currency symbol for display
  static String getCurrencySymbol(String currencyCode) {
    return supportedCurrencies[currencyCode]?['symbol'] ?? currencyCode;
  }

  /// Get currency name for display
  static String getCurrencyName(String currencyCode) {
    return supportedCurrencies[currencyCode]?['name'] ?? currencyCode;
  }

  /// Get currency flag emoji
  static String getCurrencyFlag(String currencyCode) {
    return supportedCurrencies[currencyCode]?['flag'] ?? '💱';
  }

  /// Format amount with currency symbol
  static String formatCurrency(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    
    // Format based on currency
    if (currencyCode == 'JPY' || currencyCode == 'KRW' || currencyCode == 'VND') {
      // No decimal places for these currencies
      return '$symbol${amount.toStringAsFixed(0)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Cache exchange rates locally
  static Future<void> _cacheRates(String baseCurrency, Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$baseCurrency';
      final cacheData = {
        'rates': rates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Cache save error: $e');
    }
  }

  /// Get cached exchange rates if they're still valid
  static Future<Map<String, double>?> _getCachedRates(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$baseCurrency';
      final cachedString = prefs.getString(cacheKey);
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          return Map<String, double>.from(cacheData['rates']);
        }
      }
      
      return null;
    } catch (e) {
      print('Cache read error: $e');
      return null;
    }
  }

  /// Clear all cached rates
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Get cached exchange rates even if expired (fallback)
  static Future<Map<String, double>?> _getCachedRatesIgnoreExpiry(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$baseCurrency';
      final cachedString = prefs.getString(cacheKey);
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        return Map<String, double>.from(cacheData['rates']);
      }
      
      return null;
    } catch (e) {
      print('Cache read error: $e');
      return null;
    }
  }

  /// Check if API key is configured
  static bool get isConfigured => _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;
}