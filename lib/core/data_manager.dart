import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/models.dart';

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
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.json');
    await file.writeAsString(content);
  }
}
