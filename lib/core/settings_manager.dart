import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'app_environment.dart';
import 'database_helper.dart';
import 'chart_customization.dart';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();

  factory SettingsManager() {
    return _instance;
  }

  SettingsManager._internal();

  ChartCustomization _chartSettings = ChartCustomization();
  ThemeMode _themeMode = ThemeMode.system;

  ChartCustomization get chartSettings => _chartSettings;
  ThemeMode get themeMode => _themeMode;

  static const String _chartSettingsKey = 'chart_settings';
  static const String _themeModeKey = 'theme_mode';
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  bool _hasSeenTutorial = false;
  bool get hasSeenTutorial => _hasSeenTutorial;

  /// Load settings from SharedPreferences or Database (Portable)
  Future<void> loadSettings() async {
    if (AppEnvironment.isPortable) {
      await _loadSettingsFromDb();
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load Chart Settings
    final chartSettingsString = prefs.getString(_chartSettingsKey);
    if (chartSettingsString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(chartSettingsString);
        _chartSettings = ChartCustomization.fromJson(json);
      } catch (e) {
        debugPrint("Error loading chart settings: $e");
      }
    }

    // Load Tutorial Status
    _hasSeenTutorial = prefs.getBool(_hasSeenTutorialKey) ?? false;

    notifyListeners();
  }

  Future<void> _loadSettingsFromDb() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query('settings');
      final settingsMap = {for (var m in maps) m['key'] as String: m['value']};

      // Theme
      if (settingsMap.containsKey(_themeModeKey)) {
        final modeStr = settingsMap[_themeModeKey];
        if (modeStr != null) {
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == modeStr,
            orElse: () => ThemeMode.system,
          );
        }
      }

      // Chart Settings
      if (settingsMap.containsKey(_chartSettingsKey)) {
        try {
          final chartSettingsValue = settingsMap[_chartSettingsKey];
          if (chartSettingsValue != null) {
            final json = jsonDecode(chartSettingsValue);
            _chartSettings = ChartCustomization.fromJson(json);
          }
        } catch (e) {
          debugPrint("Error loading chart settings from DB: $e");
        }
      }

      // Tutorial
      if (settingsMap.containsKey(_hasSeenTutorialKey)) {
        final tutorialValue = settingsMap[_hasSeenTutorialKey];
        _hasSeenTutorial = tutorialValue == 'true';
      }

      notifyListeners();
    } catch (e) {
      AppEnvironment.log("SettingsManager: Error loading from DB: $e");
    }
  }

  Future<void> setHasSeenTutorial(bool value) async {
    _hasSeenTutorial = value;
    notifyListeners();
    await _saveSetting(_hasSeenTutorialKey, value.toString());
  }

  Future<void> updateChartSettings(ChartCustomization settings) async {
    _chartSettings = settings;
    notifyListeners();
    await _saveSetting(_chartSettingsKey, jsonEncode(_chartSettings.toJson()));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveSetting(_themeModeKey, mode.toString());
  }

  Future<void> applyPreset(String presetName) async {
    switch (presetName.toLowerCase()) {
      case 'beginner':
        _chartSettings = ChartPresets.beginner;
        break;
      case 'professional':
        _chartSettings = ChartPresets.professional;
        break;
      case 'minimal':
        _chartSettings = ChartPresets.minimal;
        break;
      case 'printfriendly':
      case 'print':
        _chartSettings = ChartPresets.printFriendly;
        break;
      default:
        // do nothing or reset
        break;
    }
    notifyListeners();
    await _saveSetting(_chartSettingsKey, jsonEncode(_chartSettings.toJson()));
  }

  Future<void> resetToDefaults() async {
    _chartSettings.resetToDefaults();
    notifyListeners();
    await _saveSetting(_chartSettingsKey, jsonEncode(_chartSettings.toJson()));
  }

  Future<void> _saveSetting(String key, String value) async {
    if (AppEnvironment.isPortable) {
      try {
        final db = await DatabaseHelper().database;
        await db.insert('settings', {
          'key': key,
          'value': value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        AppEnvironment.log("SettingsManager: Error saving to DB: $e");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (value == 'true' || value == 'false') {
        await prefs.setBool(key, value == 'true');
      } else {
        await prefs.setString(key, value);
      }
    }
  }
}
