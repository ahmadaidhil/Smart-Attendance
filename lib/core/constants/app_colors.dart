import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Maroon)
  static const Color primaryDark = Color(0xFF2B0000);    // Deep Maroon
  static const Color primaryMid = Color(0xFF4A0000);     // Maroon Mid
  static const Color primaryLight = Color(0xFF8B0000);   // Maroon Light

  // Accent Colors
  static const Color accent = Color(0xFF8B0000);          // Primary Maroon
  static const Color accentLight = Color(0xFFC70000);    // Bright Red
  static const Color accentGlow = Color(0xFFFF4D4D);     // Red Glow

  // Status Colors
  static const Color success = Color(0xFF10B981);        // Emerald
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);        // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFEF4444);         // Red
  static const Color dangerLight = Color(0xFFF87171);
  static const Color info = Color(0xFF8B5CF6);           // Purple

  // Admin Palette
  static const Color adminPrimary = Color(0xFF8B0000);   // Dark Red / Maroon
  static const Color adminPrimaryDark = Color(0xFF4A0000); // Very Dark Maroon
  static const Color adminLight = Color(0xFFFFF0F0);     // Very light pinkish red
  static const Color adminBg = Color(0xFFF8F9FA);        // Light gray background

  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B0000), Color(0xFF600000)],
  );

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // Glass
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBgDark = Color(0x0DFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B0000), Color(0xFF4A0000)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2B0000), Color(0xFF4A0000), Color(0xFF2B0000)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
