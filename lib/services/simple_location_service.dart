// lib/services/simple_location_service.dart
// No Google API key required!

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // FREE - uses device's built-in geocoding
import 'package:saveplus_plus/models/transaction_model.dart'; // Import SimpleLocationData from here

class SimpleLocationService {
  
  /// Check if location services are available
  static Future<bool> isLocationAvailable() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission != LocationPermission.deniedForever;
  }

  /// Get current GPS coordinates (FREE - uses device GPS)
  static Future<Position?> getCurrentLocation() async {
    try {
      if (!await isLocationAvailable()) return null;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Convert coordinates to address (FREE - uses device's geocoding)
  static Future<SimpleLocationData?> getLocationInfo(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        return SimpleLocationData(
          latitude: lat,
          longitude: lng,
          address: _buildAddress(place),
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          postalCode: place.postalCode ?? '',
          street: place.street ?? '',
          name: place.name ?? '',
          capturedAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting location info: $e');
      return null;
    }
  }

  /// Build readable address from placemark
  static String _buildAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.name != null && place.name!.isNotEmpty) {
      parts.add(place.name!);
    }
    if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    return parts.join(', ');
  }

  /// Calculate distance between two points (FREE - math calculation)
  static double calculateDistance(
    double lat1, double lng1, 
    double lat2, double lng2
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Smart category suggestion based on location patterns and keywords
  static String suggestCategory(SimpleLocationData location) {
    final address = location.address.toLowerCase();
    final name = location.name.toLowerCase();
    final street = location.street.toLowerCase();
    
    // Combine all text for analysis
    final allText = '$address $name $street';
    
    // Food keywords
    if (_containsAny(allText, [
      'restaurant', 'cafe', 'coffee', 'food', 'pizza', 'burger', 
      'mcdonald', 'kfc', 'subway', 'starbucks', 'domino', 'taco',
      'kitchen', 'dining', 'bistro', 'bakery', 'deli', 'bar',
      'mamak', 'kopitiam', 'restoran', 'kedai makan'
    ])) {
      return 'Food';
    }
    
    // Transport keywords
    if (_containsAny(allText, [
      'petrol', 'gas', 'fuel', 'station', 'shell', 'petronas', 
      'mobil', 'caltex', 'bp', 'taxi', 'grab', 'uber', 'bus',
      'train', 'mrt', 'lrt', 'airport', 'parking'
    ])) {
      return 'Transport';
    }
    
    // Work keywords
    if (_containsAny(allText, [
      'office', 'company', 'workplace', 'coworking', 'business center',
      'corporate', 'building', 'tower', 'headquarters', 'branch',
      'meeting room', 'conference', 'workshop'
    ])) {
      return 'Work';
    }
    
    // Entertainment keywords
    if (_containsAny(allText, [
      'cinema', 'theater', 'theatre', 'concert', 'club', 'arcade', 
      'bowling', 'karaoke', 'park', 'museum', 'zoo', 'aquarium',
      'amusement', 'theme park', 'casino', 'bar', 'pub', 'lounge',
      'gym', 'fitness', 'spa', 'recreation', 'sports center'
    ])) {
      return 'Entertainment';
    }
    
    // Bills/Services keywords
    if (_containsAny(allText, [
      'bank', 'atm', 'hospital', 'clinic', 'doctor', 'medical',
      'post office', 'government', 'service', 'repair',
      'insurance', 'telekom', 'unifi', 'utility', 'pharmacy'
    ])) {
      return 'Bills';
    }
    
    return 'Other';
  }

  /// Check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Group transactions by location proximity
  static List<LocationGroup> groupTransactionsByLocation(
    List<TransactionWithSimpleLocation> transactions,
    {double radiusMeters = 100}
  ) {
    List<LocationGroup> groups = [];
    
    for (final transaction in transactions) {
      if (transaction.location == null) continue;
      
      // Find existing group within radius
      LocationGroup? existingGroup;
      for (final group in groups) {
        final distance = calculateDistance(
          transaction.location!.latitude,
          transaction.location!.longitude,
          group.centerLat,
          group.centerLng,
        );
        
        if (distance <= radiusMeters) {
          existingGroup = group;
          break;
        }
      }
      
      if (existingGroup != null) {
        // Add to existing group
        existingGroup.transactions.add(transaction);
        existingGroup.totalAmount += transaction.amount.abs();
      } else {
        // Create new group
        groups.add(LocationGroup(
          centerLat: transaction.location!.latitude,
          centerLng: transaction.location!.longitude,
          displayName: transaction.location!.shortName,
          transactions: [transaction],
          totalAmount: transaction.amount.abs(),
        ));
      }
    }
    
    // Sort by total spending
    groups.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return groups;
  }

  /// Get spending insights by location
  static LocationInsights getSpendingInsights(
    List<TransactionWithSimpleLocation> transactions
  ) {
    final groups = groupTransactionsByLocation(transactions);
    
    double totalSpending = 0;
    Map<String, double> categorySpending = {};
    
    for (final transaction in transactions) {
      if (transaction.amount < 0) { // Only expenses
        totalSpending += transaction.amount.abs();
        
        final category = transaction.category;
        categorySpending[category] = 
            (categorySpending[category] ?? 0) + transaction.amount.abs();
      }
    }
    
    return LocationInsights(
      topSpendingLocations: groups.take(5).toList(),
      totalLocations: groups.length,
      totalSpending: totalSpending,
      categoryBreakdown: categorySpending,
    );
  }
}

class TransactionWithSimpleLocation {
  final String id;
  final double amount;
  final String category;
  final DateTime timestamp;
  final SimpleLocationData? location;

  TransactionWithSimpleLocation({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.location,
  });
}

class LocationGroup {
  final double centerLat;
  final double centerLng;
  final String displayName;
  final List<TransactionWithSimpleLocation> transactions;
  double totalAmount;

  LocationGroup({
    required this.centerLat,
    required this.centerLng,
    required this.displayName,
    required this.transactions,
    required this.totalAmount,
  });
}

class LocationInsights {
  final List<LocationGroup> topSpendingLocations;
  final int totalLocations;
  final double totalSpending;
  final Map<String, double> categoryBreakdown;

  LocationInsights({
    required this.topSpendingLocations,
    required this.totalLocations,
    required this.totalSpending,
    required this.categoryBreakdown,
  });
}