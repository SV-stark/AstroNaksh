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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
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
    final dateTimeStr = json['dateTime'] as String?;
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      throw FormatException('Missing or empty dateTime in BirthData');
    }
    final locationJson = json['location'];
    if (locationJson == null || locationJson is! Map) {
      throw FormatException('Missing or invalid location in BirthData');
    }
    return BirthData(
      dateTime: DateTime.parse(dateTimeStr),
      location: Location.fromJson(Map<String, dynamic>.from(locationJson)),
      name: json['name'] as String? ?? '',
      place: json['place'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthData &&
        other.dateTime == dateTime &&
        other.location == location &&
        other.name == name &&
        other.place == place &&
        other.timezone == timezone;
  }

  @override
  int get hashCode =>
      dateTime.hashCode ^
      location.hashCode ^
      name.hashCode ^
      place.hashCode ^
      timezone.hashCode;
}
