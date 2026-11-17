import '../models/planet.dart';
import '../models/vedic_chart.dart';

/// Available chart rendering styles.
enum ChartStyle {
  /// Clockwise grid-based chart where zodiac signs are fixed and house numbers vary.
  southIndian,

  /// Counter-clockwise diamond-based chart where houses are fixed and sign numbers vary.
  northIndian,
}

/// Helper extension on [VedicChart] to provide pure-Dart SVG rendering capabilities.
extension VedicChartRenderer on VedicChart {
  /// Generates a clean, modern, and beautifully styled SVG representation of the chart.
  ///
  /// Supports [ChartStyle.southIndian] and [ChartStyle.northIndian].
  String toSVG({
    ChartStyle style = ChartStyle.southIndian,
    double width = 500,
    double height = 500,
    bool darkTheme = false,
  }) {
    final strokeColor = darkTheme ? '#ffffff' : '#1e293b';
    final textColor = darkTheme ? '#f1f5f9' : '#0f172a';
    final labelColor = darkTheme ? '#94a3b8' : '#64748b';
    final cardBg = darkTheme ? '#0f172a' : '#ffffff';
    const ascColor = '#f59e0b'; // Amber Accent

    final buffer = StringBuffer();
    buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" width="$width" height="$height">',
    );

    // Background card
    buffer.write(
      '<rect width="500" height="500" rx="16" fill="$cardBg" stroke="$strokeColor" stroke-width="2"/>',
    );

    if (style == ChartStyle.southIndian) {
      _drawSouthIndianSVG(buffer, strokeColor, textColor, labelColor, ascColor);
    } else {
      _drawNorthIndianSVG(buffer, strokeColor, textColor, labelColor, ascColor);
    }

    buffer.write('</svg>');
    return buffer.toString();
  }

  void _drawSouthIndianSVG(
    StringBuffer buffer,
    String strokeColor,
    String textColor,
    String labelColor,
    String ascColor,
  ) {
    // 4x4 Grid paths
    const step = 500.0 / 4;
    for (var i = 1; i < 4; i++) {
      final pos = i * step;
      buffer.write(
        '<line x1="$pos" y1="0" x2="$pos" y2="500" stroke="$strokeColor" stroke-width="1.5" stroke-dasharray="1 1"/>',
      );
      buffer.write(
        '<line x1="0" y1="$pos" x2="500" y2="$pos" stroke="$strokeColor" stroke-width="1.5" stroke-dasharray="1 1"/>',
      );
    }

    // Outer boundary borders
    buffer.write(
      '<rect x="0" y="0" width="500" height="500" fill="none" stroke="$strokeColor" stroke-width="3"/>',
    );
    // Inner center box (covering 2x2 blocks)
    buffer.write(
      '<rect x="$step" y="$step" width="${step * 2}" height="${step * 2}" fill="none" stroke="$strokeColor" stroke-width="3"/>',
    );

    // South Indian Sign Coordinates (standard clockwise layout)
    const gridCoords = [
      (0, 1), // Aries (0)
      (0, 2), // Taurus (1)
      (0, 3), // Gemini (2)
      (1, 3), // Cancer (3)
      (2, 3), // Leo (4)
      (3, 3), // Virgo (5)
      (3, 2), // Libra (6)
      (3, 1), // Scorpio (7)
      (3, 0), // Sagittarius (8)
      (2, 0), // Capricorn (9)
      (1, 0), // Aquarius (10)
      (0, 0), // Pisces (11)
    ];

    const signAbbr = [
      'Ar',
      'Ta',
      'Ge',
      'Ca',
      'Le',
      'Vi',
      'Li',
      'Sc',
      'Sa',
      'Cp',
      'Aq',
      'Pi',
    ];

    // Map each planet to its zodiac sign
    final planetsInSign = List.generate(12, (_) => <String>[]);
    for (final info in planets.values) {
      final signIndex = (info.longitude / 30).floor() % 12;
      planetsInSign[signIndex].add(_getPlanetAbbr(info.planet));
    }
    // Add Rahu/Ketu
    final rahuSign = (rahu.longitude / 30).floor() % 12;
    planetsInSign[rahuSign].add('Ra');
    final ketuSign = (ketu.longitude / 30).floor() % 12;
    planetsInSign[ketuSign].add('Ke');

    // Check Ascendant
    final ascSign = (ascendant / 30).floor() % 12;

    for (var rashiIdx = 0; rashiIdx < 12; rashiIdx++) {
      final coord = gridCoords[rashiIdx];
      final x = coord.$2 * step;
      final y = coord.$1 * step;

      // Draw sign name label
      buffer.write(
        '<text x="${x + 8}" y="${y + 20}" font-family="system-ui, sans-serif" font-size="12" font-weight="bold" fill="$labelColor">${signAbbr[rashiIdx]}</text>',
      );

      // Draw Lagna marker (ASC)
      if (rashiIdx == ascSign) {
        buffer.write(
          '<text x="${x + step - 32}" y="${y + 20}" font-family="system-ui, sans-serif" font-size="11" font-weight="bold" fill="$ascColor">ASC</text>',
        );
      }

      // Draw planets list inside the box
      final plList = planetsInSign[rashiIdx];
      var py = y + 42.0;
      for (var pIdx = 0; pIdx < plList.length; pIdx += 2) {
        final pair = plList
            .sublist(pIdx, pIdx + 2 > plList.length ? plList.length : pIdx + 2)
            .join(' ');
        buffer.write(
          '<text x="${x + 12}" y="$py" font-family="system-ui, sans-serif" font-size="14" font-weight="bold" fill="$textColor">$pair</text>',
        );
        py += 18.0;
      }
    }

    // Write chart metadata in the center box
    const centerX = 250.0;
    buffer.write(
      '<text x="$centerX" y="220" text-anchor="middle" font-family="system-ui, sans-serif" font-size="16" font-weight="bold" fill="$textColor">RASHI CHART</text>',
    );
    buffer.write(
      '<text x="$centerX" y="248" text-anchor="middle" font-family="system-ui, sans-serif" font-size="11" fill="$labelColor">Lagna: ${houses.ascendantSign}</text>',
    );
    buffer.write(
      '<text x="$centerX" y="270" text-anchor="middle" font-family="system-ui, sans-serif" font-size="11" fill="$labelColor">${dateTime.toLocal().toString().substring(0, 16)}</text>',
    );
  }

  void _drawNorthIndianSVG(
    StringBuffer buffer,
    String strokeColor,
    String textColor,
    String labelColor,
    String ascColor,
  ) {
    // Outer boundary box
    buffer.write(
      '<rect x="0" y="0" width="500" height="500" fill="none" stroke="$strokeColor" stroke-width="3"/>',
    );

    // Drawing diagonals
    buffer.write(
      '<line x1="0" y1="0" x2="500" y2="500" stroke="$strokeColor" stroke-width="2"/>',
    );
    buffer.write(
      '<line x1="500" y1="0" x2="0" y2="500" stroke="$strokeColor" stroke-width="2"/>',
    );

    // Drawing Inner Diamond
    buffer.write(
      '<polygon points="250,0 500,250 250,500 0,250" fill="none" stroke="$strokeColor" stroke-width="2"/>',
    );

    // Define center points for each of the 12 houses to place text
    const centers = [
      (dx: 250.0, dy: 120.0), // House 1
      (dx: 120.0, dy: 60.0), // House 2
      (dx: 60.0, dy: 120.0), // House 3
      (dx: 125.0, dy: 250.0), // House 4
      (dx: 60.0, dy: 380.0), // House 5
      (dx: 120.0, dy: 440.0), // House 6
      (dx: 250.0, dy: 380.0), // House 7
      (dx: 380.0, dy: 440.0), // House 8
      (dx: 440.0, dy: 380.0), // House 9
      (dx: 375.0, dy: 250.0), // House 10
      (dx: 440.0, dy: 120.0), // House 11
      (dx: 380.0, dy: 60.0), // House 12
    ];

    final ascSign = (ascendant / 30).floor() % 12;

    // Place sign numbers and planets in houses
    for (var h = 1; h <= 12; h++) {
      final center = centers[h - 1];
      final signNumber = ((ascSign + h - 1) % 12) + 1;

      // Draw sign number
      buffer.write(
        '<text x="${center.dx}" y="${center.dy - 25}" text-anchor="middle" font-family="system-ui, sans-serif" font-size="11" font-weight="bold" fill="$labelColor">$signNumber</text>',
      );

      // Get planets in this house
      final planetsInHouse = getPlanetsInHouse(
        h,
      ).map((info) => _getPlanetAbbr(info.planet)).toList();
      // Check node placements manually since they are not in planets map
      final rahuHouse = houses.getHouseForLongitude(rahu.longitude);
      if (rahuHouse == h) planetsInHouse.add('Ra');
      final ketuHouse = houses.getHouseForLongitude(ketu.longitude);
      if (ketuHouse == h) planetsInHouse.add('Ke');

      // Draw lagna marker on the 1st house
      if (h == 1) {
        buffer.write(
          '<text x="${center.dx}" y="${center.dy - 40}" text-anchor="middle" font-family="system-ui, sans-serif" font-size="10" font-weight="bold" fill="$ascColor">ASC</text>',
        );
      }

      // Draw planets
      if (planetsInHouse.isNotEmpty) {
        var py = center.dy;
        for (var pIdx = 0; pIdx < planetsInHouse.length; pIdx += 3) {
          final chunk = planetsInHouse
              .sublist(
                pIdx,
                pIdx + 3 > planetsInHouse.length
                    ? planetsInHouse.length
                    : pIdx + 3,
              )
              .join(' ');
          buffer.write(
            '<text x="${center.dx}" y="$py" text-anchor="middle" font-family="system-ui, sans-serif" font-size="13" font-weight="bold" fill="$textColor">$chunk</text>',
          );
          py += 16.0;
        }
      }
    }
  }

  String _getPlanetAbbr(Planet planet) {
    return switch (planet) {
      Planet.sun => 'Su',
      Planet.moon => 'Mo',
      Planet.mars => 'Ma',
      Planet.mercury => 'Me',
      Planet.jupiter => 'Ju',
      Planet.venus => 'Ve',
      Planet.saturn => 'Sa',
      Planet.meanNode || Planet.trueNode => 'Ra',
      Planet.ketu => 'Ke',
      _ => planet.displayName.substring(0, 2),
    };
  }
}
