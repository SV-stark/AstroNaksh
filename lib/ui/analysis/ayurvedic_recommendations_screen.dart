import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/ayurveda_service.dart';
import '../styles.dart';

class AyurvedicRecommendationsScreen extends StatefulWidget {
  const AyurvedicRecommendationsScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  State<AyurvedicRecommendationsScreen> createState() =>
      _AyurvedicRecommendationsScreenState();
}

class _AyurvedicRecommendationsScreenState
    extends State<AyurvedicRecommendationsScreen> {
  final AyurvedaService _ayurvedaService = AyurvedaService();
  late AyurvedicProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = _ayurvedaService.calculateAyurvedicProfile(widget.chartData);
  }

  Widget _buildProgressBar({
    required String label,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.15),
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items, Color bulletColor) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: bulletColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Ayurvedic Recommendations'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              backgroundColor: AppStyles.primaryColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      FluentIcons.flower,
                      color: AppStyles.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prakriti Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Ayurvedic constitution is determined by the zodiac element values of the Ascendant (Lagna), Sun, Moon, and other planets at the moment of your birth.',
                            style: FluentTheme.of(context).typography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dosha Distribution Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Dosha Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressBar(
                      label: 'Vata (Air & Ether)',
                      percentage: _profile.vataPercentage,
                      color: const Color(0xFF2196F3), // Blue
                    ),
                    _buildProgressBar(
                      label: 'Pitta (Fire & Water)',
                      percentage: _profile.pittaPercentage,
                      color: const Color(0xFFF44336), // Red
                    ),
                    _buildProgressBar(
                      label: 'Kapha (Earth & Water)',
                      percentage: _profile.kaphaPercentage,
                      color: const Color(0xFF4CAF50), // Green
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Dominant Constitution: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _profile.dominantDosha,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations Tabs
            Expander(
              header: const Row(
                children: [
                  Icon(FluentIcons.eat_drink, color: Color(0xFF4CAF50)),
                  SizedBox(width: 12),
                  Text(
                    'Dietary Guidelines (Favor)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: _buildBulletList(
                _profile.dietaryRecommendations,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 12),

            Expander(
              header: const Row(
                children: [
                  Icon(FluentIcons.blocked2, color: Color(0xFFF44336)),
                  SizedBox(width: 12),
                  Text(
                    'Foods to Avoid / Limit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: _buildBulletList(
                _profile.avoidedFoods,
                const Color(0xFFF44336),
              ),
            ),
            const SizedBox(height: 12),

            Expander(
              header: const Row(
                children: [
                  Icon(FluentIcons.calendar, color: Color(0xFF2196F3)),
                  SizedBox(width: 12),
                  Text(
                    'Lifestyle & Daily Routine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: _buildBulletList(
                _profile.lifestyleRecommendations,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 12),

            Expander(
              header: const Row(
                children: [
                  Icon(FluentIcons.flower, color: AppStyles.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'Recommended Herbs & Remedies',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: _buildBulletList(
                _profile.recommendedHerbs,
                AppStyles.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
