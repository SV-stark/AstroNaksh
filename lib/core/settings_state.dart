import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'chart_customization.dart';

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ChartCustomization chartSettings,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool hasSeenTutorial,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
