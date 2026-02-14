import 'package:fluent_ui/fluent_ui.dart';
import '../../core/chart_customization.dart';

/// Social Media Export Themes
/// 5 visually stunning themes optimized for sharing on social platforms

/// Available social media themes
enum SocialTheme {
  cosmicNebula, // Deep space purple/blue nebula
  goldenHour, // Warm sunset golds and oranges
  minimalistWhite, // Clean Instagram-style white
  mysticAurora, // Green/purple aurora borealis
  cosmicDark, // True black OLED optimized
}

/// Extension to get social theme configuration
extension SocialThemeExtension on SocialTheme {
  /// Theme display name
  String get displayName {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return 'Cosmic Nebula';
      case SocialTheme.goldenHour:
        return 'Golden Hour';
      case SocialTheme.minimalistWhite:
        return 'Minimalist';
      case SocialTheme.mysticAurora:
        return 'Mystic Aurora';
      case SocialTheme.cosmicDark:
        return 'Cosmic Dark';
    }
  }

  /// Theme description
  String get description {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return 'Deep space purple nebula with glowing accents';
      case SocialTheme.goldenHour:
        return 'Warm sunset tones, perfect for Instagram';
      case SocialTheme.minimalistWhite:
        return 'Clean white aesthetic for professional sharing';
      case SocialTheme.mysticAurora:
        return 'Northern lights inspired ethereal green & purple';
      case SocialTheme.cosmicDark:
        return 'True black OLED optimized for dark mode shares';
    }
  }

  /// Preview/icon color for the theme
  Color get previewColor {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return const Color(0xFF9C27B0);
      case SocialTheme.goldenHour:
        return const Color(0xFFFFA726);
      case SocialTheme.minimalistWhite:
        return const Color(0xFFFFFFFF);
      case SocialTheme.mysticAurora:
        return const Color(0xFF00E676);
      case SocialTheme.cosmicDark:
        return const Color(0xFF000000);
    }
  }

  /// Whether this theme is dark mode
  bool get isDark {
    switch (this) {
      case SocialTheme.cosmicNebula:
      case SocialTheme.mysticAurora:
      case SocialTheme.cosmicDark:
        return true;
      case SocialTheme.goldenHour:
      case SocialTheme.minimalistWhite:
        return false;
    }
  }

  /// Get gradient background for the theme
  Gradient get backgroundGradient {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0033),
            Color(0xFF330066),
            Color(0xFF4A0080),
            Color(0xFF1A0033),
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        );
      case SocialTheme.goldenHour:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFE0B2),
            Color(0xFFFFCC80),
            Color(0xFFFFB74D),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );
      case SocialTheme.minimalistWhite:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFFFAFAFA)],
        );
      case SocialTheme.mysticAurora:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001a0f),
            Color(0xFF003d26),
            Color(0xFF1a0033),
            Color(0xFF001a0f),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );
      case SocialTheme.cosmicDark:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
        );
    }
  }

  /// Get chart colors adapted for social media export
  ChartColors get chartColors {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return const ChartColors(
          background: Color(0xFF1A0033),
          houseBorder: Color(0xFFE1BEE7),
          houseFill: Color(0xFF330066),
          planetText: Color(0xFFFFFFFF),
          retrogradeIndicator: Color(0xFFFF80AB),
          ascendantMarker: Color(0xFF00E5FF),
          beneficPlanet: Color(0xFF69F0AE),
          maleficPlanet: Color(0xFFFF8A80),
          neutralPlanet: Color(0xFF82B1FF),
        );
      case SocialTheme.goldenHour:
        return const ChartColors(
          background: Color(0xFFFFF8E1),
          houseBorder: Color(0xFF8D6E63),
          houseFill: Color(0xFFFFECB3),
          planetText: Color(0xFF3E2723),
          retrogradeIndicator: Color(0xFFD32F2F),
          ascendantMarker: Color(0xFFFF6F00),
          beneficPlanet: Color(0xFF2E7D32),
          maleficPlanet: Color(0xFFC62828),
          neutralPlanet: Color(0xFF1565C0),
        );
      case SocialTheme.minimalistWhite:
        return const ChartColors(
          background: Color(0xFFFFFFFF),
          houseBorder: Color(0xFF424242),
          houseFill: Color(0xFFFAFAFA),
          planetText: Color(0xFF212121),
          retrogradeIndicator: Color(0xFFD32F2F),
          ascendantMarker: Color(0xFF1976D2),
          beneficPlanet: Color(0xFF388E3C),
          maleficPlanet: Color(0xFFD32F2F),
          neutralPlanet: Color(0xFF1976D2),
        );
      case SocialTheme.mysticAurora:
        return const ChartColors(
          background: Color(0xFF001a0f),
          houseBorder: Color(0xFF00E676),
          houseFill: Color(0xFF003d26),
          planetText: Color(0xFFFFFFFF),
          retrogradeIndicator: Color(0xFFFF4081),
          ascendantMarker: Color(0xFF00E5FF),
          beneficPlanet: Color(0xFF69F0AE),
          maleficPlanet: Color(0xFFFF8A80),
          neutralPlanet: Color(0xFF82B1FF),
        );
      case SocialTheme.cosmicDark:
        return const ChartColors(
          background: Color(0xFF000000),
          houseBorder: Color(0xFFBB86FC),
          houseFill: Color(0xFF121212),
          planetText: Color(0xFFFFFFFF),
          retrogradeIndicator: Color(0xFFCF6679),
          ascendantMarker: Color(0xFF03DAC6),
          beneficPlanet: Color(0xFF81C784),
          maleficPlanet: Color(0xFFE57373),
          neutralPlanet: Color(0xFF64B5F6),
        );
    }
  }

  /// Get text colors for overlay elements
  Color get overlayTextColor {
    switch (this) {
      case SocialTheme.cosmicNebula:
      case SocialTheme.mysticAurora:
      case SocialTheme.cosmicDark:
        return Colors.white;
      case SocialTheme.goldenHour:
      case SocialTheme.minimalistWhite:
        return const Color(0xDE000000);
    }
  }

  /// Get accent color for highlights
  Color get accentColor {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return const Color(0xFF9C27B0);
      case SocialTheme.goldenHour:
        return const Color(0xFFFFA726);
      case SocialTheme.minimalistWhite:
        return const Color(0xFF2196F3);
      case SocialTheme.mysticAurora:
        return const Color(0xFF00E676);
      case SocialTheme.cosmicDark:
        return const Color(0xFFBB86FC);
    }
  }

  /// Get box decoration for cards/frames
  BoxDecoration get frameDecoration {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1BEE7).withValues(alpha: 0.3),
            width: 1,
          ),
        );
      case SocialTheme.goldenHour:
        return BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA726).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        );
      case SocialTheme.minimalistWhite:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case SocialTheme.mysticAurora:
        return BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
            width: 1,
          ),
        );
      case SocialTheme.cosmicDark:
        return BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBB86FC).withValues(alpha: 0.3),
            width: 1,
          ),
        );
    }
  }

  /// Get watermark/logo styling
  TextStyle get watermarkStyle {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return TextStyle(
          color: Colors.white.withValues(alpha: 0.54),
          fontSize: 10,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        );
      case SocialTheme.goldenHour:
        return const TextStyle(
          color: Color(0xFF8D6E63),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
        );
      case SocialTheme.minimalistWhite:
        return TextStyle(
          color: Colors.black.withValues(alpha: 0.38),
          fontSize: 10,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        );
      case SocialTheme.mysticAurora:
        return TextStyle(
          color: Colors.white.withValues(alpha: 0.54),
          fontSize: 10,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        );
      case SocialTheme.cosmicDark:
        return TextStyle(
          color: Colors.white.withValues(alpha: 0.38),
          fontSize: 10,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        );
    }
  }

  /// Get aspect line colors
  Color get aspectLineColor {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return const Color(0xFFE1BEE7).withValues(alpha: 0.4);
      case SocialTheme.goldenHour:
        return const Color(0xFF8D6E63).withValues(alpha: 0.3);
      case SocialTheme.minimalistWhite:
        return const Color(0xFFBDBDBD).withValues(alpha: 0.4);
      case SocialTheme.mysticAurora:
        return const Color(0xFF00E676).withValues(alpha: 0.3);
      case SocialTheme.cosmicDark:
        return const Color(0xFFBB86FC).withValues(alpha: 0.4);
    }
  }

  /// Get planet glow effect
  BoxShadow? get planetGlow {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return BoxShadow(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
          blurRadius: 8,
          spreadRadius: 2,
        );
      case SocialTheme.mysticAurora:
        return BoxShadow(
          color: const Color(0xFF00E676).withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 2,
        );
      default:
        return null;
    }
  }

  /// Get recommended export format
  ExportFormat get recommendedFormat {
    switch (this) {
      case SocialTheme.cosmicNebula:
      case SocialTheme.mysticAurora:
        return ExportFormat.png;
      case SocialTheme.goldenHour:
        return ExportFormat.png;
      case SocialTheme.minimalistWhite:
        return ExportFormat.png;
      case SocialTheme.cosmicDark:
        return ExportFormat.png;
    }
  }

  /// Get export dimensions (for social media optimization)
  Size get exportDimensions {
    switch (this) {
      case SocialTheme.cosmicNebula:
      case SocialTheme.goldenHour:
      case SocialTheme.minimalistWhite:
      case SocialTheme.mysticAurora:
      case SocialTheme.cosmicDark:
        return const Size(1080, 1080); // Instagram square
    }
  }

  /// Get social media hashtags for this theme
  List<String> get hashtags {
    switch (this) {
      case SocialTheme.cosmicNebula:
        return [
          '#CosmicNebula',
          '#SpaceVibes',
          '#Astrology',
          '#NatalChart',
          '#AstroNaksh',
        ];
      case SocialTheme.goldenHour:
        return [
          '#GoldenHour',
          '#SunsetVibes',
          '#Astrology',
          '#NatalChart',
          '#AstroNaksh',
        ];
      case SocialTheme.minimalistWhite:
        return [
          '#Minimalist',
          '#CleanDesign',
          '#Astrology',
          '#NatalChart',
          '#AstroNaksh',
        ];
      case SocialTheme.mysticAurora:
        return [
          '#Aurora',
          '#Mystic',
          '#Astrology',
          '#NatalChart',
          '#AstroNaksh',
        ];
      case SocialTheme.cosmicDark:
        return [
          '#DarkMode',
          '#OLED',
          '#Astrology',
          '#NatalChart',
          '#AstroNaksh',
        ];
    }
  }
}

/// Export format options
enum ExportFormat { png, jpg }

/// Social media theme manager
class SocialThemeManager {
  static final SocialThemeManager _instance = SocialThemeManager._internal();
  factory SocialThemeManager() => _instance;
  SocialThemeManager._internal();

  SocialTheme currentTheme = SocialTheme.cosmicNebula;

  /// Get all available themes
  List<SocialTheme> get allThemes => SocialTheme.values;

  /// Apply theme to chart customization for export
  ChartCustomization applyThemeToCustomization(
    ChartCustomization customization,
    SocialTheme theme,
  ) {
    final themed = ChartCustomization()
      ..chartStyle = customization.chartStyle
      ..colorScheme = ColorScheme
          .classic // We'll override colors manually
      ..showHouses = customization.showHouses
      ..showSigns = customization.showSigns
      ..showDegrees = customization.showDegrees
      ..showNakshatras = customization.showNakshatras
      ..showRetrograde = customization.showRetrograde
      ..showCombust = customization.showCombust
      ..showExaltedDebilitated = customization.showExaltedDebilitated
      ..planetSize = PlanetSize
          .large // Larger for social media
      ..houseSystem = customization.houseSystem
      ..showHouseCusps = customization.showHouseCusps
      ..showHouseNumbers = customization.showHouseNumbers
      ..showBirthDetails = customization.showBirthDetails
      ..showAyanamsa = customization.showAyanamsa
      ..showCurrentDasha = customization.showCurrentDasha;

    return themed;
  }
}
