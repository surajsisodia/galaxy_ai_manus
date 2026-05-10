import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A67FF)),
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      scaffoldBackgroundColor: base.colorScheme.surface,
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8EA2FF),
        brightness: Brightness.dark,
      ),
    );

    final darkColorScheme = base.colorScheme.copyWith(
      surface: AppColors.darkBackground,
    );

    return base.copyWith(
      colorScheme: darkColorScheme,
      textTheme: AppTypography.textTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
