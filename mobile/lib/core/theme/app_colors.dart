import 'package:flutter/material.dart';

/// Central color palette for Labour Connect.
/// Brand: confident indigo primary + warm amber accent (trust + energy).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F46E5); // indigo 600
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFEEF2FF); // indigo 50
  static const Color accent = Color(0xFFF59E0B); // amber 500
  static const Color accentLight = Color(0xFFFEF3C7);

  // Neutrals
  static const Color ink = Color(0xFF0F172A); // slate 900
  static const Color textPrimary = Color(0xFF1E293B); // slate 800
  static const Color textSecondary = Color(0xFF64748B); // slate 500
  static const Color textMuted = Color(0xFF94A3B8); // slate 400
  static const Color border = Color(0xFFE2E8F0); // slate 200
  static const Color divider = Color(0xFFF1F5F9); // slate 100
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // slate 50
  static const Color scaffold = Color(0xFFF6F7FB);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> avatarPalette = [
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
  ];
}
