import 'package:astronaksh/data/models.dart';
import 'package:jyotish/jyotish.dart';

/// A builder class to create [CompleteChartData] for testing purposes.
class TestChartBuilder {
  final Map<Planet, PlanetInput> _planets = {};
  double _ascendant = 0; // default to Aries rising
  final DateTime _dateTime = DateTime.utc(
    2000,
    1,
    1,
    12,
    0,
  ); // Made final as suggested
  Location _location = Location(latitude: 0, longitude: 0);

  // Rahu longitude. Ketu will be opposite.
  double? _rahuLongitude;

  TestChartBuilder();

  /// Set the Ascendant (Lagna) sign (1-12)
  TestChartBuilder withAscendantSign(int sign) {
    // Set to middle of the sign
    _ascendant = (sign - 1) * 30.0 + 15.0;
    return this;
  }

  /// Set a planet's position by sign (1-12) and optional degrees (0-30)
  TestChartBuilder withPlanetInSign(
    Planet planet,
    int sign, [
    double degrees = 15.0,
  ]) {
    final longitude = (sign - 1) * 30.0 + degrees;

    if (planet == Planet.meanNode) {
      _rahuLongitude = longitude;
    } else {
      _planets[planet] = PlanetInput(
        longitude: longitude,
        speed: 1.0,
      ); // Default forward motion
    }
    return this;
  }

  /// Helper for setting Rahu (Mean Node)
  TestChartBuilder withRahuInSign(int sign, [double degrees = 15.0]) {
    final longitude = (sign - 1) * 30.0 + degrees;
    _rahuLongitude = longitude;
    return this;
  }

  /// Helper for setting Ketu (implicitly sets Rahu opposite)
  TestChartBuilder withKetuInSign(int sign, [double degrees = 15.0]) {
    final ketuLong = (sign - 1) * 30.0 + degrees;
    final rahuLong = (ketuLong + 180) % 360;
    _rahuLongitude = rahuLong;
    return this;
  }

  /// Set a planet to be retrograde
  TestChartBuilder withRetrogradePlanet(Planet planet) {
    if (planet == Planet.meanNode) {
      // Nodes are usually retrograde/mean, speed logic handled in position creation
      return this;
    }

    if (_planets.containsKey(planet)) {
      final current = _planets[planet]!;
      _planets[planet] = PlanetInput(longitude: current.longitude, speed: -1.0);
    }
    return this;
  }

  /// Set specific coordinates
  TestChartBuilder withLocation(double lat, double lng) {
    _location = Location(latitude: lat, longitude: lng);
    return this;
  }

  /// Build the mock CompleteChartData
  CompleteChartData build() {
    // 1. Create Houses
    final houseCusps = List<double>.generate(12, (index) {
      return (_ascendant + (index * 30.0)) % 360.0;
    });

    final houseSystem = HouseSystem(
      system: 'Equal',
      cusps: houseCusps,
      ascendant: _ascendant,
      midheaven: (_ascendant + 270) % 360, // Approx MC
    );

    // 2. Create Planet Map for VedicChart
    final vedicPlanets = <Planet, VedicPlanetInfo>{};

    // Standard planets
    final standardPlanets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];

    for (final p in standardPlanets) {
      final input = _planets[p] ?? PlanetInput(longitude: 0, speed: 1);

      final position = PlanetPosition(
        planet: p,
        dateTime: _dateTime,
        longitude: input.longitude,
        latitude: 0,
        distance: 1,
        longitudeSpeed: input.speed,
        latitudeSpeed: 0,
        distanceSpeed: 0,
        isCombust: false, // Simplified
      );

      vedicPlanets[p] = VedicPlanetInfo(
        position: position,
        house: _getHouse(input.longitude, _ascendant),
        dignity: PlanetaryDignity
            .neutralSign, // Simplified, logic in builder doesn't calculate dignity yet
        isCombust: false,
        exaltationDegree: 0,
        debilitationDegree: 0,
      );
    }

    // 3. Handle Rahu/Ketu
    final rahuLong = _rahuLongitude ?? 0.0;
    final rahuPosition = PlanetPosition(
      planet: Planet.meanNode,
      dateTime: _dateTime,
      longitude: rahuLong,
      latitude: 0,
      distance: 1,
      longitudeSpeed: -1, // Usually retrograde
      latitudeSpeed: 0,
      distanceSpeed: 0,
      isCombust: false,
    );

    final rahuInfo = VedicPlanetInfo(
      position: rahuPosition,
      house: _getHouse(rahuLong, _ascendant),
      dignity: PlanetaryDignity.neutralSign,
      isCombust: false,
      exaltationDegree: 0,
      debilitationDegree: 0,
    );

    final ketu = KetuPosition(rahuPosition: rahuPosition);

    final vedicChart = VedicChart(
      dateTime: _dateTime,
      location: 'Test Location',
      latitude: _location.latitude,
      longitudeCoord: _location.longitude,
      houses: houseSystem,
      planets: vedicPlanets,
      rahu: rahuInfo,
      ketu: ketu,
    );

    // Empty Dasha/KP data for now
    final dashaData = DashaData(
      vimshottari: VimshottariDasha(
        birthLord: 'Sun',
        balanceAtBirth: 0,
        mahadashas: [],
      ),
      yogini: YoginiDasha(startYogini: 'Mangala', mahadashas: []),
      chara: CharaDasha(startSign: 1, periods: []),
    );

    final kpData = KPData(subLords: [], significators: [], rulingPlanets: []);

    return CompleteChartData(
      birthData: BirthData(
        dateTime: _dateTime,
        location: _location,
        name: 'Test User',
        place: 'Test Place',
      ),
      baseChart: vedicChart,
      divisionalCharts: {},
      dashaData: dashaData,
      kpData: kpData,
      // ashtakavarga removed
      significatorTable: _buildSignificatorTable(vedicChart),
    );
  }

  int _getHouse(double longitude, double ascendant) {
    // Equal house system
    double adjusted = (longitude - ascendant + 360) % 360;
    return (adjusted / 30).floor() + 1;
  }

  Map<String, Map<String, dynamic>> _buildSignificatorTable(VedicChart chart) {
    final map = <String, Map<String, dynamic>>{};

    chart.planets.forEach((planet, data) {
      map[planet.name] = {
        'position': data.position.longitude,
        'house': data.house,
        'sign': _getSignName((data.position.longitude / 30).floor()),
        'speed': data.position.longitudeSpeed,
      };
    });

    // Valid for Rahu too
    map['Rahu'] = {
      'position': chart.rahu.position.longitude,
      'house': chart.rahu.house,
      'sign': _getSignName((chart.rahu.position.longitude / 30).floor()),
      'speed': chart.rahu.position.longitudeSpeed,
    };

    // Fixed Ketu access
    map['Ketu'] = {
      'position': chart.ketu.longitude,
      'house': _getHouse(chart.ketu.longitude, chart.houses.ascendant),
      'sign': _getSignName((chart.ketu.longitude / 30).floor()),
      'speed': chart.rahu.position.longitudeSpeed, // Use Rahu speed
    };

    return map;
  }

  String _getSignName(int index) {
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
    return signs[index % 12];
  }
}

class PlanetInput {
  final double longitude;
  final double speed;
  PlanetInput({required this.longitude, required this.speed});
}
