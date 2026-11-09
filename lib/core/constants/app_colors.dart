import 'package:flutter/material.dart';

class AppColors {
  // Brand Emerald Green (matches screenshot #22C55E / #16A34A)
  static const Color primary = Color(0xFF22C55E); // Bright Emerald Green
  static const Color primaryDark = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFF4ADE80);
  static const Color primaryContainer = Color(0xFF0E4D2B);

  // Accent Amber / Gold
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentContainer = Color(0xFF3B2708);

  // Status Colors
  static const Color statusPaid = Color(0xFF22C55E);
  static const Color statusPaidBg = Color(0xFF133824);

  static const Color statusPartial = Color(0xFFF59E0B);
  static const Color statusPartialBg = Color(0xFF38280E);

  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0xFF3A1517);

  static const Color statusUpcoming = Color(0xFF64748B);
  static const Color statusUpcomingBg = Color(0xFF1E2838);

  // Dark Theme Background & Surfaces (Exact match to screenshot)
  static const Color scaffoldDark = Color(0xFF0D1219);
  static const Color cardDark = Color(0xFF161E2A);
  static const Color cardDarkElevated = Color(0xFF1B2433);
  static const Color inputDark = Color(0xFF151D28);
  static const Color borderDark = Color(0xFF243042);
  static const Color iconButtonDark = Color(0xFF1A2330);

  // Light Theme (also available if switched)
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF8C9EB5);
  static const Color textMuted = Color(0xFF5D6F85);
  static const Color textDark = Color(0xFF0F172A);
}
