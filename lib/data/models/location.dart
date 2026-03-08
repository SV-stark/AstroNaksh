class Location {
  final double latitude;
  final double longitude;
  Location({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
}

class BirthData {
  final DateTime dateTime;
  final Location location;
  final String name;
  final String place;
  final String timezone;

  BirthData({
    required this.dateTime,
    required this.location,
    this.name = '',
    this.place = '',
    this.timezone = '',
  });

  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'location': location.toJson(),
    'name': name,
    'place': place,
    'timezone': timezone,
  };

  factory BirthData.fromJson(Map<String, dynamic> json) {
    return BirthData(
      dateTime: DateTime.parse(json['dateTime']),
      location: Location.fromJson(json['location']),
      name: json['name'] ?? '',
      place: json['place'] ?? '',
      timezone: json['timezone'] ?? '',
    );
  }
}
