// lib/services/timezone_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class TimezoneService {
  static const String _timezoneKey = 'selected_timezone';
  static const String _defaultTimezone = 'Asia/Kuala_Lumpur';
  
  // Common timezones with their display names
  static const Map<String, String> supportedTimezones = {
    'Asia/Kuala_Lumpur': 'Kuala Lumpur, Malaysia (MYT)',
    'Asia/Singapore': 'Singapore (SGT)',
    'Asia/Jakarta': 'Jakarta, Indonesia (WIB)',
    'Asia/Bangkok': 'Bangkok, Thailand (ICT)',
    'Asia/Manila': 'Manila, Philippines (PST)',
    'Asia/Hong_Kong': 'Hong Kong (HKT)',
    'Asia/Shanghai': 'Shanghai, China (CST)',
    'Asia/Tokyo': 'Tokyo, Japan (JST)',
    'Asia/Seoul': 'Seoul, South Korea (KST)',
    'Asia/Kolkata': 'Mumbai, India (IST)',
    'Asia/Dubai': 'Dubai, UAE (GST)',
    'Europe/London': 'London, UK (GMT/BST)',
    'Europe/Paris': 'Paris, France (CET/CEST)',
    'Europe/Berlin': 'Berlin, Germany (CET/CEST)',
    'Europe/Rome': 'Rome, Italy (CET/CEST)',
    'America/New_York': 'New York, USA (EST/EDT)',
    'America/Chicago': 'Chicago, USA (CST/CDT)',
    'America/Denver': 'Denver, USA (MST/MDT)',
    'America/Los_Angeles': 'Los Angeles, USA (PST/PDT)',
    'America/Toronto': 'Toronto, Canada (EST/EDT)',
    'America/Vancouver': 'Vancouver, Canada (PST/PDT)',
    'Australia/Sydney': 'Sydney, Australia (AEST/AEDT)',
    'Australia/Melbourne': 'Melbourne, Australia (AEST/AEDT)',
    'Australia/Perth': 'Perth, Australia (AWST)',
    'Pacific/Auckland': 'Auckland, New Zealand (NZST/NZDT)',
  };
  
  /// Get the currently selected timezone
  static Future<String> getSelectedTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_timezoneKey) ?? _defaultTimezone;
  }
  
  /// Set the selected timezone
  static Future<void> setSelectedTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, timezone);
  }
  
  /// Get timezone offset in hours for display purposes
  static int getTimezoneOffset(String timezone) {
    final now = DateTime.now();
    
    // Map of common timezone offsets (in hours from UTC)
    const offsets = {
      'Asia/Kuala_Lumpur': 8,
      'Asia/Singapore': 8,
      'Asia/Jakarta': 7,
      'Asia/Bangkok': 7,
      'Asia/Manila': 8,
      'Asia/Hong_Kong': 8,
      'Asia/Shanghai': 8,
      'Asia/Tokyo': 9,
      'Asia/Seoul': 9,
      'Asia/Kolkata': 5, // +5:30 but simplified to 5
      'Asia/Dubai': 4,
      'Europe/London': 0, // GMT, can be +1 during BST
      'Europe/Paris': 1, // CET, can be +2 during CEST
      'Europe/Berlin': 1,
      'Europe/Rome': 1,
      'America/New_York': -5, // EST, can be -4 during EDT
      'America/Chicago': -6,
      'America/Denver': -7,
      'America/Los_Angeles': -8,
      'America/Toronto': -5,
      'America/Vancouver': -8,
      'Australia/Sydney': 10, // AEST, can be +11 during AEDT
      'Australia/Melbourne': 10,
      'Australia/Perth': 8,
      'Pacific/Auckland': 12, // NZST, can be +13 during NZDT
    };
    
    return offsets[timezone] ?? 0;
  }
  
  /// Convert UTC DateTime to selected timezone
  static DateTime convertToSelectedTimezone(DateTime utcDateTime, String timezone) {
    final offset = getTimezoneOffset(timezone);
    return utcDateTime.add(Duration(hours: offset));
  }
  
  /// Convert local DateTime to UTC for storage
  static DateTime convertToUTC(DateTime localDateTime, String timezone) {
    final offset = getTimezoneOffset(timezone);
    return localDateTime.subtract(Duration(hours: offset));
  }
  
  /// Format DateTime with timezone info
  static String formatWithTimezone(DateTime dateTime, String timezone) {
    final converted = convertToSelectedTimezone(dateTime, timezone);
    final timezoneAbbr = _getTimezoneAbbreviation(timezone);
    
    return '${converted.hour}:${converted.minute.toString().padLeft(2, '0')} $timezoneAbbr';
  }
  
  static String _getTimezoneAbbreviation(String timezone) {
    const abbreviations = {
      'Asia/Kuala_Lumpur': 'MYT',
      'Asia/Singapore': 'SGT',
      'Asia/Jakarta': 'WIB',
      'Asia/Bangkok': 'ICT',
      'Asia/Manila': 'PST',
      'Asia/Hong_Kong': 'HKT',
      'Asia/Shanghai': 'CST',
      'Asia/Tokyo': 'JST',
      'Asia/Seoul': 'KST',
      'Asia/Kolkata': 'IST',
      'Asia/Dubai': 'GST',
      'Europe/London': 'GMT',
      'Europe/Paris': 'CET',
      'Europe/Berlin': 'CET',
      'Europe/Rome': 'CET',
      'America/New_York': 'EST',
      'America/Chicago': 'CST',
      'America/Denver': 'MST',
      'America/Los_Angeles': 'PST',
      'America/Toronto': 'EST',
      'America/Vancouver': 'PST',
      'Australia/Sydney': 'AEST',
      'Australia/Melbourne': 'AEST',
      'Australia/Perth': 'AWST',
      'Pacific/Auckland': 'NZST',
    };
    
    return abbreviations[timezone] ?? 'UTC';
  }
}