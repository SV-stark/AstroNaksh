import 'package:fluent_ui/fluent_ui.dart';

class AppStyles {
  // Colors - Professional Fluent
  static const Color primaryColor = Color(0xFF0078D4); // Windows Blue
  static const Color accentColor = Color(0xFF005A9E);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF202020);
  static const Color darkSurface = Color(0xFF2B2B2B);
  static const Color darkBorder = Color(0xFF333333);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);

  static const Color white = Colors.white;
  static const Color grey = Colors.grey;

  // Spacing
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;

  // Fluent Dark Theme
  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _createAccentColor(primaryColor),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      typography: Typography.fromBrightness(brightness: Brightness.dark),
      iconTheme: const IconThemeData(color: white),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: darkSurface,
        highlightColor: primaryColor,
      ),
    );
  }

  // Fluent Light Theme
  static FluentThemeData get lightTheme {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: _createAccentColor(primaryColor),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      typography: Typography.fromBrightness(brightness: Brightness.light),
      iconTheme: const IconThemeData(color: Colors.black),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: lightBorder,
        highlightColor: primaryColor,
      ),
    );
  }

  static AccentColor _createAccentColor(Color color) {
    return AccentColor.swatch({
      'normal': color,
      'dark': color,
      'light': color,
      'darker': color,
      'lighter': color,
      'darkest': color,
      'lightest': color,
    });
  }
}
