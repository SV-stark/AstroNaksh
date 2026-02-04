import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';

class SavedChartsHelper {
  static const String _key = 'saved_charts';

  static Future<List<BirthData>> loadCharts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => BirthData.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveChart(BirthData data) async {
    final charts = await loadCharts();
    // Check if duplicate (simple check by name/time)
    final existingIndex = charts.indexWhere(
      (c) => c.name == data.name && c.dateTime.isAtSameMomentAs(data.dateTime),
    );

    if (existingIndex != -1) {
      charts[existingIndex] = data; // Update
    } else {
      charts.add(data);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(charts.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> removeChart(BirthData data) async {
    final charts = await loadCharts();
    charts.removeWhere(
      (c) => c.name == data.name && c.dateTime.isAtSameMomentAs(data.dateTime),
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(charts.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
