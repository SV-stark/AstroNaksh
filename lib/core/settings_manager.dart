import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
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
    notifyListeners();
  }

  Future<void> updateChartSettings(ChartCustomization settings) async {
    _chartSettings = settings;
    notifyListeners();
    _saveChartSettings();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
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
    _saveChartSettings();
  }

  Future<void> resetToDefaults() async {
    _chartSettings.resetToDefaults();
    notifyListeners();
    _saveChartSettings();
  }

  Future<void> _saveChartSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chartSettingsKey,
      jsonEncode(_chartSettings.toJson()),
    );
  }
}
