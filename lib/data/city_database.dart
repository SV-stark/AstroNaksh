import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// City Database with GPS Integration
/// Comprehensive database of world cities with coordinates
class CityDatabase {
  /// Major cities database
  /// internal list of cities
  static List<City> _cities = [];

  static bool _initialized = false;

  /// Initialize the database
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/cities2.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cities = jsonList.map((json) {
        return City(
          name: json['n'] as String,
          state: json['s'] as String,
          country: json['c'] as String,
          latitude: (json['la'] as num).toDouble(),
          longitude: (json['lo'] as num).toDouble(),
          timezone: 'Asia/Kolkata', // Dataset is India-focused
        );
      }).toList();

      // Sort by name for faster binary search if needed, currently just sort for clean display
      _cities.sort((a, b) => a.name.compareTo(b.name));

      _initialized = true;
      debugPrint('CityDatabase: Loaded ${_cities.length} cities.');
    } catch (e) {
      debugPrint('CityDatabase: Error loading cities: $e');
      // Fallback to a minimal list if load fails
      _cities = [
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
      ];
      _initialized = true;
    }
  }

  /// Get all cities
  static List<City> getAllCities() => _cities;

  /// Find cities by name (prefix search)
  static List<City> searchCities(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _cities
        .where((city) => city.name.toLowerCase().startsWith(lowerQuery))
        .take(20)
        .toList();
  }

  /// Find nearest city to coordinates
  static City findNearestCity(double lat, double lon) {
    if (_cities.isEmpty) {
      return const City(
        name: 'New Delhi',
        state: 'Delhi',
        country: 'India',
        latitude: 28.6139,
        longitude: 77.2090,
        timezone: 'Asia/Kolkata',
      );
    }

    City nearest = _cities.first;
    double minDistance = _calculateDistance(lat, lon, nearest.latitude, nearest.longitude);

    for (var i = 1; i < _cities.length; i++) {
      final dist = _calculateDistance(lat, lon, _cities[i].latitude, _cities[i].longitude);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = _cities[i];
      }
    }

    return nearest;
  }

  /// Haversine formula for distance between coordinates
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  /// Get current location and find nearest city
  static Future<City?> getCityFromCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      return findNearestCity(position.latitude, position.longitude);
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
  final String name;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;

  String get displayName => '$name, $state, $country';

  const City({
    required this.name,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

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
