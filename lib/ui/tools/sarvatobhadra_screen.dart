import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/core.dart';
import 'package:jyotish/transit.dart';

import '../../core/ephemeris_manager.dart';
import '../../data/models.dart';

class SarvatobhadraScreen extends StatefulWidget {
  const SarvatobhadraScreen({super.key, this.chartData});

  final CompleteChartData? chartData;

  @override
  State<SarvatobhadraScreen> createState() => _SarvatobhadraScreenState();
}

class _SarvatobhadraScreenState extends State<SarvatobhadraScreen> {
  DateTime _transitDate = DateTime.now();
  SarvatobhadraAnalysis? _analysis;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateVedhas();
  }

  Future<void> _calculateVedhas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await EphemerisManager.ensureEphemerisData();

      // If no natal chart passed, calculate default current chart as baseline
      VedicChart baseChart;
      final location = GeographicLocation(
        latitude: widget.chartData?.birthData.location.latitude ?? 28.6139,
        longitude: widget.chartData?.birthData.location.longitude ?? 77.2090,
        timezone: widget.chartData?.birthData.timezone.isNotEmpty == true
            ? widget.chartData!.birthData.timezone
            : 'Asia/Kolkata',
      );

      if (widget.chartData != null) {
        baseChart = widget.chartData!.baseChart;
      } else {
        baseChart = await EphemerisManager.jyotish.calculateVedicChart(
          dateTime: DateTime.now().subtract(const Duration(days: 365 * 25)),
          location: location,
        );
      }

      final transitChart = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: _transitDate,
        location: location,
      );

      final analysis = await EphemerisManager.jyotish.analyzeSarvatobhadra(
        natalChart: baseChart,
        transitPositions: {
          for (final p in Planet.traditionalPlanets)
            p: transitChart.getPlanet(p)?.longitude ?? 0.0,
        },
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Sarvatobhadra Chakra Analysis'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DatePicker(
              selected: _transitDate,
              onChanged: (v) {
                setState(() => _transitDate = v);
                _calculateVedhas();
              },
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _calculateVedhas,
              child: const Text('Recalculate'),
            ),
          ],
        ),
      ),
      children: [
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: ProgressRing(),
            ),
          )
        else if (_errorMessage != null)
          InfoBar(
            title: const Text('Error'),
            content: Text(_errorMessage!),
            severity: InfoBarSeverity.error,
          )
        else if (_analysis != null) ...[
          _buildSummaryOverview(),
          const SizedBox(height: 16),
          _buildVedhaDetailsList(),
        ],
      ],
    );
  }

  Widget _buildSummaryOverview() {
    final favorable = _analysis!.favorableTransits;
    final unfavorable = _analysis!.unfavorableTransits;

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.accept, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Favorable Vedhas (${favorable.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  favorable.isNotEmpty
                      ? favorable.map((p) => p.displayName).join(', ')
                      : 'No major benefic vedha active',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.blocked, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Obstructive Vedhas (${unfavorable.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  unfavorable.isNotEmpty
                      ? unfavorable.map((p) => p.displayName).join(', ')
                      : 'No malefic obstruction',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVedhaDetailsList() {
    final vedhas = _analysis!.transitVedhas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Planetary Vedhas (81-Square Grid)',
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 12),
        ...vedhas.entries.map((entry) {
          final planet = entry.key;
          final vedha = entry.value;
          final isObstructive =
              vedha.severity.name == 'severe' || vedha.severity.name == 'moderate';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Expander(
              header: Row(
                children: [
                  Text(
                    planet.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isObstructive
                          ? Colors.red.withAlpha(40)
                          : Colors.green.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      vedha.severity.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isObstructive ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transiting Nakshatra: ${vedha.transitNakshatra}'),
                  const SizedBox(height: 4),
                  Text('Aspected Nakshatras: ${vedha.aspectedNakshatras.join(", ")}'),
                  const SizedBox(height: 4),
                  if (vedha.aspectsNatalMoon)
                    Text(
                      '• Hits Natal Moon Nakshatra (Janma Nakshatra)',
                      style: TextStyle(color: Colors.orange),
                    ),
                  if (vedha.aspectsNatalAscendant)
                    Text(
                      '• Hits Natal Ascendant Nakshatra',
                      style: TextStyle(color: Colors.orange),
                    ),
                  if (vedha.aspectsNatalSun)
                    Text(
                      '• Hits Natal Sun Nakshatra',
                      style: TextStyle(color: Colors.orange),
                    ),
                  if (!vedha.aspectsNatalMoon &&
                      !vedha.aspectsNatalAscendant &&
                      !vedha.aspectsNatalSun)
                    const Text(
                      '• General field Vedha without critical point affliction',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
