import 'package:fluent_ui/fluent_ui.dart';
import '../core/chart_customization.dart';
import '../core/ayanamsa_calculator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ChartCustomization _settings;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _settings = ChartCustomization.fromJson(SettingsManager.current.toJson());
  }

  void _saveSettings() {
    SettingsManager.updateSettings(_settings);
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Settings saved'),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.design),
            title: const Text('Chart Display'),
            body: _buildChartDisplaySettings(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.globe),
            title: const Text('Planets'),
            body: _buildPlanetSettings(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Houses'),
            body: _buildHouseSettings(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Ayanamsa'),
            body: _buildAyanamsaSettings(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.pdf),
            title: const Text('PDF Report'),
            body: _buildPdfSettings(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text('Dasha'),
            body: _buildDashaSettings(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.reset),
            title: const Text('Reset'),
            body: _buildPresetsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartDisplaySettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Chart Display')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chart Style',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ChartStyle.values.map((style) {
                    return ToggleButton(
                      checked: _settings.chartStyle == style,
                      onChanged: (v) {
                        if (v) setState(() => _settings.chartStyle = style);
                      },
                      child: Text(_formatEnumName(style.name)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color Scheme',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ColorScheme.values.map((scheme) {
                    return ToggleButton(
                      checked: _settings.colorScheme == scheme,
                      onChanged: (v) {
                        if (v) setState(() => _settings.colorScheme = scheme);
                      },
                      child: Text(_formatEnumName(scheme.name)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planet Size',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: PlanetSize.values.map((size) {
                    return ToggleButton(
                      checked: _settings.planetSize == size,
                      onChanged: (v) {
                        if (v) setState(() => _settings.planetSize = size);
                      },
                      child: Text(_formatEnumName(size.name)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Planet Display')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildToggle('Show Degrees', _settings.showDegrees, (v) {
                  setState(() => _settings.showDegrees = v);
                }),
                _buildToggle('Show Nakshatras', _settings.showNakshatras, (v) {
                  setState(() => _settings.showNakshatras = v);
                }),
                _buildToggle('Show Retrograde', _settings.showRetrograde, (v) {
                  setState(() => _settings.showRetrograde = v);
                }),
                _buildToggle('Show Combust', _settings.showCombust, (v) {
                  setState(() => _settings.showCombust = v);
                }),
                _buildToggle(
                  'Show Exalted/Debilitated',
                  _settings.showExaltedDebilitated,
                  (v) {
                    setState(() => _settings.showExaltedDebilitated = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHouseSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('House Settings')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'House System',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HouseSystem.values.map((system) {
                    return ToggleButton(
                      checked: _settings.houseSystem == system,
                      onChanged: (v) {
                        if (v) setState(() => _settings.houseSystem = system);
                      },
                      child: Text(_formatEnumName(system.name)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildToggle('Show Houses', _settings.showHouses, (v) {
                  setState(() => _settings.showHouses = v);
                }),
                _buildToggle('Show Signs', _settings.showSigns, (v) {
                  setState(() => _settings.showSigns = v);
                }),
                _buildToggle('Show House Cusps', _settings.showHouseCusps, (v) {
                  setState(() => _settings.showHouseCusps = v);
                }),
                _buildToggle('Show House Numbers', _settings.showHouseNumbers, (
                  v,
                ) {
                  setState(() => _settings.showHouseNumbers = v);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAyanamsaSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Ayanamsa System')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Ayanamsa',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                ...AyanamsaCalculator.systems.map((system) {
                  final isSelected =
                      _settings.ayanamsaSystem.toLowerCase() ==
                      system.name.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile.selectable(
                      selected: isSelected,
                      onPressed: () {
                        setState(() => _settings.ayanamsaSystem = system.name);
                      },
                      leading: Icon(
                        isSelected
                            ? FluentIcons.radio_bullet
                            : FluentIcons.circle_ring,
                        color: isSelected
                            ? FluentTheme.of(context).accentColor
                            : null,
                      ),
                      title: Text(system.name),
                      subtitle: Text(system.description),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('PDF Report Options')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildToggle('Include D-1 Chart', _settings.pdfIncludeD1, (v) {
                  setState(() => _settings.pdfIncludeD1 = v);
                }),
                _buildToggle('Include D-9 Navamsa', _settings.pdfIncludeD9, (
                  v,
                ) {
                  setState(() => _settings.pdfIncludeD9 = v);
                }),
                _buildToggle('Include Dasha', _settings.pdfIncludeDasha, (v) {
                  setState(() => _settings.pdfIncludeDasha = v);
                }),
                _buildToggle('Include KP Analysis', _settings.pdfIncludeKP, (
                  v,
                ) {
                  setState(() => _settings.pdfIncludeKP = v);
                }),
                _buildToggle(
                  'Include Other Vargas',
                  _settings.pdfIncludeVargas,
                  (v) {
                    setState(() => _settings.pdfIncludeVargas = v);
                  },
                ),
                _buildToggle(
                  'Include Interpretations',
                  _settings.pdfIncludeInterpretations,
                  (v) {
                    setState(() => _settings.pdfIncludeInterpretations = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashaSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Dasha & Transit')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dasha Years to Show',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _settings.dashaYearsToShow.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        onChanged: (v) {
                          setState(
                            () => _settings.dashaYearsToShow = v.toInt(),
                          );
                        },
                        label: '${_settings.dashaYearsToShow} years',
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('${_settings.dashaYearsToShow} yrs'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildToggle('Show Antardasha', _settings.showAntardasha, (v) {
                  setState(() => _settings.showAntardasha = v);
                }),
                _buildToggle(
                  'Show Pratyantardasha',
                  _settings.showPratyantardasha,
                  (v) {
                    setState(() => _settings.showPratyantardasha = v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transit Settings',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                _buildToggle('Show Transits', _settings.showTransits, (v) {
                  setState(() => _settings.showTransits = v);
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Days to show: '),
                    Expanded(
                      child: Slider(
                        value: _settings.transitDaysToShow.toDouble(),
                        min: 7,
                        max: 90,
                        divisions: 11,
                        onChanged: (v) {
                          setState(
                            () => _settings.transitDaysToShow = v.toInt(),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text('${_settings.transitDaysToShow}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Presets & Reset')),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Presets',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => _applyPreset('beginner'),
                      child: const Text('Beginner'),
                    ),
                    FilledButton(
                      onPressed: () => _applyPreset('professional'),
                      child: const Text('Professional'),
                    ),
                    Button(
                      onPressed: () => _applyPreset('minimal'),
                      child: const Text('Minimal'),
                    ),
                    Button(
                      onPressed: () => _applyPreset('print'),
                      child: const Text('Print-Friendly'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                Button(
                  onPressed: () {
                    setState(() => _settings.resetToDefaults());
                  },
                  child: const Text('Reset to Defaults'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyPreset(String name) {
    setState(() {
      switch (name) {
        case 'beginner':
          _settings = ChartPresets.beginner;
          break;
        case 'professional':
          _settings = ChartPresets.professional;
          break;
        case 'minimal':
          _settings = ChartPresets.minimal;
          break;
        case 'print':
          _settings = ChartPresets.printFriendly;
          break;
      }
    });
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          ToggleSwitch(checked: value, onChanged: onChanged),
        ],
      ),
    );
  }

  String _formatEnumName(String name) {
    // Convert camelCase to Title Case
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
