import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../core/ephemeris_manager.dart';

class GowriPanchangaService {
  /// Get current Gowri Panchanga
  Future<GowriPanchangamInfo> getCurrentGowriPanchanga(
    DateTime dateTime,
    Location location,
  ) async {
    await EphemerisManager.ensureEphemerisData();
    return await EphemerisManager.jyotish.getCurrentGowriPanchangam(
      dateTime: dateTime,
      location: _toGeoLocation(location),
    );
  }

  /// Get Gowri Panchanga for a full day
  Future<List<GowriPanchangamInfo>> getGowriPanchangaForDay(
    DateTime date,
    Location location,
  ) async {
    await EphemerisManager.ensureEphemerisData();
    final results = <GowriPanchangamInfo>[];
    
    for (int hour = 0; hour < 24; hour++) {
      final dt = DateTime(date.year, date.month, date.day, hour);
      final gowri = await getCurrentGowriPanchanga(dt, location);
      results.add(gowri);
    }
    
    return results;
  }

  /// Find best muhurta for activity based on Gowri Panchanga
  Future<List<MuhurtaPeriod>> findBestGowriMuhurta(
    DateTime date,
    Location location,
    String activity,
  ) async {
    final gowriList = await getGowriPanchangaForDay(date, location);
    
    final favorable = <MuhurtaPeriod>[];
    DateTime? startTime;
    
    for (int i = 0; i < gowriList.length; i++) {
      final gowri = gowriList[i];
      final isFavorable = _isFavorableForActivity(gowri, activity);
      
      if (isFavorable && startTime == null) {
        startTime = DateTime(date.year, date.month, date.day, i);
      } else if (!isFavorable && startTime != null) {
        favorable.add(MuhurtaPeriod(
          start: startTime,
          end: DateTime(date.year, date.month, date.day, i),
          quality: 'Gowri favorable',
        ));
        startTime = null;
      }
    }
    
    if (startTime != null) {
      favorable.add(MuhurtaPeriod(
        start: startTime,
        end: DateTime(date.year, date.month, date.day, 23, 59),
        quality: 'Gowri favorable',
      ));
    }
    
    return favorable;
  }

  bool _isFavorableForActivity(GowriPanchangamInfo gowri, String activity) {
    final activityLower = activity.toLowerCase();
    
    switch (activityLower) {
      case 'marriage':
      case 'wedding':
        return gowri.weekday == 'Friday' || gowri.weekday == 'Wednesday';
      case 'education':
      case 'learning':
        return gowri.weekday == 'Wednesday' || gowri.weekday == 'Thursday';
      case 'business':
      case 'new venture':
        return gowri.weekday == 'Wednesday' || gowri.weekday == 'Friday';
      case 'property':
      case 'real estate':
        return gowri.weekday == 'Tuesday' || gowri.weekday == 'Saturday';
      default:
        return gowri.isAuspicious;
    }
  }

  GeographicLocation _toGeoLocation(Location location) {
    return GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: 0,
    );
  }
}

class MuhurtaPeriod {
  final DateTime start;
  final DateTime end;
  final String quality;

  MuhurtaPeriod({
    required this.start,
    required this.end,
    required this.quality,
  });

  Duration get duration => end.difference(start);
}
