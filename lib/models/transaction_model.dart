// lib/models/transaction_model.dart - Updated with SimpleLocationData

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// A single expense/income transaction with optional location data.
class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final DateTime timestamp;
  final SimpleLocationData? location;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.location,
  });

  /// Construct from a Firestore document snapshot.
  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'] != null 
          ? SimpleLocationData.fromMap(Map<String, dynamic>.from(data['location']))
          : null,
    );
  }

  /// Convert to a map for uploading to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      if (location != null) 'location': location!.toMap(),
    };
  }

  /// Create a copy with updated values
  TransactionModel copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? timestamp,
    SimpleLocationData? location,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  /// Get distance from another location
  double? getDistanceFrom(double lat, double lng) {
    return location?.getDistanceFrom(lat, lng);
  }

  /// Get location display name
  String get locationName {
    return location?.shortName ?? 'No location';
  }

  /// Check if transaction has location data
  bool get hasLocation => location != null;
}

class SimpleLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String street;
  final String name;
  final DateTime capturedAt;

  SimpleLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.street,
    required this.name,
    required this.capturedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'street': street,
      'name': name,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory SimpleLocationData.fromMap(Map<String, dynamic> map) {
    return SimpleLocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      postalCode: map['postalCode'] ?? '',
      street: map['street'] ?? '',
      name: map['name'] ?? '',
      capturedAt: DateTime.parse(map['capturedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get shortName {
    if (name.isNotEmpty && name != address) {
      return name;
    }
    
    // Extract meaningful part from address
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    
    return 'Unknown Location';
  }

  double getDistanceFrom(double lat, double lng) {
    // Simple distance calculation (Haversine formula)
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        latitude.toRadians().cos() * lat.toRadians().cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * (a.sqrt()).atan2((1 - a).sqrt());
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

extension on double {
  double toRadians() => this * (math.pi / 180);
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double atan2(double other) => math.atan2(this, other);
}