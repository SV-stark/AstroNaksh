import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@freezed
abstract class Location with _$Location {
  const factory Location({
    required double latitude,
    required double longitude,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LocationToJson(this as _Location);
}

@freezed
abstract class BirthData with _$BirthData {
  const factory BirthData({
    required DateTime dateTime,

    /// The converters are required: without them the generator writes the raw
    /// [Location] instance into the map, and `fromJson` then throws when it
    /// casts the value back to `Map<String, dynamic>`.
    @JsonKey(fromJson: _locationFromJson, toJson: _locationToJson)
    required Location location,
    @Default('') String name,
    @Default('') String place,
    @Default('') String timezone,
  }) = _BirthData;

  factory BirthData.fromJson(Map<String, dynamic> json) =>
      _$BirthDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BirthDataToJson(this as _BirthData);
}

Location _locationFromJson(Map<String, dynamic> json) =>
    Location.fromJson(json);

Map<String, dynamic> _locationToJson(Location location) => location.toJson();
