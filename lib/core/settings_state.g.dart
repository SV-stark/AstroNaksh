// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsStateImpl _$$SettingsStateImplFromJson(Map<String, dynamic> json) =>
    _$SettingsStateImpl(
      chartSettings: ChartCustomization.fromJson(
        json['chartSettings'] as Map<String, dynamic>,
      ),
      themeMode:
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      hasSeenTutorial: json['hasSeenTutorial'] as bool? ?? false,
    );

Map<String, dynamic> _$$SettingsStateImplToJson(_$SettingsStateImpl instance) =>
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
