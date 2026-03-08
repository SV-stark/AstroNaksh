/// Data class for divisional chart information
class DivisionalChartData {
  final String code; // e.g., 'D-9'
  final String name;
  final String description;
  final Map<String, double> positions; // planet name -> longitude
  final int? ascendantSign;

  DivisionalChartData({
    required this.code,
    required this.name,
    required this.description,
    required this.positions,
    this.ascendantSign,
  });

  /// Get planet's sign in this divisional chart
  int getPlanetSign(String planet) {
    final longitude = positions[planet];
    if (longitude == null) return 0;
    return (longitude / 30).floor();
  }

  /// Get formatted string showing planet positions
  String getFormattedPositions() {
    final buffer = StringBuffer();
    buffer.writeln('$name ($code) - $description');
    buffer.writeln('=' * 40);

    positions.forEach((planet, longitude) {
      final sign = (longitude / 30).floor();
      final degree = longitude % 30;
      final signName = _getSignName(sign);
      buffer.writeln('$planet: ${degree.toStringAsFixed(2)}° $signName');
    });

    if (ascendantSign != null) {
      buffer.writeln('Ascendant: ${_getSignName(ascendantSign!)}');
    }

    return buffer.toString();
  }

  static String _getSignName(int sign) {
    const signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return signs[sign % 12];
  }
}
