// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
 import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signOut();

  runApp(const SavePlusApp());
}

class SavePlusApp extends StatelessWidget {
  const SavePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<AppState>(
          create: (ctx) => AppState(
            ctx.read<AuthService>(),
            ctx.read<FirestoreService>(),
          ),
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'SavePlus+',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthGate(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.orangeAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.heading,
          fontSize: 20,
          color: AppColors.navy,
        ),
        iconTheme: IconThemeData(color: AppColors.navy),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.navy,
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
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFF1E1E1E),
        error: AppColors.orangeAlert,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF121212),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.heading,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.heading,
          fontSize: 18,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.body,
          fontSize: 14,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.label,
          fontSize: 12,
          color: AppColors.accent,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}