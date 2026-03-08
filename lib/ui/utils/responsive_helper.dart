import 'package:fluent_ui/fluent_ui.dart'
    hide Colors; // Hide material Colors to avoid conflict
import 'dart:io';

/// Utility class for responsive design
/// Optimizes UI for mobile portrait mode while preserving desktop experience
class ResponsiveHelper {
  static bool _isMobileCache = false;
  static bool _cacheInitialized = false;

  /// Check if running on mobile platform (Android/iOS)
  static bool get isMobilePlatform {
    if (!_cacheInitialized) {
      _isMobileCache = Platform.isAndroid || Platform.isIOS;
      _cacheInitialized = true;
    }
    return _isMobileCache;
  }

  /// Check if current orientation is portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if screen width is mobile-sized (< 600px)
  static bool isMobileWidth(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if should use mobile optimized layout
  static bool useMobileLayout(BuildContext context) {
    return isMobilePlatform && isPortrait(context);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (useMobileLayout(context)) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    }
    return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  }

  /// Get responsive chart size
  static double getChartSize(BuildContext context) {
    if (useMobileLayout(context)) {
      return MediaQuery.of(context).size.width - 32; // Full width minus padding
    }
    return 350; // Desktop default
  }

  /// Get grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    if (useMobileLayout(context)) {
      return 1; // Single column on mobile portrait
    }
    return 2; // Desktop default
  }

  /// Get child aspect ratio for grid
  static double getGridChildAspectRatio(BuildContext context) {
    if (useMobileLayout(context)) {
      return 2.5; // Wider cards on mobile for better touch targets
    }
    return 2.2;
  }

  /// Get appropriate NavigationPaneDisplayMode
  static PaneDisplayMode getNavigationPaneDisplayMode(BuildContext context) {
    if (useMobileLayout(context)) {
      return PaneDisplayMode.open; // Open pane on mobile for easier navigation
    }
    return PaneDisplayMode.open; // Full side pane on desktop
  }

  /// Get navigation pane width
  static double getNavigationPaneWidth(BuildContext context) {
    if (useMobileLayout(context)) {
      return 280; // Wider pane on mobile for easier touch
    }
    return 200;
  }

  /// Get compact navigation pane width
  static double getCompactPaneWidth(BuildContext context) {
    if (useMobileLayout(context)) {
      return 64; // Larger compact width on mobile
    }
    return 48;
  }

  /// Get appropriate PaneDisplayMode for top navigation
  static PaneDisplayMode getTopPaneDisplayMode(BuildContext context) {
    // Top mode works well on both mobile and desktop for tabbed interfaces
    return PaneDisplayMode.top;
  }

  /// Get responsive body padding
  static EdgeInsets getResponsiveBodyPadding(BuildContext context) {
    if (useMobileLayout(context)) {
      return const EdgeInsets.all(12.0);
    }
    return const EdgeInsets.all(16.0);
  }
}

/// Extension for BuildContext to easily access responsive helpers
extension ResponsiveContextExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.useMobileLayout(this);
  EdgeInsets get responsivePadding =>
      ResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get responsiveBodyPadding =>
      ResponsiveHelper.getResponsiveBodyPadding(this);
  double get chartSize => ResponsiveHelper.getChartSize(this);
  int get gridCrossAxisCount => ResponsiveHelper.getGridCrossAxisCount(this);
  double get gridAspectRatio => ResponsiveHelper.getGridChildAspectRatio(this);
  PaneDisplayMode get paneDisplayMode =>
      ResponsiveHelper.getNavigationPaneDisplayMode(this);
  PaneDisplayMode get topPaneDisplayMode =>
      ResponsiveHelper.getTopPaneDisplayMode(this);
  double get paneWidth => ResponsiveHelper.getNavigationPaneWidth(this);
  double get compactPaneWidth => ResponsiveHelper.getCompactPaneWidth(this);
}
