import 'dart:convert';
import 'dart:io';
import '../data/models.dart';
import 'app_environment.dart';

class DataManager {
  Future<String> exportChartToJson(BirthData data) async {
    final map = {
      'name': data.name,
      'dateTime': data.dateTime.toIso8601String(),
      'latitude': data.location.latitude,
      'longitude': data.location.longitude,
      'place': data.place,
    };
    return jsonEncode(map);
  }

  Future<BirthData?> importChartFromJson(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr);
      return BirthData(
        dateTime: DateTime.parse(map['dateTime']),
        location: Location(
          latitude: map['latitude'],
          longitude: map['longitude'],
        ),
        name: map['name'] ?? '',
        place: map['place'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveToFile(String fileName, String content) async {
    final directory = await AppEnvironment.getUserDataDirectory();
    final file = File('${directory.path}/$fileName.json');
    AppEnvironment.log('DataManager: Saving file to ${file.path}');
    await file.writeAsString(content);
  }
}
