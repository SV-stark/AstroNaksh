// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'package:fluent_ui/fluent_ui.dart' hide Colors, FontWeight;
import 'package:flutter/material.dart' show Colors, FontWeight;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database.dart';
import '../data/models.dart';
import '../data/sample_charts.dart';
import '../ui/utils/responsive_helper.dart';
import 'horary/horary_input_screen.dart';
import 'styles.dart';
import 'widgets/panchang_daily_widget.dart';
import 'widgets/vedic_clock_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Chart> _charts = [];
  List<Chart> _filteredCharts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCharts());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final charts = await db.select(db.charts).get();
      debugPrint('DEBUG: Loaded ${charts.length} charts from database');
      setState(() {
        _charts = charts;
        _filteredCharts = charts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DEBUG ERROR loading charts: $e');
      setState(() {
        _charts = [];
        _filteredCharts = [];
        _isLoading = false;
      });
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error Loading Charts'),
            content: Text('Failed to load saved charts: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCharts = _charts.where((chart) {
        final name = (chart.name ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _openChart(Chart chart) {
    try {
      final birthData = BirthData(
        dateTime: DateTime.parse(chart.birthTime!),
        location: Location(
          latitude: chart.latitude!,
          longitude: chart.longitude!,
        ),
        name: chart.name ?? '',
        place: chart.locationName ?? '',
        timezone: chart.timezone ?? '',
      );
      context.push('/chart', extra: birthData);
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Error opening chart'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: ScaffoldPage(
        header: PageHeader(
          title: const Text('AstroNaksh'),
          commandBar: CommandBar(
            overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('New Chart'),
                onPressed: () async {
                  await context.push('/input');
                  _loadCharts();
                },
              ),
            ],
            secondaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.settings),
                label: const Text('Settings'),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
        content: CustomScrollView(
          slivers: [
            // Today's Sky Dashboard Widget
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.useMobileLayout(context) ? 16 : 24,
                24,
                ResponsiveHelper.useMobileLayout(context) ? 16 : 24,
                8,
              ),
              sliver: const SliverToBoxAdapter(child: PanchangDailyWidget()),
            ),

            // Vedic Clock Card
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.useMobileLayout(context) ? 16 : 24,
                8,
                ResponsiveHelper.useMobileLayout(context) ? 16 : 24,
                8,
              ),
              sliver: const SliverToBoxAdapter(child: VedicClockCard()),
            ),

            // Dashboard Quick Actions
            SliverPadding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 16),
                    HoverButton(
                      onPressed: () async {
                        await context.push('/input');
                        _loadCharts();
                      },
                      builder: (context, states) {
                        return Card(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppStyles.primaryColor,
                                  AppStyles.primaryColor.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 20,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    FluentIcons.add,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Create New Chart',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Calculate birth data and explore detailed horoscopes',
                                        style: TextStyle(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  FluentIcons.chevron_right,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: ResponsiveHelper.useMobileLayout(context)
                          ? 2
                          : 3,
                      mainAxisSpacing: ResponsiveHelper.useMobileLayout(context)
                          ? 16
                          : 12,
                      crossAxisSpacing:
                          ResponsiveHelper.useMobileLayout(context) ? 16 : 12,
                      childAspectRatio:
                          ResponsiveHelper.getGridChildAspectRatio(context) *
                          (ResponsiveHelper.useMobileLayout(context)
                              ? 1.0
                              : 1.5),
                      children: [
                        _buildQuickAction(
                          icon: FluentIcons.heart_fill,
                          title: 'Compare',
                          subtitle: 'Chart compatibility',
                          color: Colors.purple,
                          onTap: () {
                            context.push('/comparison');
                          },
                        ),
                        _buildQuickAction(
                          icon: FluentIcons.calendar,
                          title: 'Panchang',
                          subtitle: 'Daily almanac',
                          color: Colors.orange,
                          onTap: () {
                            context.push('/panchang');
                          },
                        ),
                        _buildQuickAction(
                          icon: FluentIcons.chat,
                          title: 'Horary (Prashna)',
                          subtitle: 'Ask a question',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              FluentPageRoute(
                                builder: (_) => const HoraryInputScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          icon: FluentIcons.diamond,
                          title: 'Muhurta Finder',
                          subtitle: 'Auspicious times',
                          color: Colors.blue,
                          onTap: () {
                            context.push('/muhurta');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.useMobileLayout(context)
                    ? 16.0
                    : 24.0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Recent Charts',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: ResponsiveHelper.useMobileLayout(context)
                          ? 200
                          : 250,
                      height: ResponsiveHelper.useMobileLayout(context)
                          ? 44
                          : 36,
                      child: TextBox(
                        controller: _searchController,
                        placeholder: 'Search...',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(FluentIcons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: ProgressRing()),
                ),
              )
            else
              _filteredCharts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FluentIcons.contact_list,
                                size: 64,
                                color: Colors.grey.withAlpha(128),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No saved charts yet',
                                style: FluentTheme.of(context).typography.title,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first chart to get started',
                                style: TextStyle(
                                  color: Colors.grey.withAlpha(150),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: () async {
                                  await context.push('/input');
                                  _loadCharts();
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(FluentIcons.add),
                                    SizedBox(width: 8),
                                    Text('Create New Chart'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                'Or explore famous charts:',
                                style: FluentTheme.of(
                                  context,
                                ).typography.subtitle,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 400,
                                child: Column(
                                  children: SampleCharts.samples
                                      .map(
                                        (sample) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Card(
                                            padding: EdgeInsets.zero,
                                            child: ListTile.selectable(
                                              leading: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  FluentIcons.contact_info,
                                                  color: AppStyles.primaryColor,
                                                ),
                                              ),
                                              title: Text(
                                                sample.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(sample.place),
                                              onPressed: () {
                                                context.push(
                                                  '/chart',
                                                  extra: sample,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.useMobileLayout(context)
                            ? 16.0
                            : 24.0,
                      ),
                      sliver: SliverList.builder(
                        itemCount: _filteredCharts.length,
                        itemBuilder: (context, index) {
                          final chart = _filteredCharts[index];
                          final isMobile = ResponsiveHelper.useMobileLayout(
                            context,
                          );
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 8 : 4,
                            ),
                            child: Card(
                              padding: EdgeInsets.zero,
                              child: ListTile.selectable(
                                onPressed: () => _openChart(chart),
                                leading: Container(
                                  width: isMobile ? 48 : 40,
                                  height: isMobile ? 48 : 40,
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppStyles.primaryColor.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    FluentIcons.contact,
                                    color: AppStyles.primaryColor,
                                    size: isMobile ? 24 : 20,
                                  ),
                                ),
                                title: Text(
                                  chart.name ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 16 : 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_formatDateTime(chart.birthTime)}'
                                  '${chart.locationName != null ? ' • ${chart.locationName}' : ''}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 12,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: isMobile ? 48 : 40,
                                  height: isMobile ? 48 : 40,
                                  child: IconButton(
                                    icon: Icon(
                                      FluentIcons.delete,
                                      color: Colors.red,
                                      size: isMobile ? 24 : 16,
                                    ),
                                    onPressed: () async {
                                      final db = ref.read(databaseProvider);
                                      await (db.delete(db.charts)..where(
                                            (t) => t.id.equals(chart.id),
                                          ))
                                          .go();
                                      _loadCharts();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return Card(
      key: key,
      padding: EdgeInsets.all(isMobile ? 12 : 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: isMobile ? 48 : 40,
              height: isMobile ? 48 : 40,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isMobile ? 24 : 20),
            ),
            SizedBox(width: isMobile ? 12 : 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 11,
                      color: Colors.grey.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FluentIcons.chevron_right,
              color: Colors.grey.withAlpha(180),
              size: isMobile ? 20 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
