import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color purple = Color(0xFF6C5CE7);
  static const Color purpleLight = Color(0xFF8B7FF0);
  static const Color purpleDark = Color(0xFF4E3DC8);
  static const Color pink = Color(0xFFE040FB);
  static const Color pinkLight = Color(0xFFC026D3);
  static const Color cyan = Color(0xFF00CEC9);
  static const Color cyanDark = Color(0xFF00A8A4);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeDark = Color(0xFFEA6B0F);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);

  // Dark Theme
  static const Color bgDark = Color(0xFF0D0D14);
  static const Color bgCardDark = Color(0xFF141420);
  static const Color bgElevatedDark = Color(0xFF1C1C2A);
  static const Color bgHoverDark = Color(0x0AFFFFFF);
  static const Color borderDark = Color(0x28FFFFFF);
  static const Color borderHoverDark = Color(0x24FFFFFF);
  static const Color inputBgDark = Color(0x1AFFFFFF);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0x99FFFFFF);
  static const Color textMutedDark = Color(0x59FFFFFF);
  static const Color textFaintDark = Color(0x33FFFFFF);

  // Light Theme
  static const Color bgLight = Color(0xFFF3F2FA);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgElevatedLight = Color(0xFFEEEDF8);
  static const Color bgHoverLight = Color(0x0D6C5CE7);
  static const Color borderLight = Color(0x1F6C5CE7);
  static const Color borderHoverLight = Color(0x406C5CE7);
  static const Color inputBgLight = Color(0x0F6C5CE7);
  static const Color textPrimaryLight = Color(0xFF16113A);
  static const Color textSecondaryLight = Color(0xA616113A);
  static const Color textMutedLight = Color(0x6616113A);
  static const Color textFaintLight = Color(0x3316113A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, pink],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, orange],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, purple],
  );

  static const LinearGradient triGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, pink, orange],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, cyan],
  );
}
