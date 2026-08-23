import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color background = Color(0xFF1C1B16);
  static const Color surface = Color(0xFF1C1B16);
  static const Color surfaceDim = Color(0xFF15130F);
  static const Color surfaceBright = Color(0xFF3B3934);
  static const Color surfaceContainerLowest = Color(0xFF0F0E0A);
  static const Color surfaceContainerLow = Color(0xFF1D1C17);
  static const Color surfaceContainer = Color(0xFF21201B);
  static const Color surfaceContainerHigh = Color(0xFF2C2A25);
  static const Color surfaceContainerHighest = Color(0xFF36352F);
  static const Color onSurface = Color(0xFFE6E1D9);
  static const Color onSurfaceVariant = Color(0xFFCFC5B3);
  static const Color inverseSurface = Color(0xFFE7E2DA);
  static const Color inverseOnSurface = Color(0xFF32302B);
  static const Color outline = Color(0xFF98907F);
  static const Color outlineVariant = Color(0xFF4C4638);
  static const Color surfaceTint = Color(0xFFE3C36C);
  static const Color primary = Color(0xFFFFDF8C);
  static const Color onPrimary = Color(0xFF3D2F00);
  static const Color primaryContainer = Color(0xFFE3C36C);
  static const Color onPrimaryContainer = Color(0xFF664F00);
  static const Color inversePrimary = Color(0xFF735B0C);
  static const Color secondary = Color(0xFFCAC6BD);
  static const Color onSecondary = Color(0xFF32302A);
  static const Color secondaryContainer = Color(0xFF484740);
  static const Color onSecondaryContainer = Color(0xFFB8B5AC);
  static const Color tertiary = Color(0xFFDDE0FF);
  static const Color onTertiary = Color(0xFF222C5F);
  static const Color tertiaryContainer = Color(0xFFB9C3FF);
  static const Color onTertiaryContainer = Color(0xFF454F83);
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static ColorScheme colorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      surfaceTint: surfaceTint,
    );
  }
}
