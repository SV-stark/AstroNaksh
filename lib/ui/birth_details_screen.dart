import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../logic/astrology/birth_details_service.dart';
import 'utils/responsive_helper.dart';

class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  BirthDetailsReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final report = await BirthDetailsService.generateReport(widget.chartData);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ScaffoldPage(
        header: PageHeader(
          title: const Text('Birth & Astrological Details'),
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: const Center(child: ProgressRing()),
      );
    }

    final report = _report!;
    final useMobile = ResponsiveHelper.useMobileLayout(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.pop(context);
        },
      },
      child: ScaffoldPage(
        header: PageHeader(
          title: const Text('Birth & Astrological Details'),
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: useMobile ? 16 : 24,
            vertical: 16,
          ),
          children: [
            _buildSection(
              context,
              'Main Details',
              FluentIcons.contact_info,
              report.mainDetails,
              useMobile ? 1 : 2,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Avakahada Chakra',
              FluentIcons.compass_n_w,
              report.avakahadaChakra,
              useMobile ? 1 : 2,
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Panchang Details',
              FluentIcons.calendar,
              report.panchangDetails,
              useMobile ? 1 : 2,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Astronomical Information',
              FluentIcons.analytics_view,
              report.additionalInfo,
              useMobile ? 1 : 2,
              color: Colors.teal,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Map<String, String> data,
    int crossAxisCount, {
    AccentColor? color,
  }) {
    final theme = FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? theme.accentColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          padding: const EdgeInsets.all(0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 5,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final key = data.keys.elementAt(index);
              final value = data.values.elementAt(index);
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.resources.dividerStrokeColorDefault,
                      width: 0.5,
                    ),
                    right: (index % crossAxisCount < crossAxisCount - 1)
                        ? BorderSide(
                            color: theme.resources.dividerStrokeColorDefault,
                            width: 0.5,
                          )
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        key,
                        style: theme.typography.body?.copyWith(
                          color: theme.resources.textFillColorSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Text(' :  '),
                    Expanded(
                      flex: 3,
                      child: Text(
                        value,
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
