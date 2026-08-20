import 'package:flutter/material.dart';

/// Design tokens extracted from `screen_sample.png`.
/// Theme: "スポーツ速報 × 株式市場 × 移籍市場" — dark navy/black base,
/// red for BREAKING, green for AGREEMENT/OFFICIAL, blue for RUMOUR.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0D14);
  static const Color surface = Color(0xFF12161F);
  static const Color card = Color(0xFF1A1F2B);
  static const Color cardBorder = Color(0xFF262C3A);

  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFF9AA1B2);
  static const Color textMuted = Color(0xFF5D6478);

  // Status accents
  static const Color rumour = Color(0xFF4C8DFF);
  static const Color interest = Color(0xFF6FD1FF);
  static const Color contact = Color(0xFF7C7CFF);
  static const Color negotiation = Color(0xFFFFC24C);
  static const Color bid = Color(0xFFFFA24C);
  static const Color agreement = Color(0xFF4CD97B);
  static const Color finalStage = Color(0xFFFF4C4C);
  static const Color official = Color(0xFF2ED573);
  static const Color collapsed = Color(0xFF6B7280);

  static const Color breaking = Color(0xFFFF3B3B);

  static const Color gaugeTrack = Color(0xFF262C3A);

  // Product accents used by the TRANSFER NOW identity / onboarding flow.
  static const Color accentCyan = Color(0xFF69E7FF);
  static const Color accentCyanStrong = Color(0xFF38D7FF);
  static const Color accentLime = Color(0xFFB6FF3B);
  static const Color accentLimeGlow = Color(0xFF8DFF00);
  static const Color accentLimeBorder = Color(0xFFCEFF7C);
  static const Color backgroundGlow = Color(0xFF102B37);
}
