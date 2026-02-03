import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/yoga_dosha_analyzer.dart';
import '../widgets/strength_meter.dart';

class YogaDoshaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const YogaDoshaScreen({super.key, required this.chartData});

  @override
  State<YogaDoshaScreen> createState() => _YogaDoshaScreenState();
}

class _YogaDoshaScreenState extends State<YogaDoshaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = YogaDoshaAnalyzer.analyze(widget.chartData);

    // Convert String lists to Map objects for UI
    final yogaStrings = analysis['yogas'] as List;
    final doshasStrings = analysis['doshas'] as List;

    final yogas = yogaStrings
        .map(
          (y) => {
            'name': y.toString(),
            'description': _getYogaDescription(y.toString()),
          },
        )
        .toList();

    final doshas = doshasStrings
        .map(
          (d) => {
            'name': d.toString(),
            'description': _getDoshaDescription(d.toString()),
          },
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoga & Dosha Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Yogas'),
            Tab(text: 'Doshas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab({'yogas': yogas, 'doshas': doshas}),
          _buildYogasTab(yogas),
          _buildDoshasTab(doshas),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(Map<String, dynamic> analysis) {
    final yogas = analysis['yogas'] as List;
    final doshas = analysis['doshas'] as List;

    // Calculate overall score
    final yogaCount = yogas.length;
    final doshaCount = doshas.length;
    final overallScore = ((yogaCount - doshaCount) / 10 * 50 + 50)
        .clamp(0, 100)
        .toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall chart quality
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Overall Chart Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CircularScoreIndicator(
                  score: overallScore,
                  label: _getQualityLabel(overallScore),
                  size: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  _getQualityDescription(overallScore),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Yoga count
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
            title: const Text('Auspicious Yogas'),
            subtitle: Text('$yogaCount yoga(s) detected'),
            trailing: Text(
              '$yogaCount',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),

        // Dosha count
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.warning, color: Colors.white),
            ),
            title: const Text('Doshas/Challenges'),
            subtitle: Text('$doshaCount dosha(s) detected'),
            trailing: Text(
              '$doshaCount',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick highlights
        if (yogas.isNotEmpty) ...[
          const Text(
            'Notable Yogas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...yogas.take(3).map((yoga) => _buildQuickYogaCard(yoga)),
        ],

        if (doshas.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Important Doshas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...doshas.map((dosha) => _buildQuickDoshaCard(dosha)),
        ],
      ],
    );
  }

  Widget _buildYogasTab(List yogas) {
    if (yogas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No major yogas detected',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Group yogas by type
    final groupedYogas = <String, List>{};
    for (var yoga in yogas) {
      final type = _getYogaType(yoga['name']);
      groupedYogas.putIfAbsent(type, () => []);
      groupedYogas[type]!.add(yoga);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yogas are auspicious planetary combinations that bring positive results in various areas of life.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...groupedYogas.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.map((yoga) => _buildYogaCard(yoga)),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDoshasTab(List doshas) {
    if (doshas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              const Text(
                'No major doshas detected!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is a favorable chart without significant afflictions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.orange.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Doshas are challenging combinations. Understanding them helps in planning remedies and precautions.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...doshas.map((dosha) => _buildDoshaCard(dosha)),
      ],
    );
  }

  Widget _buildQuickYogaCard(Map<String, dynamic> yoga) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.stars, color: Colors.amber),
        title: Text(yoga['name']),
        subtitle: Text(
          yoga['description'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        dense: true,
      ),
    );
  }

  Widget _buildQuickDoshaCard(Map<String, dynamic> dosha) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(dosha['name']),
        subtitle: Text(
          dosha['description'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        dense: true,
      ),
    );
  }

  Widget _buildYogaCard(Map<String, dynamic> yoga) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.stars, color: Colors.amber, size: 28),
        title: Text(
          yoga['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _getYogaType(yoga['name']),
          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(yoga['description']),
                const SizedBox(height: 12),
                const Text(
                  'Effects:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(_getYogaEffects(yoga['name'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoshaCard(Map<String, dynamic> dosha) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(
          Icons.warning_amber,
          color: Colors.orange,
          size: 28,
        ),
        title: Text(
          dosha['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Remedial measures recommended',
          style: TextStyle(fontSize: 12, color: Colors.orange),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(dosha['description']),
                const SizedBox(height: 12),
                const Text(
                  'Remedies:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(_getDoshaRemedies(dosha['name'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Average';
    return 'Challenging';
  }

  String _getQualityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent chart with strong positive combinations and minimal afflictions.';
    } else if (score >= 65) {
      return 'This is a very good chart with several beneficial yogas that support success.';
    } else if (score >= 50) {
      return 'This is a good chart with balanced energies and opportunities for growth.';
    } else if (score >= 35) {
      return 'This chart has average potential with both opportunities and challenges to navigate.';
    }
    return 'This chart has some challenges that require conscious effort and remedial measures.';
  }

  String _getYogaType(String name) {
    if (name.contains('Gaja') || name.contains('Raj'))
      return 'Raj Yogas (Power & Status)';
    if (name.contains('Dhana') || name.contains('Lakshmi'))
      return 'Dhana Yogas (Wealth)';
    if (name.contains('Saraswati')) return 'Learning & Wisdom';
    if (name.contains('Neecha Bhanga')) return 'Cancellation Yogas';
    if (name.contains('Parivartana')) return 'Exchange Yogas';
    return 'Special Yogas';
  }

  String _getYogaEffects(String name) {
    // Simplified - in reality this would be more comprehensive
    if (name.contains('Gaja')) {
      return 'Brings wisdom, prosperity, and good reputation. Person may achieve high positions and respect in society.';
    } else if (name.contains('Dhana')) {
      return 'Indicates wealth accumulation and financial prosperity. Good for business and investments.';
    } else if (name.contains('Raj')) {
      return 'Grants authority, leadership qualities, and success in administrative positions.';
    }
    return 'Brings positive results in areas indicated by the planets and houses involved.';
  }

  String _getDoshaRemedies(String name) {
    if (name.contains('Kaal Sarp')) {
      return 'Chant Maha Mrityunjaya mantra, worship Lord Shiva, donate on Saturdays, perform Rahu-Ketu puja.';
    } else if (name.contains('Mangal')) {
      return 'Worship Lord Hanuman, recite Mars mantras, donate red items on Tuesdays, fast on Tuesdays.';
    } else if (name.contains('Pitra')) {
      return 'Perform Shraddha rituals, donate to elders, worship ancestors, feed Brahmins on Amavasya.';
    }
    return 'Consult with an experienced astrologer for personalized remedial measures.';
  }

  String _getYogaDescription(String name) {
    if (name.contains('Gajakesari')) {
      return 'Jupiter in a Kendra (angle) from the Moon creates this auspicious yoga for wisdom and prosperity.';
    } else if (name.contains('Budhaditya')) {
      return 'Sun and Mercury conjunction bestows intelligence, communication skills, and learning ability.';
    } else if (name.contains('Chandra Mangala')) {
      return 'Moon-Mars combination indicates courage, wealth accumulation, and strong determination.';
    } else if (name.contains('Raj Yoga')) {
      return 'Combination of Kendra and Trikona lords brings power, status, and leadership qualities.';
    } else if (name.contains('Dhana')) {
      return 'Wealth-producing combination indicating financial prosperity and material success.';
    } else if (name.contains('Vipreet')) {
      return 'Reversed raja yoga from lords of 6th, 8th, or 12th houses bringing unexpected success.';
    } else if (name.contains('Neecha Bhanga')) {
      return 'Cancellation of planetary debilitation turning weakness into strength unexpectedly.';
    } else if (name.contains('Parivartana')) {
      return 'Mutual exchange of houses between planets creating powerful synergy.';
    } else if (name.contains('Adhi')) {
      return 'Benefic planets surrounding the Moon bringing mental peace and prosperity.';
    } else if (name.contains('Lakshmi')) {
      return 'Venus with 9th lord combination indicating wealth, luxury, and fortune.';
    } else if (name.contains('Saraswati')) {
      return 'Combination of Jupiter, Venus, and Mercury promoting arts, learning, and wisdom.';
    } else if (name.contains('Amala')) {
      return 'Benefic planet in 10th house from Lagna or Moon bringing pure reputation.';
    } else if (name.contains('Parvata')) {
      return 'Benefics in angles without malefic aspects indicating elevated status.';
    } else if (name.contains('Kahala')) {
      return '4th and 9th lords in mutual kendras indicating stubborn determination and valor.';
    } else if (name.contains('Chamara')) {
      return 'Exalted Lagna lord in a kendra bringing royal support and attendants.';
    } else if (name.contains('Sankha')) {
      return '5th and 6th lords in mutual kendras bringing wealth, fame, and prosperity.';
    }
    return 'An auspicious planetary combination bringing positive results in life.';
  }

  String _getDoshaDescription(String name) {
    if (name.contains('Kaal Sarp')) {
      return 'All planets hemmed between Rahu and Ketu creating obstacles and delays but also spiritual growth.';
    } else if (name.contains('Manglik') || name.contains('Kuja')) {
      return 'Mars in sensitive houses (1st, 2nd, 4th, 7th, 8th, or 12th) affecting marriage and relationships.';
    } else if (name.contains('Pitra')) {
      return 'Affliction of Sun or Moon by Rahu, Ketu, or Saturn indicating ancestral karma.';
    } else if (name.contains('Kemadruma')) {
      return 'Moon without support from neighboring houses creating loneliness or mental unrest.';
    }
    return 'A challenging planetary combination requiring awareness and remedial measures.';
  }
}
