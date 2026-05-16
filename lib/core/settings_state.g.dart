// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsState _$SettingsStateFromJson(Map<String, dynamic> json) =>
    _SettingsState(
      chartSettings: ChartCustomization.fromJson(
        json['chartSettings'] as Map<String, dynamic>,
      ),
      themeMode:
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      hasSeenTutorial: json['hasSeenTutorial'] as bool? ?? false,
    );

Map<String, dynamic> _$SettingsStateToJson(_SettingsState instance) =>
    <String, dynamic>{
      'chartSettings': instance.chartSettings,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'hasSeenTutorial': instance.hasSeenTutorial,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
