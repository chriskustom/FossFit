import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light({
    String? fontFamily,
    double? fontSize,
    int? seedColor,
  }) {
    final colourScheme = ColorScheme.fromSeed(
      seedColor: seedColor == null ? const Color.fromARGB(255, 209, 1, 199) : Color(seedColor),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colourScheme,
      textTheme: _applyFont(
        ThemeData.light(useMaterial3: true).textTheme,
        fontFamily,
        fontSize,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colourScheme.primaryContainer,
        foregroundColor: colourScheme.onSurface,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData dark({
    String? fontFamily,
    double? fontSize,
    int? seedColor,
  }) {
    final colourScheme = ColorScheme.fromSeed(
      seedColor: seedColor == null ? const Color.fromARGB(255, 209, 1, 199) : Color(seedColor),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colourScheme,
      textTheme: _applyFont(
        ThemeData.dark(useMaterial3: true).textTheme,
        fontFamily,
        fontSize,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colourScheme.primaryContainer,
        foregroundColor: colourScheme.onSurface,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  static TextTheme _applyFont(
    TextTheme original,
    String? fontFamily,
    double? fontSize,
  ) {
    if (fontFamily == null || fontSize == null) return original;

    const double materialBase = 14.0;
    final double factor = fontSize / materialBase;

    TextStyle? normalize(TextStyle? style) {
      if (style == null) return null;
      return style.fontSize == null ? style.copyWith(fontSize: materialBase) : style;
    }

    final normalized = original.copyWith(
      displayLarge: normalize(original.displayLarge),
      displayMedium: normalize(original.displayMedium),
      displaySmall: normalize(original.displaySmall),
      headlineLarge: normalize(original.headlineLarge),
      headlineMedium: normalize(original.headlineMedium),
      headlineSmall: normalize(original.headlineSmall),
      titleLarge: normalize(original.titleLarge),
      titleMedium: normalize(original.titleMedium),
      titleSmall: normalize(original.titleSmall),
      bodyLarge: normalize(original.bodyLarge),
      bodyMedium: normalize(original.bodyMedium),
      bodySmall: normalize(original.bodySmall),
      labelLarge: normalize(original.labelLarge),
      labelMedium: normalize(original.labelMedium),
      labelSmall: normalize(original.labelSmall),
    );

    return normalized.apply(fontFamily: fontFamily, fontSizeFactor: factor);
  }
}

extension ThemeX on BuildContext {
  LinearGradient get linearGradientTLBR => LinearGradient(
        colors: [
          Theme.of(this).colorScheme.primaryContainer,
          Theme.of(this).colorScheme.primaryContainer,
        ],
        begin: AlignmentGeometry.topLeft,
        end: AlignmentGeometry.bottomRight,
      );
  LinearGradient get linearGradientLR => LinearGradient(
        colors: [
          Theme.of(this).colorScheme.primaryContainer,
          Theme.of(this).colorScheme.primaryContainer,
        ],
        begin: AlignmentGeometry.centerLeft,
        end: AlignmentGeometry.centerRight,
      );
}
