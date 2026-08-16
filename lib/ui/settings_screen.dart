import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jyotish/jyotish.dart' hide HouseSystem, ChartStyle;

import '../core/ayanamsa_calculator.dart';
import '../core/backup_service.dart';
import '../core/chart_customization.dart';
import '../core/settings_provider.dart';
import '../ui/utils/responsive_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late ChartCustomization _settings;
  int _currentIndex = 0;
  bool _initialized = false;

  late final TextEditingController _brandOrgNameController;
  late final TextEditingController _brandOrgTaglineController;
  late final TextEditingController _brandContactInfoController;
  late final TextEditingController _brandPrimaryColorHexController;
  late final TextEditingController _brandAccentColorHexController;
  late final TextEditingController _webdavUrlController;
  late final TextEditingController _webdavUsernameController;
  late final TextEditingController _webdavPasswordController;

  void _initSettingsIfNeeded() {
    if (!_initialized) {
      final currentSettings = ref.read(settingsProvider).value?.chartSettings;
      if (currentSettings != null) {
        _settings = ChartCustomization.fromJson(currentSettings.toJson());
      } else {
        _settings = ChartCustomization();
      }

      _brandOrgNameController = TextEditingController(
        text: _settings.brandOrgName,
      );
      _brandOrgTaglineController = TextEditingController(
        text: _settings.brandOrgTagline,
      );
      _brandContactInfoController = TextEditingController(
        text: _settings.brandContactInfo,
      );
      _brandPrimaryColorHexController = TextEditingController(
        text: _settings.brandPrimaryColorHex,
      );
      _brandAccentColorHexController = TextEditingController(
        text: _settings.brandAccentColorHex,
      );
      _webdavUrlController = TextEditingController(text: _settings.webdavUrl);
      _webdavUsernameController = TextEditingController(
        text: _settings.webdavUsername,
      );
      _webdavPasswordController = TextEditingController(
        text: _settings.webdavPassword,
      );

      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _brandOrgNameController.dispose();
      _brandOrgTaglineController.dispose();
      _brandContactInfoController.dispose();
      _brandPrimaryColorHexController.dispose();
      _brandAccentColorHexController.dispose();
      _webdavUrlController.dispose();
      _webdavUsernameController.dispose();
      _webdavPasswordController.dispose();
    }
    super.dispose();
  }

  void _saveSettings() {
    ref.read(settingsProvider.notifier).updateChartSettings(_settings);
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
    _initSettingsIfNeeded();
    final isMobile = ResponsiveHelper.useMobileLayout(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: NavigationView(
        titleBar: TitleBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile)
                IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              if (isMobile)
                IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
          endHeader: Padding(
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
            PaneItem(
              icon: const Icon(FluentIcons.grid_view_small),
              title: const Text('Vargas'),
              body: _buildVargaSettings(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.database),
              title: const Text('Backup & Sync'),
              body: _buildBackupSyncSettings(),
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
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    final currentTheme =
        ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
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
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.system),
              ),
              const Divider(),
              ListTile.selectable(
                title: const Text('Light Mode'),
                leading: const Icon(FluentIcons.sunny),
                selected: currentTheme == ThemeMode.light,
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.light),
              ),
              const Divider(),
              ListTile.selectable(
                title: const Text('Dark Mode'),
                leading: const Icon(FluentIcons.clear_night),
                selected: currentTheme == ThemeMode.dark,
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.dark),
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
                  system.id.toLowerCase();

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
                      setState(() => _settings.ayanamsaSystem = system.id);
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
        const Text(
          'Brand Identity Builder',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Organization Name',
                      child: TextBox(
                        controller: _brandOrgNameController,
                        placeholder: 'ASTRONAKSH',
                        onChanged: (val) {
                          _settings.brandOrgName = val.trim().isEmpty
                              ? 'ASTRONAKSH'
                              : val;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoLabel(
                      label: 'Organization Tagline',
                      child: TextBox(
                        controller: _brandOrgTaglineController,
                        placeholder: 'Vedic Insights',
                        onChanged: (val) {
                          _settings.brandOrgTagline = val.trim().isEmpty
                              ? 'Vedic Insights'
                              : val;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Contact Info / Copyright Line',
                child: TextBox(
                  controller: _brandContactInfoController,
                  placeholder: '© 2026 AstroNaksh - contact@astronaksh.com',
                  onChanged: (val) {
                    _settings.brandContactInfo = val;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Primary Color (Hex)',
                      child: TextBox(
                        controller: _brandPrimaryColorHexController,
                        placeholder: '#1A237E',
                        onChanged: (val) {
                          _settings.brandPrimaryColorHex = val;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoLabel(
                      label: 'Accent Color (Hex)',
                      child: TextBox(
                        controller: _brandAccentColorHexController,
                        placeholder: '#B8860B',
                        onChanged: (val) {
                          _settings.brandAccentColorHex = val;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Custom Logo Image',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _settings.brandLogoPath.isNotEmpty
                            ? _settings.brandLogoPath
                                  .split(Platform.pathSeparator)
                                  .last
                            : 'No logo selected (using default text brand)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _settings.brandLogoPath.isNotEmpty
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Button(
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          setState(() {
                            _settings.brandLogoPath = result.files.single.path!;
                          });
                        }
                      } catch (e) {
                        debugPrint('Error picking logo: $e');
                      }
                    },
                    child: const Text('Choose File'),
                  ),
                  if (_settings.brandLogoPath.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Button(
                      onPressed: () {
                        setState(() {
                          _settings.brandLogoPath = '';
                        });
                      },
                      child: Icon(FluentIcons.clear, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Page & Layout Formatting',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Page Margins Size'),
                  SizedBox(
                    width: 150,
                    child: ComboBox<String>(
                      value: _settings.pdfPageMargins,
                      items: const [
                        ComboBoxItem(
                          value: 'small',
                          child: Text('Small (16px)'),
                        ),
                        ComboBoxItem(
                          value: 'medium',
                          child: Text('Medium (32px)'),
                        ),
                        ComboBoxItem(
                          value: 'large',
                          child: Text('Large (48px)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings.pdfPageMargins = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Divider(
                style: DividerThemeData(
                  verticalMargin: EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              _buildSimpleToggle(
                'Include Cover Page',
                _settings.pdfIncludeCover,
                (v) => setState(() => _settings.pdfIncludeCover = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Content Selection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTileToggle(
                'Include D-1 Chart',
                _settings.pdfIncludeD1,
                (v) => setState(() => _settings.pdfIncludeD1 = v),
              ),
              _buildListTileToggle(
                'Include D-9 Navamsa',
                _settings.pdfIncludeD9,
                (v) => setState(() => _settings.pdfIncludeD9 = v),
              ),
              _buildListTileToggle(
                'Include Dasha periods',
                _settings.pdfIncludeDasha,
                (v) => setState(() => _settings.pdfIncludeDasha = v),
              ),
              _buildListTileToggle(
                'Include KP Analysis',
                _settings.pdfIncludeKP,
                (v) => setState(() => _settings.pdfIncludeKP = v),
              ),
              _buildListTileToggle(
                'Include Other Vargas',
                _settings.pdfIncludeVargas,
                (v) => setState(() => _settings.pdfIncludeVargas = v),
              ),
              _buildListTileToggle(
                'Include Interpretations',
                _settings.pdfIncludeInterpretations,
                (v) => setState(() => _settings.pdfIncludeInterpretations = v),
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

  Widget _buildVargaSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Divisional Charts (Vargas)')),
      children: [
        const Text(
          'Configure divisional chart calculation methods. These settings determine which algorithms are used when generating the Hora, Drekkana, Navamsha, and Dashamsha charts.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        const Text('Hora (D-2) Calculation Method'),
        const SizedBox(height: 8),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: ComboBox<HoraMethod>(
              value: _settings.horaMethod,
              items: HoraMethod.values.map((method) {
                return ComboBoxItem<HoraMethod>(
                  value: method,
                  child: Text(_formatEnumName(method.name)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _settings.horaMethod = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Drekkana (D-3) Calculation Method'),
        const SizedBox(height: 8),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: ComboBox<DrekkanaMethod>(
              value: _settings.drekkanaMethod,
              items: DrekkanaMethod.values.map((method) {
                return ComboBoxItem<DrekkanaMethod>(
                  value: method,
                  child: Text(_formatEnumName(method.name)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _settings.drekkanaMethod = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Navamsha (D-9) Calculation Method'),
        const SizedBox(height: 8),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: ComboBox<NavamshaMethod>(
              value: _settings.navamshaMethod,
              items: NavamshaMethod.values.map((method) {
                return ComboBoxItem<NavamshaMethod>(
                  value: method,
                  child: Text(_formatEnumName(method.name)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _settings.navamshaMethod = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Dashamsha (D-10) Calculation Method'),
        const SizedBox(height: 8),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: ComboBox<DashamshaMethod>(
              value: _settings.dashamshaMethod,
              items: DashamshaMethod.values.map((method) {
                return ComboBoxItem<DashamshaMethod>(
                  value: method,
                  child: Text(_formatEnumName(method.name)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _settings.dashamshaMethod = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSyncSettings() {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Backup & Synchronization')),
      children: [
        const Text(
          'Local Database Backup & Restore',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safeguard your chart database offline by exporting a local backup file, or restore from a previously exported file.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Button(
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.saveFile(
                          dialogTitle: 'Export Local Backup',
                          fileName: 'astronaksh_backup.db',
                          type: FileType.any,
                        );
                        if (result != null) {
                          final backupService = ref.read(backupServiceProvider);
                          await backupService.backupLocal(result);
                          if (mounted) {
                            unawaited(
                              displayInfoBar(
                                context,
                                builder: (context, close) => InfoBar(
                                  title: const Text('Backup Successful'),
                                  content: Text('Database exported to: $result'),
                                  severity: InfoBarSeverity.success,
                                  onClose: close,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Backup Failed'),
                                content: Text('Error: $e'),
                                severity: InfoBarSeverity.error,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.export),
                        SizedBox(width: 8),
                        Text('Export Local Backup'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          dialogTitle: 'Select Backup File to Restore',
                          type: FileType.any,
                          allowMultiple: false,
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          final sourcePath = result.files.single.path!;
                          final backupService = ref.read(backupServiceProvider);

                          if (!mounted) return;
                          // Show a warning/confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => ContentDialog(
                              title: const Text('Confirm Restore'),
                              content: const Text(
                                'Restoring this backup file will overwrite your current charts database. This cannot be undone. Are you sure you want to proceed?',
                              ),
                              actions: [
                                Button(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Restore'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await backupService.restoreLocal(sourcePath);
                            if (mounted) {
                              unawaited(
                                displayInfoBar(
                                  context,
                                  builder: (context, close) => InfoBar(
                                    title: const Text('Database Restored'),
                                    content: const Text(
                                      'Charts database has been successfully restored.',
                                    ),
                                    severity: InfoBarSeverity.success,
                                    onClose: close,
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Restore Failed'),
                                content: Text('Error: $e'),
                                severity: InfoBarSeverity.error,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.import),
                        SizedBox(width: 8),
                        Text('Restore Local Backup'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Cloud WebDAV Synchronization',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure private cloud WebDAV credentials to sync backups securely across devices. This app is offline-first; sync is only triggered manually.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'WebDAV Target Server URL',
                child: TextBox(
                  controller: _webdavUrlController,
                  placeholder:
                      'https://example.com/remote.php/dav/files/user/AstroNaksh/',
                  onChanged: (val) {
                    _settings.webdavUrl = val.trim();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'WebDAV Username',
                      child: TextBox(
                        controller: _webdavUsernameController,
                        placeholder: 'Username',
                        onChanged: (val) {
                          _settings.webdavUsername = val.trim();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoLabel(
                      label: 'WebDAV Password',
                      child: TextBox(
                        controller: _webdavPasswordController,
                        placeholder: 'Password / App Password',
                        obscureText: true,
                        onChanged: (val) {
                          _settings.webdavPassword = val.trim();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Button(
                    onPressed: () async {
                      try {
                        final backupService = ref.read(backupServiceProvider);
                        final success = await backupService.testWebDAV(
                          _settings.webdavUrl,
                          _settings.webdavUsername,
                          _settings.webdavPassword,
                        );
                        if (success && mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Connection Successful'),
                                content: const Text(
                                  'Successfully connected to WebDAV server!',
                                ),
                                severity: InfoBarSeverity.success,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Connection Failed'),
                                content: Text('Error: $e'),
                                severity: InfoBarSeverity.error,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.cloud_link),
                        SizedBox(width: 8),
                        Text('Test Connection'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () async {
                      try {
                        final backupService = ref.read(backupServiceProvider);
                        await backupService.uploadToWebDAV(
                          _settings.webdavUrl,
                          _settings.webdavUsername,
                          _settings.webdavPassword,
                        );
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Upload Complete'),
                                content: const Text(
                                  'Database backup uploaded to WebDAV server!',
                                ),
                                severity: InfoBarSeverity.success,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Upload Failed'),
                                content: Text('Error: $e'),
                                severity: InfoBarSeverity.error,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.cloud_upload),
                        SizedBox(width: 8),
                        Text('Backup to Cloud'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () async {
                      try {
                        // Confirm restore
                        if (!mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => ContentDialog(
                            title: const Text('Confirm Restore from Cloud'),
                            content: const Text(
                              'Downloading and restoring from the cloud backup will overwrite your local charts database. This cannot be undone. Are you sure you want to proceed?',
                            ),
                            actions: [
                              Button(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Download & Restore'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final backupService = ref.read(backupServiceProvider);
                          await backupService.downloadAndRestoreFromWebDAV(
                            _settings.webdavUrl,
                            _settings.webdavUsername,
                            _settings.webdavPassword,
                          );
                          if (mounted) {
                            unawaited(
                              displayInfoBar(
                                context,
                                builder: (context, close) => InfoBar(
                                  title: const Text('Sync Complete'),
                                  content: const Text(
                                    'Successfully restored database from cloud WebDAV backup!',
                                  ),
                                  severity: InfoBarSeverity.success,
                                  onClose: close,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          unawaited(
                            displayInfoBar(
                              context,
                              builder: (context, close) => InfoBar(
                                title: const Text('Restore Failed'),
                                content: Text('Error: $e'),
                                severity: InfoBarSeverity.error,
                                onClose: close,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.cloud_download),
                        SizedBox(width: 8),
                        Text('Restore from Cloud'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatEnumName(String name) {
    // Convert camelCase to Title Case
    return name
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
