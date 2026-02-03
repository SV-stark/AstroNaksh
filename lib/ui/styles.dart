import 'package:fluent_ui/fluent_ui.dart';

class AppStyles {
  // Colors
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep Purple
  static const Color accentColor = Color(0xFFFFD700); // Gold
  static const Color backgroundColor = Color(0xFF1A1A2E); // Dark Navy
  static const Color surfaceColor = Color(0xFF16213E); // Slightly lighter navy
  static const Color textColor = Color(
    0xFFE94560,
  ); // Reddish Pink for highlights
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;

  // Fluent Theme
  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _createAccentColor(primaryColor),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      typography: Typography.fromBrightness(brightness: Brightness.dark),
      iconTheme: const IconThemeData(color: white),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: surfaceColor,
        highlightColor: primaryColor,
        selectedIconColor: WidgetStateProperty.all(accentColor),
        unselectedIconColor: WidgetStateProperty.all(grey),
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
