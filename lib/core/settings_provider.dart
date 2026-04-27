import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

import 'app_environment.dart';
import 'chart_customization.dart';
import 'database.dart';
import 'settings_state.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  static const String _chartSettingsKey = 'chart_settings';
  static const String _themeModeKey = 'theme_mode';
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  @override
  Future<SettingsState> build() async {
    return _loadSettings();
  }

  Future<SettingsState> _loadSettings() async {
    if (AppEnvironment.isPortable) {
      return _loadSettingsFromDb();
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final themeModeString = prefs.getString(_themeModeKey);
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeModeString,
      orElse: () => ThemeMode.system,
    );

    // Chart Settings
    ChartCustomization chartSettings = ChartCustomization();
    final chartSettingsString = prefs.getString(_chartSettingsKey);
    if (chartSettingsString != null) {
      try {
        chartSettings = ChartCustomization.fromJson(jsonDecode(chartSettingsString));
      } catch (_) {}
    }

    return SettingsState(
      chartSettings: chartSettings,
      themeMode: themeMode,
      hasSeenTutorial: prefs.getBool(_hasSeenTutorialKey) ?? false,
    );
  }

  Future<SettingsState> _loadSettingsFromDb() async {
    final db = ref.read(databaseProvider);
    final allSettings = await db.select(db.settings).get();
    final settingsMap = {for (var s in allSettings) s.key: s.value};

    final themeStr = settingsMap[_themeModeKey];
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeStr,
      orElse: () => ThemeMode.system,
    );

    ChartCustomization chartSettings = ChartCustomization();
    final chartStr = settingsMap[_chartSettingsKey];
    if (chartStr != null) {
      try {
        chartSettings = ChartCustomization.fromJson(jsonDecode(chartStr));
      } catch (_) {}
    }

    return SettingsState(
      chartSettings: chartSettings,
      themeMode: themeMode,
      hasSeenTutorial: settingsMap[_hasSeenTutorialKey] == 'true',
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _saveSetting(_themeModeKey, mode.toString());
      final currentState = state.value!;
      return currentState.copyWith(themeMode: mode);
    });
  }

  Future<void> updateChartSettings(ChartCustomization chartSettings) async {
    state = await AsyncValue.guard(() async {
      await _saveSetting(_chartSettingsKey, jsonEncode(chartSettings.toJson()));
      return state.value!.copyWith(chartSettings: chartSettings);
    });
  }

  Future<void> setHasSeenTutorial(bool value) async {
    state = await AsyncValue.guard(() async {
      await _saveSetting(_hasSeenTutorialKey, value.toString());
      return state.value!.copyWith(hasSeenTutorial: value);
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    if (AppEnvironment.isPortable) {
      final db = ref.read(databaseProvider);
      await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion(
          key: Value(key),
          value: Value(value),
        ),
      );
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
