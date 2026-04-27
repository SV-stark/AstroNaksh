// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationImpl _$$LocationImplFromJson(Map<String, dynamic> json) =>
    _$LocationImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$LocationImplToJson(_$LocationImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_$BirthDataImpl _$$BirthDataImplFromJson(Map<String, dynamic> json) =>
    _$BirthDataImpl(
      dateTime: DateTime.parse(json['dateTime'] as String),
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      name: json['name'] as String? ?? '',
      place: json['place'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
    );

Map<String, dynamic> _$$BirthDataImplToJson(_$BirthDataImpl instance) =>
    <String, dynamic>{
      'dateTime': instance.dateTime.toIso8601String(),
      'location': instance.location,
      'name': instance.name,
      'place': instance.place,
      'timezone': instance.timezone,
    };
