// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../routes.dart';
import '../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext c) {
    Future.delayed(const Duration(seconds:1), () {
      Navigator.pushReplacementNamed(c, Routes.login);
    });
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'SavePlus+',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
