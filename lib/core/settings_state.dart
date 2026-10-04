import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'chart_customization.dart';

part 'settings_state.freezed.dart';

/// Application-level settings persisted by `Settings`.
///
/// Deliberately free of a `fromJson` factory: the provider reads and writes
/// this object field by field, so the generated json round-trip was dead code.
@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ChartCustomization chartSettings,
    @Default(ThemeMode.system) ThemeMode themeMode,
  }) = _SettingsState;
}
