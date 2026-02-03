import 'package:fluent_ui/fluent_ui.dart';

class AppStyles {
  // Colors - Modern Cosmic
  static const Color primaryColor = Color(
    0xFF6A1B9A,
  ); // Deep Purple (maintained as primary brand)
  static const Color accentColor = Color(
    0xFFD4A574,
  ); // Amber/Gold (Cosmic accent)

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF0F1115); // Deep Charcoal
  static const Color darkSurface = Color(0xFF1A1D29); // Rich Navy
  static const Color darkBorder = Color(0xFF252A3A); // Slate

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFFAFBFC); // Soft Cream
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightBorder = Color(0xFFF0F2F5); // Light Gray

  static const Color white = Colors.white;
  static const Color grey = Colors.grey;

  // Fluent Dark Theme
  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _createAccentColor(accentColor),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      typography: Typography.fromBrightness(brightness: Brightness.dark),
      iconTheme: const IconThemeData(color: white),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: darkSurface,
        highlightColor: accentColor,
        selectedIconColor: WidgetStateProperty.all(accentColor),
        unselectedIconColor: WidgetStateProperty.all(grey),
      ),
      menuColor: darkSurface,
    );
  }

  // Fluent Light Theme
  static FluentThemeData get lightTheme {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: _createAccentColor(accentColor),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      typography: Typography.fromBrightness(brightness: Brightness.light),
      iconTheme: const IconThemeData(color: Colors.black),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: lightBorder,
        highlightColor: accentColor,
        selectedIconColor: WidgetStateProperty.all(accentColor),
        unselectedIconColor: WidgetStateProperty.all(grey),
      ),
      menuColor: lightSurface,
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
