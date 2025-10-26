// lib/routes.dart

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

class Routes {
  static const splash   = '/';
  static const login    = '/login';
  static const signup   = '/signup';
  static const home     = '/home';
  static const goal     = '/goal';
  static const reports  = '/reports';
  static const settings = '/settings';

  static final all = <String, WidgetBuilder>{
    splash  : (ctx) => const SplashScreen(),
    login   : (ctx) => const LoginScreen(),
    signup  : (ctx) => const SignupScreen(),
    home    : (ctx) => const HomeScreen(),
    goal    : (ctx) => const GoalScreen(),
    reports : (ctx) => const ReportsScreen(),
    settings: (ctx) => const SettingsScreen(),
  };
}
