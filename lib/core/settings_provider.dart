import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _webdavPasswordKey = 'astronaksh_webdav_password';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String?> getSecureWebdavPassword() async {
    try {
      return await _secureStorage.read(key: _webdavPasswordKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSecureWebdavPassword(String password) async {
    try {
      if (password.isEmpty) {
        await _secureStorage.delete(key: _webdavPasswordKey);
      } else {
        await _secureStorage.write(key: _webdavPasswordKey, value: password);
      }
    } catch (_) {}
  }

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
    var chartSettings = ChartCustomization();
    final chartSettingsString = prefs.getString(_chartSettingsKey);
    if (chartSettingsString != null && chartSettingsString.isNotEmpty) {
      try {
        final decoded = jsonDecode(chartSettingsString);
        if (decoded is Map<String, dynamic>) {
          chartSettings = ChartCustomization.fromJson(decoded);
        } else if (decoded is Map) {
          chartSettings = ChartCustomization.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (e) {
        AppEnvironment.log('SettingsNotifier: Failed to parse chart settings from prefs: $e');
      }
    }

    final securePassword = await getSecureWebdavPassword();
    if (securePassword != null && securePassword.isNotEmpty) {
      chartSettings.webdavPassword = securePassword;
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
    final settingsMap = {for (final s in allSettings) s.key: s.value};

    final themeStr = settingsMap[_themeModeKey];
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeStr,
      orElse: () => ThemeMode.system,
    );

    var chartSettings = ChartCustomization();
    final chartStr = settingsMap[_chartSettingsKey];
    if (chartStr != null && chartStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(chartStr);
        if (decoded is Map<String, dynamic>) {
          chartSettings = ChartCustomization.fromJson(decoded);
        } else if (decoded is Map) {
          chartSettings = ChartCustomization.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (e) {
        AppEnvironment.log('SettingsNotifier: Failed to parse chart settings from DB: $e');
      }
    }

    final securePassword = await getSecureWebdavPassword();
    if (securePassword != null && securePassword.isNotEmpty) {
      chartSettings.webdavPassword = securePassword;
    }

    return SettingsState(
      chartSettings: chartSettings,
      themeMode: themeMode,
      hasSeenTutorial: settingsMap[_hasSeenTutorialKey] == 'true',
    );
  }

  SettingsState _currentOrDefault() {
    return state.asData?.value ??
        SettingsState(chartSettings: ChartCustomization());
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = _currentOrDefault();
    state = AsyncValue.data(current.copyWith(themeMode: mode));
    await AsyncValue.guard(() async {
      await _saveSetting(_themeModeKey, mode.toString());
      return current.copyWith(themeMode: mode);
    });
  }

  Future<void> updateChartSettings(ChartCustomization chartSettings) async {
    final current = _currentOrDefault();
    state = AsyncValue.data(current.copyWith(chartSettings: chartSettings));
    await AsyncValue.guard(() async {
      await saveSecureWebdavPassword(chartSettings.webdavPassword);
      await _saveSetting(_chartSettingsKey, jsonEncode(chartSettings.toJson()));
      return current.copyWith(chartSettings: chartSettings);
    });
  }

  Future<void> setHasSeenTutorial(bool value) async {
    final current = _currentOrDefault();
    state = AsyncValue.data(current.copyWith(hasSeenTutorial: value));
    await AsyncValue.guard(() async {
      await _saveSetting(_hasSeenTutorialKey, value.toString());
      return current.copyWith(hasSeenTutorial: value);
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    if (AppEnvironment.isPortable) {
      final db = ref.read(databaseProvider);
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion(key: Value(key), value: Value(value)),
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
