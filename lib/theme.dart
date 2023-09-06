/**
 * Copy from: https://material.io/components/cards/flutter#theming-a-card
 */

library Theme;

import 'package:flutter/material.dart';

IconThemeData _customIconTheme(IconThemeData original) {
  return original.copyWith(color: shrineBrown900);
}

TextSelectionThemeData _customTextSelectionTheme(
    TextSelectionThemeData original) {
  return original.copyWith(
    selectionColor: shrinePink100,
    selectionHandleColor: shrineBrown900,
  );
}

ThemeData buildShrineTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryColor: shrinePink100,
    scaffoldBackgroundColor: shrineBackgroundWhite,
    cardColor: shrineBackgroundWhite,
    textSelectionTheme: _customTextSelectionTheme(base.textSelectionTheme),
    buttonTheme: const ButtonThemeData(
      colorScheme: _shrineColorScheme,
      textTheme: ButtonTextTheme.normal,
    ),
    primaryIconTheme: _customIconTheme(base.iconTheme),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    iconTheme: _customIconTheme(base.iconTheme),
    colorScheme: _shrineColorScheme
        .copyWith(secondary: shrineBrown900)
        .copyWith(error: shrineErrorRed),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base
      .copyWith(
        bodySmall: base.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: defaultLetterSpacing,
        ),
        displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: defaultLetterSpacing,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 18,
          letterSpacing: defaultLetterSpacing,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 18,
          letterSpacing: defaultLetterSpacing,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          letterSpacing: defaultLetterSpacing,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: defaultLetterSpacing,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        displayMedium: base.displayMedium?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        displaySmall: base.displaySmall?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        titleLarge: base.titleLarge?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: defaultLetterSpacing,
        ),
      )
      .apply(
        fontFamily: 'Rubik',
        displayColor: shrineBrown900,
        bodyColor: shrineBrown900,
      );
}

const ColorScheme _shrineColorScheme = ColorScheme(
  primary: shrinePink100,
  secondary: shrinePink50,
  surface: shrineSurfaceWhite,
  background: shrineBackgroundWhite,
  error: shrineErrorRed,
  onPrimary: shrineBrown900,
  onSecondary: shrineBrown900,
  onSurface: shrineBrown900,
  onBackground: shrineBrown900,
  onError: shrineSurfaceWhite,
  brightness: Brightness.light,
);

const Color shrinePink50 = Color(0xFFFEEAE6);
const Color shrinePink100 = Color(0xFFFEDBD0);
const Color shrinePink300 = Color(0xFFFBB8AC);
const Color shrinePink400 = Color(0xFFEAA4A4);

const Color shrineBrown900 = Color(0xFF442B2D);
const Color shrineBrown600 = Color(0xFF7D4F52);

const Color shrineErrorRed = Color(0xFFC5032B);

const Color shrineSurfaceWhite = Color(0xFFFFFBFA);
const Color shrineBackgroundWhite = Colors.white;

const defaultLetterSpacing = 0.03;
