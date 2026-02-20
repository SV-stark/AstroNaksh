import 'package:fluent_ui/fluent_ui.dart';
import '../core/chart_customization.dart';
import '../core/ayanamsa_calculator.dart';
import '../core/settings_manager.dart';
import '../core/responsive_helper.dart';

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
    _settings = ChartCustomization.fromJson(
      SettingsManager().chartSettings.toJson(),
    );
  }

  void _saveSettings() {
    SettingsManager().updateChartSettings(_settings);
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
        displayMode: context.paneDisplayMode,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.brush),
            title: const Text('Appearance'),
            body: _buildAppearanceSettings(),
          ),
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

  Widget _buildAppearanceSettings() {
    final currentTheme = SettingsManager().themeMode;
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Appearance')),
      children: [
        const Text('App Theme'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile.selectable(
                title: const Text('System Default'),
                leading: const Icon(FluentIcons.system),
                selected: currentTheme == ThemeMode.system,
                onPressed: () =>
                    SettingsManager().updateThemeMode(ThemeMode.system),
              ),
              const Divider(),
              ListTile.selectable(
                title: const Text('Light Mode'),
                leading: const Icon(FluentIcons.sunny),
                selected: currentTheme == ThemeMode.light,
                onPressed: () =>
                    SettingsManager().updateThemeMode(ThemeMode.light),
              ),
              const Divider(),
              ListTile.selectable(
                title: const Text('Dark Mode'),
                leading: const Icon(FluentIcons.clear_night),
                selected: currentTheme == ThemeMode.dark,
                onPressed: () =>
                    SettingsManager().updateThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartDisplaySettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Chart Display')),
      children: [
        const Text('Chart Style'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: ChartStyle.values.asMap().entries.map((entry) {
              final index = entry.key;
              final style = entry.value;
              return Column(
                children: [
                  ListTile.selectable(
                    title: Text(_formatEnumName(style.name)),
                    selected: _settings.chartStyle == style,
                    onPressed: () =>
                        setState(() => _settings.chartStyle = style),
                    leading: const Icon(FluentIcons.chart),
                  ),
                  if (index != ChartStyle.values.length - 1) const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Color Scheme'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: ColorScheme.values.asMap().entries.map((entry) {
              final index = entry.key;
              final scheme = entry.value;
              return Column(
                children: [
                  ListTile.selectable(
                    title: Text(_formatEnumName(scheme.name)),
                    selected: _settings.colorScheme == scheme,
                    onPressed: () =>
                        setState(() => _settings.colorScheme = scheme),
                    leading: const Icon(FluentIcons.color),
                  ),
                  if (index != ColorScheme.values.length - 1) const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Planet Size'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: PlanetSize.values.asMap().entries.map((entry) {
              final index = entry.key;
              final size = entry.value;
              return Column(
                children: [
                  ListTile.selectable(
                    title: Text(_formatEnumName(size.name)),
                    selected: _settings.planetSize == size,
                    onPressed: () =>
                        setState(() => _settings.planetSize = size),
                    leading: const Icon(FluentIcons.size_legacy),
                  ),
                  if (index != PlanetSize.values.length - 1) const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Planet Display')),
      children: [
        const Text('Visibility Options'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle('Show Degrees', _settings.showDegrees, (v) {
                setState(() => _settings.showDegrees = v);
              }),
              _buildListTileToggle(
                'Show Nakshatras',
                _settings.showNakshatras,
                (v) {
                  setState(() => _settings.showNakshatras = v);
                },
              ),
              _buildListTileToggle(
                'Show Retrograde',
                _settings.showRetrograde,
                (v) {
                  setState(() => _settings.showRetrograde = v);
                },
              ),
              _buildListTileToggle('Show Combust', _settings.showCombust, (v) {
                setState(() => _settings.showCombust = v);
              }),
              _buildListTileToggle(
                'Show Exalted/Debilitated',
                _settings.showExaltedDebilitated,
                (v) {
                  setState(() => _settings.showExaltedDebilitated = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Advanced Options'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle(
                'Include Outer Planets (Uranus, Neptune, Pluto)',
                _settings.includeOuterPlanets,
                (v) => setState(() => _settings.includeOuterPlanets = v),
              ),
              _buildListTileToggle(
                'Include Special Aspects (Mars, Jupiter, Saturn)',
                _settings.includeSpecialAspects,
                (v) => setState(() => _settings.includeSpecialAspects = v),
              ),
              _buildListTileToggle(
                'Include Nodes (Rahu/Ketu) in Aspects',
                _settings.includeNodesInAspects,
                (v) => setState(() => _settings.includeNodesInAspects = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHouseSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('House Settings')),
      children: [
        const Text('House System'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: HouseSystem.values.asMap().entries.map((entry) {
              final index = entry.key;
              final system = entry.value;
              return Column(
                children: [
                  ListTile.selectable(
                    title: Text(_formatEnumName(system.name)),
                    selected: _settings.houseSystem == system,
                    onPressed: () =>
                        setState(() => _settings.houseSystem = system),
                  ),
                  if (index != HouseSystem.values.length - 1) const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Display Options'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle('Show Houses', _settings.showHouses, (v) {
                setState(() => _settings.showHouses = v);
              }),
              _buildListTileToggle('Show Signs', _settings.showSigns, (v) {
                setState(() => _settings.showSigns = v);
              }),
              _buildListTileToggle(
                'Show House Cusps',
                _settings.showHouseCusps,
                (v) {
                  setState(() => _settings.showHouseCusps = v);
                },
              ),
              _buildListTileToggle(
                'Show House Numbers',
                _settings.showHouseNumbers,
                (v) {
                  setState(() => _settings.showHouseNumbers = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAyanamsaSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Ayanamsa & Calculation')),
      children: [
        const Text('Ayanamsa System'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: AyanamsaCalculator.systems.asMap().entries.map((entry) {
              final index = entry.key;
              final system = entry.value;
              final isSelected =
                  _settings.ayanamsaSystem.toLowerCase() ==
                  system.name.toLowerCase();

              return Column(
                children: [
                  ListTile.selectable(
                    title: Text(
                      system.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: system.description != system.name
                        ? Text(system.description)
                        : null,
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
                  ),
                  if (index != AyanamsaCalculator.systems.length - 1)
                    const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Node Type (Rahu/Ketu)'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile.selectable(
                title: const Text('Mean Node'),
                subtitle: const Text('Traditional Vedic (recommended)'),
                leading: const Icon(FluentIcons.circle_ring),
                selected: !_settings.useTrueNode,
                onPressed: () => setState(() => _settings.useTrueNode = false),
              ),
              const Divider(),
              ListTile.selectable(
                title: const Text('True Node'),
                subtitle: const Text('More accurate for modern calculations'),
                leading: const Icon(FluentIcons.circle_ring),
                selected: _settings.useTrueNode,
                onPressed: () => setState(() => _settings.useTrueNode = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Position Calculation'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle(
                'Calculate Speed',
                _settings.calculateSpeed,
                (v) => setState(() => _settings.calculateSpeed = v),
              ),
              _buildListTileToggle(
                'Topocentric Positions',
                _settings.useTopocentric,
                (v) => setState(() => _settings.useTopocentric = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('PDF Report Options')),
      children: [
        const Text('Content Selection'),
        const SizedBox(height: 8),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle(
                'Include D-1 Chart',
                _settings.pdfIncludeD1,
                (v) {
                  setState(() => _settings.pdfIncludeD1 = v);
                },
              ),
              _buildListTileToggle(
                'Include D-9 Navamsa',
                _settings.pdfIncludeD9,
                (v) {
                  setState(() => _settings.pdfIncludeD9 = v);
                },
              ),
              _buildListTileToggle('Include Dasha', _settings.pdfIncludeDasha, (
                v,
              ) {
                setState(() => _settings.pdfIncludeDasha = v);
              }),
              _buildListTileToggle(
                'Include KP Analysis',
                _settings.pdfIncludeKP,
                (v) {
                  setState(() => _settings.pdfIncludeKP = v);
                },
              ),
              _buildListTileToggle(
                'Include Other Vargas',
                _settings.pdfIncludeVargas,
                (v) {
                  setState(() => _settings.pdfIncludeVargas = v);
                },
              ),
              _buildListTileToggle(
                'Include Interpretations',
                _settings.pdfIncludeInterpretations,
                (v) {
                  setState(() => _settings.pdfIncludeInterpretations = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashaSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Dasha & Transit')),
      children: [
        const Text('Dasha Settings'),
        const SizedBox(height: 8),
        Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dasha Years to Show: ${_settings.dashaYearsToShow}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _settings.dashaYearsToShow.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                onChanged: (v) {
                  setState(() => _settings.dashaYearsToShow = v.toInt());
                },
                label: '${_settings.dashaYearsToShow} years',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildSimpleToggle('Show Antardasha', _settings.showAntardasha, (
                v,
              ) {
                setState(() => _settings.showAntardasha = v);
              }),
              const SizedBox(height: 12),
              _buildSimpleToggle(
                'Show Pratyantardasha',
                _settings.showPratyantardasha,
                (v) {
                  setState(() => _settings.showPratyantardasha = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Transit Settings'),
        const SizedBox(height: 8),
        Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleToggle('Show Transits', _settings.showTransits, (v) {
                setState(() => _settings.showTransits = v);
              }),
              if (_settings.showTransits) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Days to show: ${_settings.transitDaysToShow}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _settings.transitDaysToShow.toDouble(),
                  min: 7,
                  max: 90,
                  divisions: 11,
                  onChanged: (v) {
                    setState(() => _settings.transitDaysToShow = v.toInt());
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Presets & Reset')),
      children: [
        const Text('Quick Presets'),
        const SizedBox(height: 8),
        Card(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPresetCard(
                'Beginner',
                'Simplified view',
                () => _applyPreset('beginner'),
              ),
              _buildPresetCard(
                'Professional',
                'Full details',
                () => _applyPreset('professional'),
              ),
              _buildPresetCard(
                'Minimal',
                'Clean Layout',
                () => _applyPreset('minimal'),
              ),
              _buildPresetCard(
                'Print-Friendly',
                'PDF Ready',
                () => _applyPreset('print'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Danger Zone'),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(FluentIcons.delete),
            title: const Text('Reset All Settings'),
            subtitle: const Text('Restore default configuration'),
            trailing: Button(
              onPressed: () {
                setState(() => _settings.resetToDefaults());
              },
              child: const Text('Reset'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    String title,
    String subtitle,
    VoidCallback onPressed,
  ) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return SizedBox(
      width: isMobile ? MediaQuery.of(context).size.width / 2 - 40 : 150,
      child: Button(
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: FluentTheme.of(context).typography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTileToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return Column(
      children: [
        ListTile(
          title: Text(label, style: TextStyle(fontSize: isMobile ? 16 : 14)),
          trailing: SizedBox(
            height: isMobile ? 48 : 32,
            child: ToggleSwitch(checked: value, onChanged: onChanged),
          ),
        ),
        const Divider(),
      ],
    );
  }

  // Simple toggle for inside cards without dividers
  Widget _buildSimpleToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: isMobile ? 16 : 14)),
        ),
        SizedBox(
          height: isMobile ? 48 : 32,
          child: ToggleSwitch(checked: value, onChanged: onChanged),
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
