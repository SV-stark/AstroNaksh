import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../core/app_environment.dart';

class CityDatabase {
  static Database? _db;
  static bool _initialized = false;

  // Cache for search queries
  static final Map<String, List<City>> _searchCache = {};

  // Fallback cities in case initialization fails or for basic fallback matching
  static final List<City> _fallbackCities = [
    const City(
      name: 'New Delhi',
      state: 'Delhi',
      country: 'India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 'Asia/Kolkata',
    ),
    const City(
      name: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      latitude: 19.0760,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
    ),
    const City(
      name: 'London',
      state: 'England',
      country: 'United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
    ),
    const City(
      name: 'New York',
      state: 'New York',
      country: 'United States',
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: 'America/New_York',
    ),
  ];

  /// Initialize the database by copying the asset cities.db to local storage
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final userDir = await AppEnvironment.getUserDataDirectory();
      final dbFile = File(p.join(userDir.path, 'cities.db'));

      bool copyNeeded = true;
      if (await dbFile.exists()) {
        final prefs = await SharedPreferences.getInstance();
        final currentVer = prefs.getInt('cities_db_version') ?? 0;
        const expectedVer = 1;

        // Ensure database size is valid (> 10MB)
        if (currentVer == expectedVer &&
            await dbFile.length() > 10 * 1024 * 1024) {
          copyNeeded = false;
        }
      }

      if (copyNeeded) {
        debugPrint(
          'CityDatabase: Copying cities.db asset to local user directory...',
        );
        final data = await rootBundle.load('assets/data/cities.db');
        await dbFile.parent.create(recursive: true);

        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await dbFile.writeAsBytes(bytes, flush: true);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cities_db_version', 1);
        debugPrint('CityDatabase: Database copy successful.');
      }

      _db = await openDatabase(dbFile.path, readOnly: true);
      _initialized = true;
      debugPrint('CityDatabase: SQLite database successfully opened.');
    } catch (e) {
      debugPrint('CityDatabase: Error opening SQLite database: $e');
      _initialized = true; // Set to true to avoid infinite retry loops
    }
  }

  /// Get fallback cities for basic verification/fallback
  static List<City> getAllCities() => _fallbackCities;

  /// Find cities by name, state, or country using indexed prefix SQLite queries
  static Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) return [];
    final trimmedQuery = query.trim().toLowerCase();

    if (_searchCache.containsKey(trimmedQuery)) {
      return _searchCache[trimmedQuery]!;
    }

    if (!_initialized || _db == null) {
      await initialize();
      if (_db == null) {
        // Fallback to in-memory search on fallback list
        return _fallbackCities.where((city) {
          return city.name.toLowerCase().startsWith(trimmedQuery) ||
              city.state.toLowerCase().startsWith(trimmedQuery) ||
              city.country.toLowerCase().startsWith(trimmedQuery);
        }).toList();
      }
    }

    List<Map<String, dynamic>> maps;
    try {
      if (trimmedQuery.contains(',')) {
        final parts = trimmedQuery.split(',').map((p) => p.trim()).toList();
        final cityName = parts[0];
        final secondary = parts.length > 1 ? parts[1] : '';

        maps = await _db!.rawQuery(
          'SELECT name, state, country, latitude, longitude, timezone FROM cities '
          'WHERE name LIKE ? AND (state LIKE ? OR country LIKE ?) '
          'LIMIT 20',
          ['$cityName%', '$secondary%', '$secondary%'],
        );
      } else {
        // Query city name prefix (utilizes database index on name)
        maps = await _db!.rawQuery(
          'SELECT name, state, country, latitude, longitude, timezone FROM cities '
          'WHERE name LIKE ? '
          'LIMIT 20',
          ['$trimmedQuery%'],
        );

        // Fallback to searching state or country if no city name matched
        if (maps.isEmpty) {
          maps = await _db!.rawQuery(
            'SELECT name, state, country, latitude, longitude, timezone FROM cities '
            'WHERE state LIKE ? OR country LIKE ? '
            'LIMIT 20',
            ['$trimmedQuery%', '$trimmedQuery%'],
          );
        }
      }
    } catch (e) {
      debugPrint('CityDatabase: Query error: $e');
      return [];
    }

    final results = maps.map((row) {
      return City(
        name: row['name'] as String,
        state: row['state'] as String,
        country: row['country'] as String,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        timezone: row['timezone'] as String,
      );
    }).toList();

    if (_searchCache.length > 50) {
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[trimmedQuery] = results;

    return results;
  }

  /// Find nearest city to coordinates using progressive bounding boxes to restrict distance calculations
  static Future<City> findNearestCity(double lat, double lon) async {
    if (!_initialized || _db == null) {
      await initialize();
    }

    if (_db == null) {
      return _fallbackCities.first;
    }

    double boxSize = 1.0;
    List<Map<String, dynamic>> maps = [];

    try {
      while (maps.isEmpty && boxSize <= 180.0) {
        maps = await _db!.rawQuery(
          'SELECT name, state, country, latitude, longitude, timezone FROM cities '
          'WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
          [lat - boxSize, lat + boxSize, lon - boxSize, lon + boxSize],
        );
        boxSize *= 2.0;
      }
    } catch (e) {
      debugPrint('CityDatabase: Error querying nearest city: $e');
    }

    if (maps.isEmpty) {
      return _fallbackCities.first;
    }

    var nearestRow = maps.first;
    var minDistance = _calculateDistance(
      lat,
      lon,
      nearestRow['latitude'] as double,
      nearestRow['longitude'] as double,
    );

    for (var i = 1; i < maps.length; i++) {
      final row = maps[i];
      final dist = _calculateDistance(
        lat,
        lon,
        row['latitude'] as double,
        row['longitude'] as double,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestRow = row;
      }
    }

    return City(
      name: nearestRow['name'] as String,
      state: nearestRow['state'] as String,
      country: nearestRow['country'] as String,
      latitude: nearestRow['latitude'] as double,
      longitude: nearestRow['longitude'] as double,
      timezone: nearestRow['timezone'] as String,
    );
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }

  /// Get current location and find nearest city
  static Future<City?> getCityFromCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      return await findNearestCity(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Alias for compatibility
  static Future<City?> getCurrentLocation() => getCityFromCurrentPosition();
}

@immutable
class City {
  const City({
    required this.name,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });
  final String name;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;

  String get displayName => '$name, $state, $country';

  @override
  String toString() => '$name, $state, $country';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          state == other.state &&
          country == other.country &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^
      state.hashCode ^
      country.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}
