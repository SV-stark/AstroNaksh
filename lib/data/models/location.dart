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
}

@freezed
abstract class BirthData with _$BirthData {
  const factory BirthData({
    required DateTime dateTime,
    required Location location,
    @Default('') String name,
    @Default('') String place,
    @Default('') String timezone,
  }) = _BirthData;

  factory BirthData.fromJson(Map<String, dynamic> json) =>
      _$BirthDataFromJson(json);
}
