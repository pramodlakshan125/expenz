import 'package:expenz/auth/login.dart';
import 'package:expenz/constant/colors.dart';
import 'package:expenz/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:expenz/services/appearance_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppearanceSettings.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppearanceSettings.mode,
      builder: (context, mode, child) => MaterialApp(
        themeMode: mode,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            primary: const Color(0xFF67DBB2),
            surface: AppColors.darkCardSurface,
          ),
          scaffoldBackgroundColor: AppColors.darkBackground,
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        title: 'Expenz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: AppColors.textOnPrimary,
            surface: AppColors.cardSurface,
            onSurface: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          // Floating messages appear above the add button without moving it.
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.cardSurface,
            surfaceTintColor: Colors.transparent,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.primary,
            selectionColor: AppColors.primary.withValues(alpha: 0.25),
            selectionHandleColor: AppColors.primary,
          ),
        ),

        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // 1. If Firebase finds a saved user on the phone -> Go to Home Page!
            if (snapshot.hasData) {
              return const MainScreen();
            }

            // 2. If NO user is saved -> Go to Login Page!
            return const LogIn();
          },
        ),
      ),
    );
  }
}
