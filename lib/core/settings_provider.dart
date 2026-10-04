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
  static const String _webdavPasswordKey = 'astronaksh_webdav_password';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String?> getSecureWebdavPassword() async {
    try {
      return await _secureStorage.read(key: _webdavPasswordKey);
    } catch (error) {
      // Hosts without a working keystore (bare Linux/Windows) land here; the
      // obfuscated copy in the settings blob is the remaining fallback.
      AppEnvironment.log(
        'Secure storage unavailable, password not loaded: $error',
      );
      return null;
    }
  }

  static Future<void> saveSecureWebdavPassword(String password) async {
    if (password.isEmpty) {
      await _secureStorage.delete(key: _webdavPasswordKey);
    } else {
      await _secureStorage.write(key: _webdavPasswordKey, value: password);
    }
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
        AppEnvironment.log(
          'SettingsNotifier: Failed to parse chart settings from prefs: $e',
        );
      }
    }

    final securePassword = await getSecureWebdavPassword();
    if (securePassword != null && securePassword.isNotEmpty) {
      chartSettings.webdavPassword = securePassword;
    }

    return SettingsState(chartSettings: chartSettings, themeMode: themeMode);
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
        AppEnvironment.log(
          'SettingsNotifier: Failed to parse chart settings from DB: $e',
        );
      }
    }

    final securePassword = await getSecureWebdavPassword();
    if (securePassword != null && securePassword.isNotEmpty) {
      chartSettings.webdavPassword = securePassword;
    }

    return SettingsState(chartSettings: chartSettings, themeMode: themeMode);
  }

  SettingsState _currentOrDefault() {
    return state.asData?.value ??
        SettingsState(chartSettings: ChartCustomization());
  }

  /// Defensive copy so callers cannot keep mutating the object that lives
  /// inside provider state (the settings screen edits its instance in place,
  /// which previously leaked unsaved values to every other reader).
  static ChartCustomization _snapshot(ChartCustomization settings) {
    return ChartCustomization.fromJson(settings.toJson());
  }

  /// Persists [body], rolling [state] back to the last known-good value if the
  /// write fails so the UI can never claim success for a lost setting.
  Future<void> _persist(
    SettingsState previous,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (error) {
      state = AsyncValue.data(previous);
      AppEnvironment.log('Failed to persist settings: $error');
      Error.throwWithStackTrace(
        StateError('Could not save settings: $error'),
        StackTrace.current,
      );
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final previous = _currentOrDefault();
    final next = previous.copyWith(themeMode: mode);
    state = AsyncValue.data(next);
    await _persist(
      previous,
      () => _saveSetting(_themeModeKey, mode.toString()),
    );
  }

  Future<void> updateChartSettings(ChartCustomization chartSettings) async {
    final previous = _currentOrDefault();
    final snapshot = _snapshot(chartSettings);
    state = AsyncValue.data(previous.copyWith(chartSettings: snapshot));

    final encoded = jsonEncode(snapshot.toJson());
    await _persist(previous, () async {
      await saveSecureWebdavPassword(snapshot.webdavPassword);
      await _saveSetting(_chartSettingsKey, encoded);
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
