// ignore_for_file: deprecated_member_use, unawaited_futures
import 'package:fluent_ui/fluent_ui.dart' hide Colors, FontWeight;
import 'package:flutter/material.dart' show Colors, FontWeight;

import '../data/city_database.dart';
import 'styles.dart';
import 'utils/responsive_helper.dart';
import 'widgets/vedic_clock_card.dart';

class VedicClockScreen extends StatefulWidget {
  const VedicClockScreen({super.key});

  @override
  State<VedicClockScreen> createState() => _VedicClockScreenState();
}

class _VedicClockScreenState extends State<VedicClockScreen> {
  City _selectedCity = const City(
    name: 'New Delhi',
    state: 'Delhi',
    country: 'India',
    latitude: 28.6139,
    longitude: 77.2090,
    timezone: 'Asia/Kolkata',
  );

  final TextEditingController _citySearchController = TextEditingController();
  List<AutoSuggestBoxItem<City>> _cityItems = [];
  bool _isLoadingLocation = false;
  bool _showLocationEditor = false;

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  void _onCitySearch(String text) {
    if (text.length < 2) {
      if (_cityItems.isNotEmpty) setState(() => _cityItems = []);
      return;
    }

    final results = CityDatabase.searchCities(text).take(10);
    setState(() {
      _cityItems = results.map((city) {
        return AutoSuggestBoxItem<City>(
          value: city,
          label: '${city.name}, ${city.country}',
          onSelected: () {
            setState(() {
              _selectedCity = city;
              _showLocationEditor = false;
              _citySearchController.clear();
              _cityItems = [];
            });
          },
        );
      }).toList();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final city = await CityDatabase.getCurrentLocation();
      if (city != null && mounted) {
        setState(() {
          _selectedCity = city;
          _showLocationEditor = false;
        });
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Location Found'),
            content: Text(city.displayName),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      } else if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Location Error'),
            content: const Text(
              'Could not detect location. Please search manually.',
            ),
            severity: InfoBarSeverity.warning,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Permission Error'),
            content: const Text('Location permission denied or unavailable'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    final horizontal = isMobile ? 16.0 : 24.0;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Vedic Clock'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        commandBar: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.location),
              label: const Text('Change Location'),
              onPressed: () => setState(
                () => _showLocationEditor = !_showLocationEditor,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cosmic hero band: date + location
            _buildHeroBand(context),
            // Animated location editor
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showLocationEditor
                    ? Padding(
                        key: const ValueKey('editor'),
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildLocationEditor(context),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
            const SizedBox(height: 16),
            // The clock card itself
            VedicClockCard(
              key: ValueKey(
                '${_selectedCity.latitude},${_selectedCity.longitude}',
              ),
              latitude: _selectedCity.latitude,
              longitude: _selectedCity.longitude,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBand(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppStyles.primaryColor.withValues(alpha: 0.85),
              AppStyles.primaryColor.withValues(alpha: 0.55),
              const Color(0xFF4B0082).withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FluentIcons.timer,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VEDIC TIME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildLocationPill(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPill(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(
        () => _showLocationEditor = !_showLocationEditor,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.location, size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _selectedCity.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _showLocationEditor
                  ? FluentIcons.chevron_up
                  : FluentIcons.chevron_down,
              size: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationEditor(BuildContext context) {
    final accentColor = FluentTheme.of(context).accentColor;
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.search, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Change Location',
                style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(FluentIcons.chrome_close, size: 12),
                onPressed: () => setState(() => _showLocationEditor = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSuggestBox<City>(
            controller: _citySearchController,
            items: _cityItems,
            onChanged: (text, reason) => _onCitySearch(text),
            placeholder: 'Search for a city…',
            trailingIcon: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(FluentIcons.globe),
                    onPressed: _useCurrentLocation,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                FluentIcons.info,
                size: 11,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Type at least 2 characters, or tap the globe to use your current location.',
                  style: FluentTheme.of(context).typography.caption?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
