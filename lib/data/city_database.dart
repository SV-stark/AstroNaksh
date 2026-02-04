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
        City(
          name: 'New Delhi',
          state: 'Delhi',
          country: 'India',
          latitude: 28.6139,
          longitude: 77.2090,
          timezone: 'Asia/Kolkata',
        ),
        City(
          name: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          latitude: 19.0760,
          longitude: 72.8777,
          timezone: 'Asia/Kolkata',
        ),
      ];
    }
  }

  /// Get all cities
  static List<City> get cities => _cities;

  /// Search cities by name
  static List<City> searchCities(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _cities.where((city) {
      return city.name.toLowerCase().contains(lowerQuery) ||
          city.country.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get city by exact name
  static City? getCityByName(String name) {
    try {
      return _cities.firstWhere(
        (city) => city.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all cities in a country
  static List<City> getCitiesByCountry(String country) {
    return _cities
        .where((city) => city.country.toLowerCase() == country.toLowerCase())
        .toList();
  }

  /// Get current location using GPS
  static Future<City?> getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Find nearest city
      return findNearestCity(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Find nearest city to coordinates
  static City findNearestCity(double latitude, double longitude) {
    City? nearest;
    double minDistance = double.infinity;

    for (final city in _cities) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = city;
      }
    }

    return nearest!;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get all countries
  static List<String> get countries {
    return _cities.map((city) => city.country).toSet().toList()..sort();
  }

  /// Get all cities
  static List<City> get allCities => List.unmodifiable(_cities);

  /// Get total number of cities
  static int get cityCount => _cities.length;
}

/// City data class
class City {
  final String name;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;

  const City({
    required this.name,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  String get displayName => '$name, $state, $country';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.name == name && other.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ country.hashCode;
}

/// Location Service for managing GPS and city selection
class LocationService {
  /// Request location permission
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get city from current position
  static Future<City?> getCityFromCurrentPosition() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return CityDatabase.findNearestCity(position.latitude, position.longitude);
  }
}
