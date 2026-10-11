import 'package:flutter/material.dart';

import 'constants.dart';

/// Font family for the title, numerals and short labels. Bundled as static
/// regular and bold files, because [FontWeight] alone does not drive the
/// weight axis of a variable font.
const String displayFontFamily = 'Oxanium';

/// The app theme, built from the colour roles in [GameConstants].
///
/// Display, headline, title and label styles use [displayFontFamily]; body
/// styles stay on Roboto.
ThemeData buildGameTheme() {
  final base = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: GameConstants.primaryColor,
      onPrimary: GameConstants.onPrimaryColor,
      secondary: GameConstants.secondaryColor,
      onSecondary: GameConstants.onPrimaryColor,
      surface: GameConstants.surfaceColor,
      onSurface: GameConstants.inkColor,
      onSurfaceVariant: GameConstants.mutedColor,
      error: GameConstants.errorColor,
    ),
    scaffoldBackgroundColor: GameConstants.backgroundColor,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
  final text = base.textTheme;
  return base.copyWith(
    textTheme: text.apply(fontFamily: displayFontFamily).copyWith(
          bodyLarge: text.bodyLarge,
          bodyMedium: text.bodyMedium,
          bodySmall: text.bodySmall,
        ),
  );
}
