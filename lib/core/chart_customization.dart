import 'package:flutter/material.dart';

/// Chart Customization Settings
/// Manages user preferences for chart display
class ChartCustomization {
  // Chart Style Settings
  ChartStyle chartStyle = ChartStyle.northIndian;
  ColorScheme colorScheme = ColorScheme.classic;
  bool showHouses = true;
  bool showSigns = true;
  bool showDegrees = true;
  bool showNakshatras = false;
  
  // Planet Display Settings
  bool showRetrograde = true;
  bool showCombust = true;
  bool showExaltedDebilitated = true;
  PlanetSize planetSize = PlanetSize.medium;
  
  // House System Settings
  HouseSystem houseSystem = HouseSystem.placidus;
  bool showHouseCusps = true;
  bool showHouseNumbers = true;
  
  // Chart Information Settings
  bool showBirthDetails = true;
  bool showAyanamsa = true;
  bool showCurrentDasha = true;
  
  // PDF Report Settings
  bool pdfIncludeD1 = true;
  bool pdfIncludeD9 = true;
  bool pdfIncludeDasha = true;
  bool pdfIncludeKP = true;
  bool pdfIncludeVargas = false;
  bool pdfIncludeInterpretations = false;
  
  // Dasha Settings
  int dashaYearsToShow = 20;
  bool showAntardasha = true;
  bool showPratyantardasha = false;
  
  // Transit Settings
  bool showTransits = true;
  int transitDaysToShow = 30;
  
  // Ayanamsa Settings
  String ayanamsaSystem = 'lahiri';
  
  // Notification Settings
  bool dailyTransitNotifications = true;
  TimeOfDay notificationTime = const TimeOfDay(hour: 8, minute: 0);
  
  ChartCustomization();
  
  /// Create from JSON
  factory ChartCustomization.fromJson(Map<String, dynamic> json) {
    final settings = ChartCustomization();
    
    settings.chartStyle = ChartStyle.values.firstWhere(
      (e) => e.toString() == json['chartStyle'],
      orElse: () => ChartStyle.northIndian,
    );
    
    settings.colorScheme = ColorScheme.values.firstWhere(
      (e) => e.toString() == json['colorScheme'],
      orElse: () => ColorScheme.classic,
    );
    
    settings.showHouses = json['showHouses'] ?? true;
    settings.showSigns = json['showSigns'] ?? true;
    settings.showDegrees = json['showDegrees'] ?? true;
    settings.showNakshatras = json['showNakshatras'] ?? false;
    settings.showRetrograde = json['showRetrograde'] ?? true;
    settings.showCombust = json['showCombust'] ?? true;
    settings.showExaltedDebilitated = json['showExaltedDebilitated'] ?? true;
    
    settings.planetSize = PlanetSize.values.firstWhere(
      (e) => e.toString() == json['planetSize'],
      orElse: () => PlanetSize.medium,
    );
    
    settings.houseSystem = HouseSystem.values.firstWhere(
      (e) => e.toString() == json['houseSystem'],
      orElse: () => HouseSystem.placidus,
    );
    
    settings.showHouseCusps = json['showHouseCusps'] ?? true;
    settings.showHouseNumbers = json['showHouseNumbers'] ?? true;
    settings.showBirthDetails = json['showBirthDetails'] ?? true;
    settings.showAyanamsa = json['showAyanamsa'] ?? true;
    settings.showCurrentDasha = json['showCurrentDasha'] ?? true;
    
    settings.pdfIncludeD1 = json['pdfIncludeD1'] ?? true;
    settings.pdfIncludeD9 = json['pdfIncludeD9'] ?? true;
    settings.pdfIncludeDasha = json['pdfIncludeDasha'] ?? true;
    settings.pdfIncludeKP = json['pdfIncludeKP'] ?? true;
    settings.pdfIncludeVargas = json['pdfIncludeVargas'] ?? false;
    settings.pdfIncludeInterpretations = json['pdfIncludeInterpretations'] ?? false;
    
    settings.dashaYearsToShow = json['dashaYearsToShow'] ?? 20;
    settings.showAntardasha = json['showAntardasha'] ?? true;
    settings.showPratyantardasha = json['showPratyantardasha'] ?? false;
    
    settings.showTransits = json['showTransits'] ?? true;
    settings.transitDaysToShow = json['transitDaysToShow'] ?? 30;
    
    settings.ayanamsaSystem = json['ayanamsaSystem'] ?? 'lahiri';
    
    settings.dailyTransitNotifications = json['dailyTransitNotifications'] ?? true;
    if (json['notificationTime'] != null) {
      final parts = json['notificationTime'].split(':');
      settings.notificationTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    return settings;
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'chartStyle': chartStyle.toString(),
      'colorScheme': colorScheme.toString(),
      'showHouses': showHouses,
      'showSigns': showSigns,
      'showDegrees': showDegrees,
      'showNakshatras': showNakshatras,
      'showRetrograde': showRetrograde,
      'showCombust': showCombust,
      'showExaltedDebilitated': showExaltedDebilitated,
      'planetSize': planetSize.toString(),
      'houseSystem': houseSystem.toString(),
      'showHouseCusps': showHouseCusps,
      'showHouseNumbers': showHouseNumbers,
      'showBirthDetails': showBirthDetails,
      'showAyanamsa': showAyanamsa,
      'showCurrentDasha': showCurrentDasha,
      'pdfIncludeD1': pdfIncludeD1,
      'pdfIncludeD9': pdfIncludeD9,
      'pdfIncludeDasha': pdfIncludeDasha,
      'pdfIncludeKP': pdfIncludeKP,
      'pdfIncludeVargas': pdfIncludeVargas,
      'pdfIncludeInterpretations': pdfIncludeInterpretations,
      'dashaYearsToShow': dashaYearsToShow,
      'showAntardasha': showAntardasha,
      'showPratyantardasha': showPratyantardasha,
      'showTransits': showTransits,
      'transitDaysToShow': transitDaysToShow,
      'ayanamsaSystem': ayanamsaSystem,
      'dailyTransitNotifications': dailyTransitNotifications,
      'notificationTime': '${notificationTime.hour}:${notificationTime.minute}',
    };
  }
  
  /// Reset to defaults
  void resetToDefaults() {
    chartStyle = ChartStyle.northIndian;
    colorScheme = ColorScheme.classic;
    showHouses = true;
    showSigns = true;
    showDegrees = true;
    showNakshatras = false;
    showRetrograde = true;
    showCombust = true;
    showExaltedDebilitated = true;
    planetSize = PlanetSize.medium;
    houseSystem = HouseSystem.placidus;
    showHouseCusps = true;
    showHouseNumbers = true;
    showBirthDetails = true;
    showAyanamsa = true;
    showCurrentDasha = true;
    pdfIncludeD1 = true;
    pdfIncludeD9 = true;
    pdfIncludeDasha = true;
    pdfIncludeKP = true;
    pdfIncludeVargas = false;
    pdfIncludeInterpretations = false;
    dashaYearsToShow = 20;
    showAntardasha = true;
    showPratyantardasha = false;
    showTransits = true;
    transitDaysToShow = 30;
    ayanamsaSystem = 'lahiri';
    dailyTransitNotifications = true;
    notificationTime = const TimeOfDay(hour: 8, minute: 0);
  }
}

/// Chart Style Options
enum ChartStyle {
  northIndian,
  southIndian,
  eastIndian,
  western,
}

/// Color Scheme Options
enum ColorScheme {
  classic,
  modern,
  vedic,
  print,
  night,
}

/// Planet Size Options
enum PlanetSize {
  small,
  medium,
  large,
}

/// House System Options
enum HouseSystem {
  placidus,
  equal,
  wholeSign,
  sripathi,
  kp,
  campanus,
  koch,
}

/// Extension to get color scheme colors
extension ColorSchemeColors on ColorScheme {
  ChartColors get colors {
    switch (this) {
      case ColorScheme.classic:
        return ChartColors(
          background: const Color(0xFFFAFAFA),
          houseBorder: const Color(0xFF333333),
          houseFill: const Color(0xFFFFFFFF),
          planetText: const Color(0xFF000000),
          retrogradeIndicator: const Color(0xFFFF0000),
          ascendantMarker: const Color(0xFFFFD700),
          beneficPlanet: const Color(0xFF006400),
          maleficPlanet: const Color(0xFF8B0000),
          neutralPlanet: const Color(0xFF000080),
        );
      case ColorScheme.modern:
        return ChartColors(
          background: const Color(0xFFF5F5F5),
          houseBorder: const Color(0xFF6200EE),
          houseFill: const Color(0xFFFFFFFF),
          planetText: const Color(0xFF333333),
          retrogradeIndicator: const Color(0xFFB00020),
          ascendantMarker: const Color(0xFF03DAC6),
          beneficPlanet: const Color(0xFF4CAF50),
          maleficPlanet: const Color(0xFFE53935),
          neutralPlanet: const Color(0xFF2196F3),
        );
      case ColorScheme.vedic:
        return ChartColors(
          background: const Color(0xFFFFF8E1),
          houseBorder: const Color(0xFF8D6E63),
          houseFill: const Color(0xFFFFFDE7),
          planetText: const Color(0xFF3E2723),
          retrogradeIndicator: const Color(0xFFD32F2F),
          ascendantMarker: const Color(0xFFFFB300),
          beneficPlanet: const Color(0xFF2E7D32),
          maleficPlanet: const Color(0xFFC62828),
          neutralPlanet: const Color(0xFF1565C0),
        );
      case ColorScheme.print:
        return ChartColors(
          background: const Color(0xFFFFFFFF),
          houseBorder: const Color(0xFF000000),
          houseFill: const Color(0xFFFFFFFF),
          planetText: const Color(0xFF000000),
          retrogradeIndicator: const Color(0xFF000000),
          ascendantMarker: const Color(0xFF000000),
          beneficPlanet: const Color(0xFF000000),
          maleficPlanet: const Color(0xFF000000),
          neutralPlanet: const Color(0xFF000000),
        );
      case ColorScheme.night:
        return ChartColors(
          background: const Color(0xFF121212),
          houseBorder: const Color(0xFFBB86FC),
          houseFill: const Color(0xFF1E1E1E),
          planetText: const Color(0xFFE0E0E0),
          retrogradeIndicator: const Color(0xFFCF6679),
          ascendantMarker: const Color(0xFF03DAC6),
          beneficPlanet: const Color(0xFF81C784),
          maleficPlanet: const Color(0xFFE57373),
          neutralPlanet: const Color(0xFF64B5F6),
        );
    }
  }
}

/// Chart Colors Configuration
class ChartColors {
  final Color background;
  final Color houseBorder;
  final Color houseFill;
  final Color planetText;
  final Color retrogradeIndicator;
  final Color ascendantMarker;
  final Color beneficPlanet;
  final Color maleficPlanet;
  final Color neutralPlanet;

  const ChartColors({
    required this.background,
    required this.houseBorder,
    required this.houseFill,
    required this.planetText,
    required this.retrogradeIndicator,
    required this.ascendantMarker,
    required this.beneficPlanet,
    required this.maleficPlanet,
    required this.neutralPlanet,
  });
}

/// Chart Presets
class ChartPresets {
  /// Beginner-friendly preset
  static ChartCustomization get beginner => ChartCustomization()
    ..chartStyle = ChartStyle.northIndian
    ..colorScheme = ColorScheme.modern
    ..showHouses = true
    ..showSigns = true
    ..showDegrees = false
    ..showNakshatras = false
    ..showRetrograde = true
    ..showCombust = false
    ..showExaltedDebilitated = false
    ..planetSize = PlanetSize.large
    ..houseSystem = HouseSystem.equal
    ..showHouseNumbers = true
    ..pdfIncludeInterpretations = true;

  /// Professional preset
  static ChartCustomization get professional => ChartCustomization()
    ..chartStyle = ChartStyle.northIndian
    ..colorScheme = ColorScheme.vedic
    ..showHouses = true
    ..showSigns = true
    ..showDegrees = true
    ..showNakshatras = true
    ..showRetrograde = true
    ..showCombust = true
    ..showExaltedDebilitated = true
    ..planetSize = PlanetSize.medium
    ..houseSystem = HouseSystem.placidus
    ..showHouseCusps = true
    ..showHouseNumbers = true
    ..pdfIncludeD1 = true
    ..pdfIncludeD9 = true
    ..pdfIncludeDasha = true
    ..pdfIncludeKP = true
    ..pdfIncludeVargas = true
    ..pdfIncludeInterpretations = false
    ..dashaYearsToShow = 30
    ..showAntardasha = true
    ..showPratyantardasha = true;

  /// Minimal preset
  static ChartCustomization get minimal => ChartCustomization()
    ..chartStyle = ChartStyle.southIndian
    ..colorScheme = ColorScheme.print
    ..showHouses = true
    ..showSigns = false
    ..showDegrees = false
    ..showNakshatras = false
    ..showRetrograde = false
    ..showCombust = false
    ..showExaltedDebilitated = false
    ..planetSize = PlanetSize.small
    ..houseSystem = HouseSystem.equal
    ..showHouseCusps = false
    ..showHouseNumbers = true
    ..pdfIncludeD1 = true
    ..pdfIncludeD9 = false
    ..pdfIncludeDasha = false
    ..pdfIncludeKP = false
    ..pdfIncludeVargas = false;

  /// Print-friendly preset
  static ChartCustomization get printFriendly => ChartCustomization()
    ..chartStyle = ChartStyle.northIndian
    ..colorScheme = ColorScheme.print
    ..showHouses = true
    ..showSigns = true
    ..showDegrees = true
    ..showNakshatras = false
    ..showRetrograde = true
    ..showCombust = false
    ..showExaltedDebilitated = false
    ..planetSize = PlanetSize.medium
    ..houseSystem = HouseSystem.placidus
    ..showHouseCusps = true
    ..showHouseNumbers = true
    ..pdfIncludeD1 = true
    ..pdfIncludeD9 = true
    ..pdfIncludeDasha = true
    ..pdfIncludeKP = true
    ..pdfIncludeVargas = false
    ..pdfIncludeInterpretations = true;
}

/// Settings Manager
class SettingsManager {
  static ChartCustomization _currentSettings = ChartCustomization();
  
  static ChartCustomization get current => _currentSettings;
  
  static void updateSettings(ChartCustomization settings) {
    _currentSettings = settings;
  }
  
  static void applyPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'beginner':
        _currentSettings = ChartPresets.beginner;
        break;
      case 'professional':
        _currentSettings = ChartPresets.professional;
        break;
      case 'minimal':
        _currentSettings = ChartPresets.minimal;
        break;
      case 'printfriendly':
      case 'print':
        _currentSettings = ChartPresets.printFriendly;
        break;
      default:
        _currentSettings = ChartCustomization();
    }
  }
}
