import 'package:jyotish/src/models/aspect.dart';
import 'package:jyotish/src/models/calculation_flags.dart';
import 'package:jyotish/src/models/geographic_location.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/astronomy/planet_position.dart';
import 'package:jyotish/src/transit/transit.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/astronomy/ephemeris_service.dart';

/// Service for calculating planetary transits.
///
/// Transits show the current positions of planets relative to a natal chart,
/// identifying significant aspects between transit and natal positions.
class TransitService {
  TransitService(this._ephemerisService);
  final EphemerisService _ephemerisService;

  /// Calculates transit positions for all planets at a given time.
  ///
  /// [natalChart] - The birth chart to compare transits against
  /// [transitDateTime] - Date/time for transit positions
  /// [location] - Geographic location for calculations
  ///
  /// Returns a map of planets to their transit info.
  Future<Map<Planet, TransitInfo>> calculateTransits({
    required VedicChart natalChart,
    required DateTime transitDateTime,
    required GeographicLocation location,
  }) async {
    final flags =
        natalChart.calculationFlags ?? CalculationFlags.traditionalist();
    final transits = <Planet, TransitInfo>{};

    // Calculate transit positions for traditional planets + nodes
    final rahuPlanet = flags.nodeType == NodeType.trueNode
        ? Planet.trueNode
        : Planet.meanNode;
    final planetsToCalculate = [
      ...Planet.traditionalPlanets,
      rahuPlanet,
      Planet.ketu,
    ];

    for (final planet in planetsToCalculate) {
      final transitPosition = await _ephemerisService.calculatePlanetPosition(
        planet: planet,
        dateTime: transitDateTime,
        location: location,
        flags: flags,
      );

      // Get natal position for this planet
      PlanetPosition? natalPosition;
      if (natalChart.planets.containsKey(planet)) {
        natalPosition = natalChart.planets[planet]?.position;
      } else if (planet == Planet.meanNode || planet == Planet.trueNode) {
        natalPosition = natalChart.rahu.position;
      } else if (planet == Planet.ketu) {
        natalPosition = natalChart.ketu.position;
      }

      // Determine which house the transit planet is in (natal chart houses)
      final transitHouse = natalChart.houses.getHouseForLongitude(
        transitPosition.longitude,
      );
      final transitSignIndex = (transitPosition.longitude / 30).floor() % 12;

      // Calculate aspects to natal planets
      final aspectsToNatal = _calculateTransitAspects(
        transitPosition,
        natalChart,
      );

      final info = TransitInfo(
        planet: planet,
        transitPosition: transitPosition,
        natalPosition: natalPosition,
        transitHouse: transitHouse,
        transitSignIndex: transitSignIndex,
        aspectsToNatal: aspectsToNatal,
      );
      transits[planet] = info;
      if (planet == Planet.meanNode && !transits.containsKey(Planet.trueNode)) {
        transits[Planet.trueNode] = info;
      } else if (planet == Planet.trueNode &&
          !transits.containsKey(Planet.meanNode)) {
        transits[Planet.meanNode] = info;
      }
    }

    return transits;
  }

  /// Calculates aspects from a single transit planet position to all natal positions.
  List<AspectInfo> calculateTransitAspects(
    PlanetPosition transitPos,
    VedicChart natalChart,
  ) =>
      _calculateTransitAspects(transitPos, natalChart);

  /// Calculates aspects from a single transit planet to all natal positions.
  List<AspectInfo> _calculateTransitAspects(
    PlanetPosition transitPos,
    VedicChart natalChart,
  ) {
    const config = AspectConfig.vedic;

    final allNatal = <Planet, PlanetPosition>{
      ...natalChart.planets.map((k, v) => MapEntry(k, v.position)),
      natalChart.rahu.position.planet: natalChart.rahu.position,
      natalChart.ketu.position.planet: natalChart.ketu.position,
    };

    return allNatal.entries
        .map((entry) {
          final natalPlanet = entry.key;
          final natalPos = entry.value;

          // Calculate angular difference
          var angularDiff = (natalPos.longitude - transitPos.longitude) % 360;
          if (angularDiff < 0) angularDiff += 360;

          final aspects = <AspectInfo>[];

          // Check conjunction
          if (angularDiff.abs() <= 10 || (360 - angularDiff).abs() <= 10) {
            final orb = angularDiff <= 180 ? angularDiff : 360 - angularDiff;
            aspects.add(
              AspectInfo(
                aspectingPlanet: transitPos.planet,
                aspectedPlanet: natalPlanet,
                type: AspectType.conjunction,
                exactOrb: orb,
                isApplying: transitPos.longitudeSpeed > 0,
                strength: 1.0 - (orb / 10).clamp(0.0, 1.0),
                aspectingLongitude: transitPos.longitude,
                aspectedLongitude: natalPos.longitude,
              ),
            );
          }

          // Check opposition (180)
          final oppDiff = (angularDiff - 180).abs();
          if (oppDiff <= 10) {
            aspects.add(
              AspectInfo(
                aspectingPlanet: transitPos.planet,
                aspectedPlanet: natalPlanet,
                type: AspectType.opposition,
                exactOrb: oppDiff,
                isApplying: transitPos.longitudeSpeed > 0,
                strength: 1.0 - (oppDiff / 10).clamp(0.0, 1.0),
                aspectingLongitude: transitPos.longitude,
                aspectedLongitude: natalPos.longitude,
              ),
            );
          }

          // Check special aspects for Mars, Jupiter, Saturn transits
          if (config.includeSpecialAspects) {
            aspects.addAll(
              _checkTransitSpecialAspects(
                transitPos,
                natalPlanet,
                natalPos,
                angularDiff,
              ),
            );
          }

          return aspects;
        })
        .expand((element) => element)
        .toList();
  }

  /// Check special aspects for transit planets.
  List<AspectInfo> _checkTransitSpecialAspects(
    PlanetPosition transitPos,
    Planet natalPlanet,
    PlanetPosition natalPos,
    double angularDiff,
  ) {
    final aspects = <AspectInfo>[];
    const orb = 10.0;

    // Mars special aspects (4th at 90°, 8th at 210° forward)
    if (transitPos.planet == Planet.mars) {
      if ((angularDiff - 90).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.marsSpecial4th,
            angularDiff - 90,
          ),
        );
      }
      if ((angularDiff - 210).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.marsSpecial8th,
            angularDiff - 210,
          ),
        );
      }
    }

    // Jupiter special aspects
    if (transitPos.planet == Planet.jupiter) {
      if ((angularDiff - 120).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.jupiterSpecial5th,
            angularDiff - 120,
          ),
        );
      }
      if ((angularDiff - 240).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.jupiterSpecial9th,
            angularDiff - 240,
          ),
        );
      }
    }

    // Saturn special aspects
    if (transitPos.planet == Planet.saturn) {
      if ((angularDiff - 60).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.saturnSpecial3rd,
            angularDiff - 60,
          ),
        );
      }
      if ((angularDiff - 270).abs() <= orb) {
        aspects.add(
          _createTransitAspect(
            transitPos,
            natalPlanet,
            natalPos,
            AspectType.saturnSpecial10th,
            angularDiff - 270,
          ),
        );
      }
    }

    return aspects;
  }

  AspectInfo _createTransitAspect(
    PlanetPosition transitPos,
    Planet natalPlanet,
    PlanetPosition natalPos,
    AspectType type,
    double orb,
  ) {
    return AspectInfo(
      aspectingPlanet: transitPos.planet,
      aspectedPlanet: natalPlanet,
      type: type,
      exactOrb: orb.abs(),
      isApplying: transitPos.longitudeSpeed > 0,
      strength: 1.0 - (orb.abs() / type.defaultOrb).clamp(0.0, 1.0),
      aspectingLongitude: transitPos.longitude,
      aspectedLongitude: natalPos.longitude,
    );
  }

  /// Finds significant transit events within a date range.
  ///
  /// [natalChart] - Birth chart
  /// [config] - Transit configuration with date range
  /// [location] - Geographic location
  ///
  /// Returns list of transit events sorted by date.
  Future<List<TransitEvent>> findTransitEvents({
    required VedicChart natalChart,
    required TransitConfig config,
    required GeographicLocation location,
  }) async {
    final events = <TransitEvent>[];
    final rahuPlanet =
        (natalChart.calculationFlags?.nodeType == NodeType.trueNode)
            ? Planet.trueNode
            : Planet.meanNode;
    final planets = config.planets ??
        [...Planet.traditionalPlanets, rahuPlanet, Planet.ketu];

    var currentDate = config.startDate;
    while (currentDate.isBefore(config.endDate)) {
      final transits = await calculateTransits(
        natalChart: natalChart,
        transitDateTime: currentDate,
        location: location,
      );

      // Check for new exact aspects
      for (final planet in planets) {
        final transit = transits[planet];
        if (transit == null) continue;

        for (final aspect in transit.aspectsToNatal) {
          // Check if aspect is becoming exact (transitioning from applying)
          if (aspect.isExact) {
            // The window during which the aspect holds must be COMPUTED, not
            // guessed. An aspect is within orb while the separation sits
            // inside `exactOrb` degrees of exact, and the separation changes
            // at the two bodies' relative angular speed, so the time spent
            // inside the orb is `exactOrb / relativeSpeed` days either side.
            //
            // The previous value, `±3 × intervalDays`, was fabricated from the
            // sampling interval and bore no relation to the actual aspect: a
            // tight orb between two slow planets yields a window of months,
            // while a wide orb between fast planets yields hours — and the
            // fabricated window was identical for both.
            final relativeSpeed = (transit.transitPosition.longitudeSpeed -
                    (natalChart
                            .getPlanet(aspect.aspectedPlanet)
                            ?.position
                            .longitudeSpeed ??
                        0.0))
                .abs();
            final halfSpanDays = relativeSpeed > 1e-9
                ? aspect.exactOrb.abs() / relativeSpeed
                : config.intervalDays.toDouble();
            final halfSpan = Duration(
              microseconds:
                  (halfSpanDays * Duration.microsecondsPerDay).round(),
            );

            final event = TransitEvent(
              transitPlanet: planet,
              natalPlanet: aspect.aspectedPlanet,
              aspectType: aspect.type,
              exactDate: currentDate,
              startDate: currentDate.subtract(halfSpan),
              endDate: currentDate.add(halfSpan),
              isRetrograde: transit.isRetrograde,
              description: _generateTransitDescription(
                aspect,
                transit.isRetrograde,
              ),
              significance: _calculateSignificance(aspect),
            );
            events.add(event);
          }
        }
      }

      currentDate = currentDate.add(Duration(days: config.intervalDays));
    }

    // Sort by date and remove duplicates
    events.sort((a, b) => a.exactDate.compareTo(b.exactDate));
    return _deduplicateEvents(events);
  }

  List<TransitEvent> _deduplicateEvents(List<TransitEvent> events) {
    // Two events are the same only when every identifying field matches:
    // transiting planet, the natal body or point aspected, the aspect, and the
    // exact instant. Bucketing the date into 7-day windows (as this did) made
    // two genuinely different exact aspects of the same pair and type collapse
    // whenever they fell in the same week — so a Tuesday exact opposition and
    // a Thursday exact trine to the same natal planet could not both be
    // reported. Bucketing cannot distinguish them at all, because the key is
    // the same for any instant inside the week.
    final seen = <String>{};
    return events.where((e) {
      final key = '${e.transitPlanet}-'
          '${e.natalPlanet?.name ?? e.natalPointName}-'
          '${e.aspectType.name}-'
          '${e.exactDate.millisecondsSinceEpoch}';
      return seen.add(key);
    }).toList();
  }

  String _generateTransitDescription(AspectInfo aspect, bool isRetrograde) {
    final retro = isRetrograde ? ' (retrograde)' : '';
    return '${aspect.aspectingPlanet.displayName}$retro ${aspect.type.english} natal ${aspect.aspectedPlanet.displayName}';
  }

  int _calculateSignificance(AspectInfo aspect) {
    var significance = 3;

    // Increase for tight aspects
    if (aspect.isExact) significance++;
    if (aspect.isTight) significance++;

    // Increase for major planets
    if (aspect.aspectingPlanet == Planet.saturn ||
        aspect.aspectingPlanet == Planet.jupiter) {
      significance++;
    }

    // Increase for conjunctions and oppositions
    if (aspect.type == AspectType.conjunction ||
        aspect.type == AspectType.opposition) {
      significance++;
    }

    return significance.clamp(1, 5);
  }
}
