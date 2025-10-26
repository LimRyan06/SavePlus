// lib/utils/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'package:saveplus_plus/utils/constants.dart';

class SnackBarHelper {
  /// Shows a success SnackBar with proper dark mode support
  static void showSuccess(
    BuildContext context,
    String message, {
    bool isDark = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isDark 
            ? AppColors.accent 
            : AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error SnackBar with proper dark mode support
  static void showError(
    BuildContext context,
    String message, {
    bool isDark = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.orangeAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows an info SnackBar with proper dark mode support
  static void showInfo(
    BuildContext context,
    String message, {
    bool isDark = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isDark 
            ? const Color(0xFF2A2A2A) 
            : Colors.grey.shade100,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a custom SnackBar with specified colors
  static void showCustom(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    Color? textColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}