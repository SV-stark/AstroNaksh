import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzlookup;

/// City Database with GPS Integration
/// Comprehensive database of world cities with coordinates
List<City> _parseCities(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) {
    final lat = (json['la'] as num).toDouble();
    final lon = (json['lo'] as num).toDouble();
    return City(
      name: json['n'] as String,
      state: json['s'] as String,
      country: json['c'] as String,
      latitude: lat,
      longitude: lon,
      timezone: tzlookup.latLngToTimezoneString(lat, lon),
    );
  }).toList();
}

class CityDatabase {
  /// Major cities database
  /// internal list of cities
  static List<City> _cities = [];

  static bool _initialized = false;

  // Simple query cache for geocoding search results
  static final Map<String, List<City>> _searchCache = {};

  /// Initialize the database
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/cities2.json',
      );
      
      // Parse JSON in a background isolate to keep UI smooth during load
      _cities = await compute(_parseCities, jsonString);

      // Sort by name for clean display
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

  /// Find cities by name, state, or country (prefix and compound search)
  static List<City> searchCities(String query) {
    if (query.isEmpty) return [];
    final trimmedQuery = query.trim().toLowerCase();

    // Check search query cache
    if (_searchCache.containsKey(trimmedQuery)) {
      return _searchCache[trimmedQuery]!;
    }

    List<City> results;
    if (trimmedQuery.contains(',')) {
      final parts = trimmedQuery.split(',').map((p) => p.trim()).toList();
      final cityName = parts[0];
      final secondary = parts.length > 1 ? parts[1] : '';

      results = _cities.where((city) {
        final nameMatch = city.name.toLowerCase().startsWith(cityName);
        if (!nameMatch) return false;

        final stateMatch = city.state.toLowerCase().startsWith(secondary);
        final countryMatch = city.country.toLowerCase().startsWith(secondary);
        return stateMatch || countryMatch;
      }).take(20).toList();
    } else {
      results = _cities.where((city) {
        return city.name.toLowerCase().startsWith(trimmedQuery) ||
            city.state.toLowerCase().startsWith(trimmedQuery) ||
            city.country.toLowerCase().startsWith(trimmedQuery);
      }).take(20).toList();
    }

    // Keep cache size bounded to 50 entries
    if (_searchCache.length > 50) {
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[trimmedQuery] = results;

    return results;
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

    var nearest = _cities.first;
    var minDistance = _calculateDistance(
      lat,
      lon,
      nearest.latitude,
      nearest.longitude,
    );

    for (var i = 1; i < _cities.length; i++) {
      final dist = _calculateDistance(
        lat,
        lon,
        _cities[i].latitude,
        _cities[i].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = _cities[i];
      }
    }

    return nearest;
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
