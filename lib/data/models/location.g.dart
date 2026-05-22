// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Location _$LocationFromJson(Map<String, dynamic> json) => _Location(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$LocationToJson(_Location instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

_BirthData _$BirthDataFromJson(Map<String, dynamic> json) => _BirthData(
  dateTime: DateTime.parse(json['dateTime'] as String),
  location: Location.fromJson(json['location'] as Map<String, dynamic>),
  name: json['name'] as String? ?? '',
  place: json['place'] as String? ?? '',
  timezone: json['timezone'] as String? ?? '',
);

Map<String, dynamic> _$BirthDataToJson(_BirthData instance) =>
    <String, dynamic>{
      'dateTime': instance.dateTime.toIso8601String(),
      'location': instance.location.toJson(),
      'name': instance.name,
      'place': instance.place,
      'timezone': instance.timezone,
    };
