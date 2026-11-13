import 'package:expenz/auth/login.dart';
import 'package:expenz/constant/colors.dart';
import 'package:expenz/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:expenz/services/appearance_settings.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
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
        scrollBehavior: const _AppScrollBehavior(),
        themeMode: mode,
        darkTheme: _styleButtons(
          ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Inter',
            colorScheme: const ColorScheme.dark(
              primary: AppColors.darkAccent,
              onPrimary: AppColors.darkBackground,
              secondary: AppColors.darkAccent,
              onSecondary: AppColors.darkBackground,
              secondaryContainer: AppColors.darkRaisedSurface,
              onSecondaryContainer: AppColors.darkText,
              error: Color(0xFFF09C96),
              surface: AppColors.darkCardSurface,
              onSurface: AppColors.darkText,
              onSurfaceVariant: AppColors.darkTextSecondary,
              outline: AppColors.darkOutline,
              outlineVariant: AppColors.darkDivider,
              surfaceContainerLowest: AppColors.darkBackground,
              surfaceContainerLow: AppColors.darkCardSurface,
              surfaceContainer: AppColors.darkCardSurface,
              surfaceContainerHigh: AppColors.darkRaisedSurface,
              surfaceContainerHighest: AppColors.darkRaisedSurface,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            cardTheme: const CardThemeData(
              color: AppColors.darkCardSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: AppColors.darkDivider),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.darkCardSurface,
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: AppColors.darkCardSurface,
              surfaceTintColor: Colors.transparent,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkBackground,
              foregroundColor: AppColors.darkText,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppColors.darkAccent,
              selectionColor: AppColors.darkAccent.withValues(alpha: 0.25),
              selectionHandleColor: AppColors.darkAccent,
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.darkRaisedSurface,
              contentTextStyle: TextStyle(color: AppColors.darkText),
            ),
          ),
        ),
        title: 'Expenz',
        debugShowCheckedModeBanner: false,
        theme: _styleButtons(
          ThemeData(
            fontFamily: 'Inter',
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              secondary: AppColors.safeState,
              onSecondary: AppColors.textOnPrimary,
              secondaryContainer: AppColors.divider,
              onSecondaryContainer: AppColors.textPrimary,
              error: AppColors.dangerState,
              surface: AppColors.cardSurface,
              onSurface: AppColors.textPrimary,
              onSurfaceVariant: AppColors.textSecondary,
              outline: AppColors.textMuted,
              outlineVariant: AppColors.divider,
              surfaceContainerHighest: AppColors.divider,
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
        ),

        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
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

/// Quiet, ink-like outlines keep actions consistent in either appearance.
ThemeData _styleButtons(ThemeData theme) {
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final outlined = OutlinedButton.styleFrom(
    foregroundColor: colors.onSurface,
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    side: BorderSide(color: colors.outline),
    shape: shape,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
  return theme.copyWith(
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: outlined.copyWith(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: shape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      shape: CircleBorder(side: BorderSide(color: colors.outline)),
    ),
  );
}

/// Keep pages from stretching or bouncing beyond their content.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
