/**
 * Copy from: https://material.io/components/cards/flutter#theming-a-card
 */

library Theme;

import 'include.dart';

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
    colorScheme: _shrineColorScheme,
    accentColor: shrineBrown900,
    primaryColor: shrinePink100,
    buttonColor: shrinePink100,
    scaffoldBackgroundColor: shrineBackgroundWhite,
    cardColor: shrineBackgroundWhite,
    textSelectionTheme: _customTextSelectionTheme(base.textSelectionTheme),
    errorColor: shrineErrorRed,
    buttonTheme: const ButtonThemeData(
      colorScheme: _shrineColorScheme,
      textTheme: ButtonTextTheme.normal,
    ),
    primaryIconTheme: _customIconTheme(base.iconTheme),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildShrineTextTheme(base.accentTextTheme),
    iconTheme: _customIconTheme(base.iconTheme),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base
      .copyWith(
        caption: base.caption?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: defaultLetterSpacing,
        ),
        headline1: base.headline1?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: defaultLetterSpacing,
        ),
        subtitle1: base.subtitle1?.copyWith(
          fontSize: 18,
          letterSpacing: defaultLetterSpacing,
        ),
        subtitle2: base.subtitle2?.copyWith(
          fontSize: 18,
          letterSpacing: defaultLetterSpacing,
        ),
        overline: base.overline?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          letterSpacing: defaultLetterSpacing,
        ),
        bodyText2: base.bodyText2?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: defaultLetterSpacing,
        ),
        bodyText1: base.bodyText1?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headline2: base.headline2?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headline3: base.headline3?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headline4: base.headline4?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headline5: base.headline5?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        headline6: base.headline6?.copyWith(
          letterSpacing: defaultLetterSpacing,
        ),
        button: base.button?.copyWith(
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
  primaryVariant: shrineBrown900,
  secondary: shrinePink50,
  secondaryVariant: shrineBrown900,
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
