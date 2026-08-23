import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
      );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 36 / 28,
        letterSpacing: -0.01 * 28,
      );

  static TextStyle get headlineSmall => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 28 / 20,
        letterSpacing: 0.02 * 20,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        height: 32 / 18,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        height: 28 / 16,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
        letterSpacing: 0.08 * 13,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      );

  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
