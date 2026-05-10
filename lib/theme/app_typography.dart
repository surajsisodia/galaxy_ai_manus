import 'package:flutter/material.dart';

class AppFontFamilies {
  static const body = 'Inter';
  static const heading = 'Inter';
  static const mono = 'JetBrainsMono';
}

class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: AppFontFamilies.heading,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: AppFontFamilies.body),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: AppFontFamilies.body),
      bodySmall: base.bodySmall?.copyWith(fontFamily: AppFontFamilies.body),
      labelLarge: base.labelLarge?.copyWith(fontFamily: AppFontFamilies.body),
      labelMedium: base.labelMedium?.copyWith(fontFamily: AppFontFamilies.body),
      labelSmall: base.labelSmall?.copyWith(fontFamily: AppFontFamilies.body),
    );
  }

  static TextStyle mono([TextStyle? base]) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppFontFamilies.mono,
    );
  }
}
