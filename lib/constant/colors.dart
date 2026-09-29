import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ---------------------------------------------------------------------------
  // 1. Primary & Brand Colors
  // ---------------------------------------------------------------------------
  static const Color primary = Color(
    0xFF25A67D,
  ); // Deep Indigo Blue (Trust & Main Theme)
  static const Color primaryLight = Color(0xFF818CF8); // Light Indigo
  static const Color primaryDark = Color(0xFF3730A3); // Dark Indigo

  // ---------------------------------------------------------------------------
  // 2. Financial Transaction Colors
  // ---------------------------------------------------------------------------
  static const Color income = Color(
    0xFF25A67D,
  ); // Jade Green (Income / Cash In)
  static const Color expense = Color(
    0xFFE11D48,
  ); // Rose Red (Outcome / Cash Out)

  // ---------------------------------------------------------------------------
  // 3. Dynamic Daily Budget Limit Status Colors
  // ---------------------------------------------------------------------------
  static const Color safeState = Color(
    0xFF10B981,
  ); // Green (0% - 70% Budget Spent)
  static const Color warningState = Color(
    0xFFF59E0B,
  ); // Amber Yellow (71% - 90% Budget Spent)
  static const Color dangerState = Color(0xFFEF4444); // Red (90%+ Budget Spent)

  // ---------------------------------------------------------------------------
  // 4. Background & Surface Colors (Light Mode)
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF8FAFC); // Soft Gray / Off-White
  static const Color cardSurface = Color(
    0xFFFFFFFF,
  ); // Pure White (Cards, Dialogs, Sheets)
  static const Color divider = Color(
    0xFFE2E8F0,
  ); // Light Slate Gray (Borders & Dividers)

  // ---------------------------------------------------------------------------
  // 5. Typography / Text Colors
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Deep Slate Black (Headings, Main Text)
  static const Color textSecondary = Color(
    0xFF64748B,
  ); // Slate Gray (Subtitles, Descriptions)
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Light Slate (Placeholders, Disabled Text)
  static const Color textOnPrimary = Color(
    0xFFFFFFFF,
  ); // White text for primary buttons

  // ---------------------------------------------------------------------------
  // 6. Optional Dark Mode Colors
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(
    0xFF0F172A,
  ); // Deep Slate Dark Background
  static const Color darkCardSurface = Color(0xFF1E293B); // Navy Slate Surface
}
