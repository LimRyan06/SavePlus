import 'package:flutter/material.dart';
import 'package:saveplus_plus/utils/constants.dart';
import 'package:saveplus_plus/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SavePlus+',
      theme: ThemeData(
        fontFamily: AppTypography.fontFamily,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          error: AppColors.orangeAlert,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.heading,
            fontSize: 20,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.navy,
          elevation: 8,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.heading,
            fontSize: 18,
            color: AppColors.navy,
          ),
          bodyMedium: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.body,
            fontSize: 14,
            color: AppColors.navy,
          ),
          labelSmall: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.label,
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
      ),
      initialRoute: Routes.splash,
      routes: Routes.all,
    );
  }
}
