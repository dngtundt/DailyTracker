import 'package:flutter/material.dart';

class AppColors {
  // Main palette - deep dark with vibrant accents
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1C2537);
  static const Color border = Color(0xFF2A3650);

  // Primary gradient colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color secondary = Color(0xFF00D4AA);
  static const Color accent = Color(0xFFFF6B6B);

  // Text
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted = Color(0xFF4A5568);

  // Rank colors
  static const Color rankIron = Color(0xFF9CA3AF);
  static const Color rankBronze = Color(0xFFCD7C2F);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFF67E8F9);
  static const Color rankDiamond = Color(0xFF818CF8);
  static const Color rankMaster = Color(0xFFE879F9);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1C2537)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getRankGradient(String rank) {
    switch (rank.toLowerCase()) {
      case 'iron': return const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)]);
      case 'bronze': return const LinearGradient(colors: [Color(0xFFCD7C2F), Color(0xFF92400E)]);
      case 'gold': return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]);
      case 'platinum': return const LinearGradient(colors: [Color(0xFF67E8F9), Color(0xFF06B6D4)]);
      case 'diamond': return const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF4F46E5)]);
      case 'master': return const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFF9333EA)]);
      default: return primaryGradient;
    }
  }
}
