import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/analysis.dart';
import 'package:jyotish/core.dart';

/// Chart Customization Settings
/// Manages user preferences for chart display
class ChartCustomization {
  ChartCustomization();

  /// Create from JSON
  ///
  /// Every field is read defensively: a single malformed entry used to throw a
  /// [TypeError] that the caller swallowed, silently resetting the whole
  /// configuration to defaults and letting the next save overwrite the user's
  /// real settings.
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

    settings.showHouses = _readBool(json['showHouses'], fallback: true);
    settings.showSigns = _readBool(json['showSigns'], fallback: true);
    settings.showDegrees = _readBool(json['showDegrees'], fallback: true);
    settings.showNakshatras = _readBool(
      json['showNakshatras'],
      fallback: false,
    );
    settings.showRetrograde = _readBool(json['showRetrograde'], fallback: true);
    settings.showCombust = _readBool(json['showCombust'], fallback: true);
    settings.showExaltedDebilitated = _readBool(
      json['showExaltedDebilitated'],
      fallback: true,
    );

    settings.planetSize = PlanetSize.values.firstWhere(
      (e) => e.toString() == json['planetSize'],
      orElse: () => PlanetSize.medium,
    );

    settings.houseSystem = HouseSystem.values.firstWhere(
      (e) => e.toString() == json['houseSystem'],
      orElse: () => HouseSystem.placidus,
    );

    settings.showHouseCusps = _readBool(json['showHouseCusps'], fallback: true);
    settings.showHouseNumbers = _readBool(
      json['showHouseNumbers'],
      fallback: true,
    );
    settings.showBirthDetails = _readBool(
      json['showBirthDetails'],
      fallback: true,
    );
    settings.showAyanamsa = _readBool(json['showAyanamsa'], fallback: true);
    settings.showCurrentDasha = _readBool(
      json['showCurrentDasha'],
      fallback: true,
    );

    settings.pdfIncludeD1 = _readBool(json['pdfIncludeD1'], fallback: true);
    settings.pdfIncludeD9 = _readBool(json['pdfIncludeD9'], fallback: true);
    settings.pdfIncludeDasha = _readBool(
      json['pdfIncludeDasha'],
      fallback: true,
    );
    settings.pdfIncludeKP = _readBool(json['pdfIncludeKP'], fallback: true);
    settings.pdfIncludeVargas = _readBool(
      json['pdfIncludeVargas'],
      fallback: false,
    );
    settings.pdfIncludeInterpretations = _readBool(
      json['pdfIncludeInterpretations'],
      fallback: false,
    );

    settings.dashaYearsToShow = _readInt(
      json['dashaYearsToShow'],
      fallback: 20,
      min: minDashaYears,
      max: maxDashaYears,
    );
    settings.showAntardasha = _readBool(json['showAntardasha'], fallback: true);
    settings.showPratyantardasha = _readBool(
      json['showPratyantardasha'],
      fallback: false,
    );

    settings.showTransits = _readBool(json['showTransits'], fallback: true);
    settings.transitDaysToShow = _readInt(
      json['transitDaysToShow'],
      fallback: 30,
      min: minTransitDays,
      max: maxTransitDays,
    );

    settings.ayanamsaSystem = _readString(
      json['ayanamsaSystem'],
      fallback: 'newKP',
    );

    settings.useTrueNode = _readBool(json['useTrueNode'], fallback: false);
    settings.useTopocentric = _readBool(
      json['useTopocentric'],
      fallback: false,
    );
    settings.calculateSpeed = _readBool(json['calculateSpeed'], fallback: true);
    settings.includeSpecialAspects = _readBool(
      json['includeSpecialAspects'],
      fallback: true,
    );
    settings.includeNodesInAspects = _readBool(
      json['includeNodesInAspects'],
      fallback: true,
    );
    settings.includeOuterPlanets = _readBool(
      json['includeOuterPlanets'],
      fallback: false,
    );

    settings.horaMethod = HoraMethod.values.firstWhere(
      (e) => e.toString() == json['horaMethod'],
      orElse: () => HoraMethod.parashara,
    );
    settings.drekkanaMethod = DrekkanaMethod.values.firstWhere(
      (e) => e.toString() == json['drekkanaMethod'],
      orElse: () => DrekkanaMethod.parashara,
    );
    settings.navamshaMethod = NavamshaMethod.values.firstWhere(
      (e) => e.toString() == json['navamshaMethod'],
      orElse: () => NavamshaMethod.parashara,
    );
    settings.dashamshaMethod = DashamshaMethod.values.firstWhere(
      (e) => e.toString() == json['dashamshaMethod'],
      orElse: () => DashamshaMethod.parashara,
    );

    // Brand Identity
    settings.brandOrgName = _readString(
      json['brandOrgName'],
      fallback: 'ASTRONAKSH',
    );
    settings.brandOrgTagline = _readString(
      json['brandOrgTagline'],
      fallback: 'Vedic Insights',
    );
    settings.brandLogoPath = _readString(json['brandLogoPath'], fallback: '');
    settings.brandContactInfo = _readString(
      json['brandContactInfo'],
      fallback: '',
    );
    settings.brandPrimaryColorHex = _readString(
      json['brandPrimaryColorHex'],
      fallback: '#1A237E',
    );
    settings.brandAccentColorHex = _readString(
      json['brandAccentColorHex'],
      fallback: '#B8860B',
    );
    final margins = _readString(json['pdfPageMargins'], fallback: 'medium');
    settings.pdfPageMargins = pdfMarginOptions.contains(margins)
        ? margins
        : 'medium';
    settings.pdfIncludeCover = json['pdfIncludeCover'] ?? true;

    // WebDAV Settings
    settings.webdavUrl = _readString(json['webdavUrl'], fallback: '');
    settings.webdavUsername = _readString(json['webdavUsername'], fallback: '');
    settings.webdavPassword = _decodePassword(
      json['webdavPassword']?.toString() ?? '',
    );

    return settings;
  }

  /// Inclusive bounds for the numeric settings that back a [Slider]. A value
  /// outside the range makes the slider assert on the next build.
  static const int minDashaYears = 5;
  static const int maxDashaYears = 50;
  static const int minTransitDays = 7;
  static const int maxTransitDays = 90;
  static const List<String> pdfMarginOptions = ['small', 'medium', 'large'];

  static bool _readBool(Object? raw, {required bool fallback}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      if (raw.toLowerCase() == 'true') return true;
      if (raw.toLowerCase() == 'false') return false;
    }
    return fallback;
  }

  static String _readString(Object? raw, {required String fallback}) {
    return raw is String ? raw : fallback;
  }

  static int _readInt(
    Object? raw, {
    required int fallback,
    int? min,
    int? max,
  }) {
    var value = raw is int
        ? raw
        : raw is num
        ? raw.toInt()
        : raw is String
        ? int.tryParse(raw) ?? fallback
        : fallback;
    if (min != null && value < min) value = min;
    if (max != null && value > max) value = max;
    return value;
  }

  static String _encodePassword(String raw) {
    if (raw.isEmpty) return '';
    const xorKey = 0x5A;
    final bytes = utf8.encode(raw);
    final xored = bytes.map((b) => b ^ xorKey).toList();
    return 'enc:${base64Encode(xored)}';
  }

  static String _decodePassword(String stored) {
    if (stored.isEmpty) return '';
    if (!stored.startsWith('enc:')) {
      return stored; // legacy plaintext compatibility
    }
    try {
      final b64 = stored.substring(4);
      final bytes = base64Decode(b64);
      const xorKey = 0x5A;
      final xored = bytes.map((b) => b ^ xorKey).toList();
      return utf8.decode(xored);
    } catch (_) {
      return stored;
    }
  }

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
  String ayanamsaSystem = 'newKP';

  // Node Type (Rahu/Ketu) - Mean vs True Node
  bool useTrueNode = false;

  // Position Calculation
  bool useTopocentric = false;
  bool calculateSpeed = true;

  // Aspect Calculation
  bool includeSpecialAspects = true;
  bool includeNodesInAspects = true;

  // Outer Planets
  bool includeOuterPlanets = false;

  // Notification Settings
  // Using hours and minutes instead of TimeOfDay to remove Material dependency

  // Varga Settings
  HoraMethod horaMethod = HoraMethod.parashara;
  DrekkanaMethod drekkanaMethod = DrekkanaMethod.parashara;
  NavamshaMethod navamshaMethod = NavamshaMethod.parashara;
  DashamshaMethod dashamshaMethod = DashamshaMethod.parashara;

  // Brand Identity Settings
  String brandOrgName = 'ASTRONAKSH';
  String brandOrgTagline = 'Vedic Insights';
  String brandLogoPath = '';
  String brandContactInfo = '';
  String brandPrimaryColorHex = '#1A237E';
  String brandAccentColorHex = '#B8860B';
  String pdfPageMargins = 'medium'; // 'small', 'medium', 'large'
  bool pdfIncludeCover = true;

  // WebDAV Settings
  String webdavUrl = '';
  String webdavUsername = '';
  String webdavPassword = '';

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
      'useTrueNode': useTrueNode,
      'useTopocentric': useTopocentric,
      'calculateSpeed': calculateSpeed,
      'includeSpecialAspects': includeSpecialAspects,
      'includeNodesInAspects': includeNodesInAspects,
      'includeOuterPlanets': includeOuterPlanets,
      'horaMethod': horaMethod.toString(),
      'drekkanaMethod': drekkanaMethod.toString(),
      'navamshaMethod': navamshaMethod.toString(),
      'dashamshaMethod': dashamshaMethod.toString(),
      'brandOrgName': brandOrgName,
      'brandOrgTagline': brandOrgTagline,
      'brandLogoPath': brandLogoPath,
      'brandContactInfo': brandContactInfo,
      'brandPrimaryColorHex': brandPrimaryColorHex,
      'brandAccentColorHex': brandAccentColorHex,
      'pdfPageMargins': pdfPageMargins,
      'pdfIncludeCover': pdfIncludeCover,
      'webdavUrl': webdavUrl,
      'webdavUsername': webdavUsername,
      'webdavPassword': _encodePassword(webdavPassword),
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
    ayanamsaSystem = 'newKP';
    useTrueNode = false;
    useTopocentric = false;
    calculateSpeed = true;
    includeSpecialAspects = true;
    includeNodesInAspects = true;
    includeOuterPlanets = false;
    horaMethod = HoraMethod.parashara;
    drekkanaMethod = DrekkanaMethod.parashara;
    navamshaMethod = NavamshaMethod.parashara;
    dashamshaMethod = DashamshaMethod.parashara;
    brandOrgName = 'ASTRONAKSH';
    brandOrgTagline = 'Vedic Insights';
    brandLogoPath = '';
    brandContactInfo = '';
    brandPrimaryColorHex = '#1A237E';
    brandAccentColorHex = '#B8860B';
    pdfPageMargins = 'medium';
    pdfIncludeCover = true;
    webdavUrl = '';
    webdavUsername = '';
    webdavPassword = '';
  }

  ChartCustomization copyWith({
    ChartStyle? chartStyle,
    ColorScheme? colorScheme,
    bool? showHouses,
    bool? showSigns,
    bool? showDegrees,
    bool? showNakshatras,
    bool? showRetrograde,
    bool? showCombust,
    bool? showExaltedDebilitated,
    PlanetSize? planetSize,
    HouseSystem? houseSystem,
    bool? showHouseCusps,
    bool? showHouseNumbers,
    bool? showBirthDetails,
    bool? showAyanamsa,
    bool? showCurrentDasha,
    bool? pdfIncludeD1,
    bool? pdfIncludeD9,
    bool? pdfIncludeDasha,
    bool? pdfIncludeKP,
    bool? pdfIncludeVargas,
    bool? pdfIncludeInterpretations,
    int? dashaYearsToShow,
    bool? showAntardasha,
    bool? showPratyantardasha,
    bool? showTransits,
    int? transitDaysToShow,
    String? ayanamsaSystem,
    bool? useTrueNode,
    bool? useTopocentric,
    bool? calculateSpeed,
    bool? includeSpecialAspects,
    bool? includeNodesInAspects,
    bool? includeOuterPlanets,
    HoraMethod? horaMethod,
    DrekkanaMethod? drekkanaMethod,
    NavamshaMethod? navamshaMethod,
    DashamshaMethod? dashamshaMethod,
    String? brandOrgName,
    String? brandOrgTagline,
    String? brandLogoPath,
    String? brandContactInfo,
    String? brandPrimaryColorHex,
    String? brandAccentColorHex,
    String? pdfPageMargins,
    bool? pdfIncludeCover,
    String? webdavUrl,
    String? webdavUsername,
    String? webdavPassword,
  }) {
    final result = ChartCustomization();
    result.chartStyle = chartStyle ?? this.chartStyle;
    result.colorScheme = colorScheme ?? this.colorScheme;
    result.showHouses = showHouses ?? this.showHouses;
    result.showSigns = showSigns ?? this.showSigns;
    result.showDegrees = showDegrees ?? this.showDegrees;
    result.showNakshatras = showNakshatras ?? this.showNakshatras;
    result.showRetrograde = showRetrograde ?? this.showRetrograde;
    result.showCombust = showCombust ?? this.showCombust;
    result.showExaltedDebilitated =
        showExaltedDebilitated ?? this.showExaltedDebilitated;
    result.planetSize = planetSize ?? this.planetSize;
    result.houseSystem = houseSystem ?? this.houseSystem;
    result.showHouseCusps = showHouseCusps ?? this.showHouseCusps;
    result.showHouseNumbers = showHouseNumbers ?? this.showHouseNumbers;
    result.showBirthDetails = showBirthDetails ?? this.showBirthDetails;
    result.showAyanamsa = showAyanamsa ?? this.showAyanamsa;
    result.showCurrentDasha = showCurrentDasha ?? this.showCurrentDasha;
    result.pdfIncludeD1 = pdfIncludeD1 ?? this.pdfIncludeD1;
    result.pdfIncludeD9 = pdfIncludeD9 ?? this.pdfIncludeD9;
    result.pdfIncludeDasha = pdfIncludeDasha ?? this.pdfIncludeDasha;
    result.pdfIncludeKP = pdfIncludeKP ?? this.pdfIncludeKP;
    result.pdfIncludeVargas = pdfIncludeVargas ?? this.pdfIncludeVargas;
    result.pdfIncludeInterpretations =
        pdfIncludeInterpretations ?? this.pdfIncludeInterpretations;
    result.dashaYearsToShow = dashaYearsToShow ?? this.dashaYearsToShow;
    result.showAntardasha = showAntardasha ?? this.showAntardasha;
    result.showPratyantardasha =
        showPratyantardasha ?? this.showPratyantardasha;
    result.showTransits = showTransits ?? this.showTransits;
    result.transitDaysToShow = transitDaysToShow ?? this.transitDaysToShow;
    result.ayanamsaSystem = ayanamsaSystem ?? this.ayanamsaSystem;
    result.useTrueNode = useTrueNode ?? this.useTrueNode;
    result.useTopocentric = useTopocentric ?? this.useTopocentric;
    result.calculateSpeed = calculateSpeed ?? this.calculateSpeed;
    result.includeSpecialAspects =
        includeSpecialAspects ?? this.includeSpecialAspects;
    result.includeNodesInAspects =
        includeNodesInAspects ?? this.includeNodesInAspects;
    result.includeOuterPlanets =
        includeOuterPlanets ?? this.includeOuterPlanets;
    result.horaMethod = horaMethod ?? this.horaMethod;
    result.drekkanaMethod = drekkanaMethod ?? this.drekkanaMethod;
    result.navamshaMethod = navamshaMethod ?? this.navamshaMethod;
    result.dashamshaMethod = dashamshaMethod ?? this.dashamshaMethod;
    result.brandOrgName = brandOrgName ?? this.brandOrgName;
    result.brandOrgTagline = brandOrgTagline ?? this.brandOrgTagline;
    result.brandLogoPath = brandLogoPath ?? this.brandLogoPath;
    result.brandContactInfo = brandContactInfo ?? this.brandContactInfo;
    result.brandPrimaryColorHex =
        brandPrimaryColorHex ?? this.brandPrimaryColorHex;
    result.brandAccentColorHex =
        brandAccentColorHex ?? this.brandAccentColorHex;
    result.pdfPageMargins = pdfPageMargins ?? this.pdfPageMargins;
    result.pdfIncludeCover = pdfIncludeCover ?? this.pdfIncludeCover;
    result.webdavUrl = webdavUrl ?? this.webdavUrl;
    result.webdavUsername = webdavUsername ?? this.webdavUsername;
    result.webdavPassword = webdavPassword ?? this.webdavPassword;
    return result;
  }
}

/// Chart Style Options
enum ChartStyle { northIndian, southIndian, eastIndian, western }

/// Color Scheme Options
enum ColorScheme { classic, modern, vedic, print, night, oled }

/// Planet Size Options
enum PlanetSize { small, medium, large }

/// House System Options
enum HouseSystem { placidus, equal, wholeSign, sripathi, kp, campanus, koch }

/// Extension to get color scheme colors
extension ColorSchemeColors on ColorScheme {
  ChartColors get colors {
    switch (this) {
      case ColorScheme.classic:
        return const ChartColors(
          background: Color(0xFFFAFAFA),
          houseBorder: Color(0xFF333333),
          houseFill: Color(0xFFFFFFFF),
          planetText: Color(0xFF000000),
          retrogradeIndicator: Color(0xFFFF0000),
          ascendantMarker: Color(0xFFFFD700),
          beneficPlanet: Color(0xFF006400),
          maleficPlanet: Color(0xFF8B0000),
          neutralPlanet: Color(0xFF000080),
        );
      case ColorScheme.modern:
        return const ChartColors(
          background: Color(0xFFF5F5F5),
          houseBorder: Color(0xFF6200EE),
          houseFill: Color(0xFFFFFFFF),
          planetText: Color(0xFF333333),
          retrogradeIndicator: Color(0xFFB00020),
          ascendantMarker: Color(0xFF03DAC6),
          beneficPlanet: Color(0xFF4CAF50),
          maleficPlanet: Color(0xFFE53935),
          neutralPlanet: Color(0xFF2196F3),
        );
      case ColorScheme.vedic:
        return const ChartColors(
          background: Color(0xFFFFF8E1),
          houseBorder: Color(0xFF8D6E63),
          houseFill: Color(0xFFFFFDE7),
          planetText: Color(0xFF3E2723),
          retrogradeIndicator: Color(0xFFD32F2F),
          ascendantMarker: Color(0xFFFFB300),
          beneficPlanet: Color(0xFF2E7D32),
          maleficPlanet: Color(0xFFC62828),
          neutralPlanet: Color(0xFF1565C0),
        );
      case ColorScheme.print:
        return const ChartColors(
          background: Color(0xFFFFFFFF),
          houseBorder: Color(0xFF000000),
          houseFill: Color(0xFFFFFFFF),
          planetText: Color(0xFF000000),
          retrogradeIndicator: Color(0xFF000000),
          ascendantMarker: Color(0xFF000000),
          beneficPlanet: Color(0xFF000000),
          maleficPlanet: Color(0xFF000000),
          neutralPlanet: Color(0xFF000000),
        );
      case ColorScheme.night:
        return const ChartColors(
          background: Color(0xFF121212),
          houseBorder: Color(0xFFBB86FC),
          houseFill: Color(0xFF1E1E1E),
          planetText: Color(0xFFE0E0E0),
          retrogradeIndicator: Color(0xFFCF6679),
          ascendantMarker: Color(0xFF03DAC6),
          beneficPlanet: Color(0xFF81C784),
          maleficPlanet: Color(0xFFE57373),
          neutralPlanet: Color(0xFF64B5F6),
        );
      case ColorScheme.oled:
        return const ChartColors(
          background: Color(0xFF000000),
          houseBorder: Color(0xFFBB86FC),
          houseFill: Color(0xFF0D0D0D),
          planetText: Color(0xFFFFFFFF),
          retrogradeIndicator: Color(0xFFFF4081),
          ascendantMarker: Color(0xFF00E5FF),
          beneficPlanet: Color(0xFF00E676),
          maleficPlanet: Color(0xFFFF5252),
          neutralPlanet: Color(0xFF448AFF),
        );
    }
  }
}

/// Chart Colors Configuration
class ChartColors {
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
  final Color background;
  final Color houseBorder;
  final Color houseFill;
  final Color planetText;
  final Color retrogradeIndicator;
  final Color ascendantMarker;
  final Color beneficPlanet;
  final Color maleficPlanet;
  final Color neutralPlanet;
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
