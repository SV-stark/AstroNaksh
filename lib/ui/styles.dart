import 'package:fluent_ui/fluent_ui.dart';

/// App theme types
enum AppThemeMode {
  light,
  dark,
  oled, // True black OLED optimized
}

class AppStyles {
  // Colors - Professional Fluent
  static const Color primaryColor = Color(0xFF0078D4); // Windows Blue
  static const Color accentColor = Color(0xFF005A9E);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF202020);
  static const Color darkSurface = Color(0xFF2B2B2B);
  static const Color darkBorder = Color(0xFF333333);

  // OLED Mode Palette - True black for AMOLED displays
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0D0D0D);
  static const Color oledSurfaceElevated = Color(0xFF141414);
  static const Color oledBorder = Color(0xFF1F1F1F);

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

  // Current theme mode
  static AppThemeMode _currentThemeMode = AppThemeMode.dark;

  static AppThemeMode get currentThemeMode => _currentThemeMode;
  
  static set currentThemeMode(AppThemeMode mode) {
    _currentThemeMode = mode;
  }

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

  // Fluent OLED Theme - True black optimized
  static FluentThemeData get oledTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _createAccentColor(const Color(0xFFBB86FC)), // Purple accent for OLED
      scaffoldBackgroundColor: oledBackground,
      cardColor: oledSurface,
      typography: Typography.fromBrightness(brightness: Brightness.dark),
      iconTheme: const IconThemeData(color: white),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: oledSurface,
        highlightColor: const Color(0xFFBB86FC),
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

  /// Get theme based on current mode
  static FluentThemeData get theme {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.oled:
        return oledTheme;
    }
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

  /// Get background color for current theme
  static Color get backgroundColor {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return lightBackground;
      case AppThemeMode.dark:
        return darkBackground;
      case AppThemeMode.oled:
        return oledBackground;
    }
  }

  /// Get surface color for current theme
  static Color get surfaceColor {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return lightSurface;
      case AppThemeMode.dark:
        return darkSurface;
      case AppThemeMode.oled:
        return oledSurface;
    }
  }

  /// Get border color for current theme
  static Color get borderColor {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return lightBorder;
      case AppThemeMode.dark:
        return darkBorder;
      case AppThemeMode.oled:
        return oledBorder;
    }
  }
}
