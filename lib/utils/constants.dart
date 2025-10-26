// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light mode colors
  static const primary = Color(0xFF1D4E89);       // navy
  static const accent = Color(0xFF4AAB4F);        // green
  static const lime = Color(0xFFF0F4F1);          // light grey-green
  static const orangeAlert = Color(0xFFEA8630);   // alert orange
  static const navy = Color(0xFF224066);
  static const grayLight = Color(0xFFF2F2F2);     // card & input background

  // Dark mode colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2A2A2A);
  static const darkInput = Color(0xFF2A2A2A);
  static const darkText = Colors.white;
  static const darkTextSecondary = Color(0xFFB0B0B0);
  
  // Helper method to get appropriate colors based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : Colors.white;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : Colors.white;
  }
  
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCard 
        : grayLight;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkText 
        : navy;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : Colors.grey.shade600;
  }
}

class AppTypography {
  static const String fontFamily = 'Inter';
  static const FontWeight heading = FontWeight.w600;
  static const FontWeight body = FontWeight.w400;
  static const FontWeight label = FontWeight.w500;
}