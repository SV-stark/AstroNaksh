import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/bhava_bala.dart';
import '../widgets/strength_meter.dart';

class BhavaBalaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const BhavaBalaScreen({super.key, required this.chartData});

  @override
  State<BhavaBalaScreen> createState() => _BhavaBalaScreenState();
}

class _BhavaBalaScreenState extends State<BhavaBalaScreen> {
  bool _sortByStrength = true;

  @override
  Widget build(BuildContext context) {
    final bhavaBalaData = BhavaBala.calculateBhavaBala(widget.chartData);

    // Convert to list for sorting
    List<MapEntry<int, BhavaStrength>> houses = bhavaBalaData.entries.toList();

    if (_sortByStrength) {
      houses.sort(
        (a, b) => b.value.totalStrength.compareTo(a.value.totalStrength),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhava Bala (House Strength)'),
        actions: [
          IconButton(
            icon: Icon(_sortByStrength ? Icons.sort : Icons.sort_by_alpha),
            tooltip: _sortByStrength ? 'Sort by Number' : 'Sort by Strength',
            onPressed: () {
              setState(() {
                _sortByStrength = !_sortByStrength;
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Educational info
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'About Bhava Bala',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bhava Bala measures house strength based on lord strength, directional power, '
                    'aspects received, and occupying planets. Stronger houses deliver better results '
                    'in their areas of life.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // House strength grid
          _buildHouseGrid(houses),

          // Detailed house cards
          ...houses.map((entry) => _buildHouseCard(entry.key, entry.value)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHouseGrid(List<MapEntry<int, BhavaStrength>> houses) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'House Strength Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final house = houses[index].key;
                final strength = houses[index].value;
                return _buildHouseGridItem(house, strength);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseGridItem(int house, BhavaStrength strength) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStrengthColor(strength.totalStrength),
            _getStrengthColor(strength.totalStrength).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getHouseNumber(house),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          GradeBadge(grade: strength.grade, size: 28),
          const SizedBox(height: 4),
          Text(
            strength.totalStrength.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCard(int house, BhavaStrength strength) {
    return ExpandableInfoCard(
      title: _getHouseName(house),
      summary: strength.interpretation,
      icon: _getHouseIcon(house),
      color: _getStrengthColor(strength.totalStrength),
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total strength
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Strength:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  GradeBadge(grade: strength.grade),
                  const SizedBox(width: 8),
                  Text(
                    strength.totalStrength.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Strength components
          const Text(
            'Strength Components:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...strength.components.entries.map((comp) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: StrengthMeter(
                value: (comp.value / 60) * 100,
                label: comp.key,
                showPercentage: false,
              ),
            );
          }),
          const SizedBox(height: 16),

          // House significations
          _buildSignifications(house),
        ],
      ),
    );
  }

  Widget _buildSignifications(int house) {
    final significations = _getHouseSignifications(house);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Significations:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(significations, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _getHouseNumber(int house) {
    const ordinals = [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '5th',
      '6th',
      '7th',
      '8th',
      '9th',
      '10th',
      '11th',
      '12th',
    ];
    return ordinals[house - 1];
  }

  String _getHouseName(int house) {
    const names = [
      '1st House - Self & Personality',
      '2nd House - Wealth & Family',
      '3rd House - Siblings & Courage',
      '4th House - Home & Mother',
      '5th House - Children & Intelligence',
      '6th House - Health & Enemies',
      '7th House - Spouse & Partnerships',
      '8th House - Longevity & Transformation',
      '9th House - Fortune & Dharma',
      '10th House - Career & Status',
      '11th House - Gains & Friends',
      '12th House - Losses & Liberation',
    ];
    return names[house - 1];
  }

  IconData _getHouseIcon(int house) {
    const icons = [
      Icons.person,
      Icons.account_balance_wallet,
      Icons.groups,
      Icons.home,
      Icons.child_care,
      Icons.healing,
      Icons.favorite,
      Icons.transform,
      Icons.star,
      Icons.work,
      Icons.attach_money,
      Icons.spa,
    ];
    return icons[house - 1];
  }

  String _getHouseSignifications(int house) {
    const significations = [
      'Physical appearance, health, vitality, overall personality, self-confidence',
      'Accumulated wealth, family, speech, food, early education, values',
      'Younger siblings, courage, short journeys, communication, skills, efforts',
      'Mother, home, property, vehicles, comfort, emotional foundation, education',
      'Children, creativity, romance, intelligence, speculation, past life merits',
      'Enemies, diseases, debts, obstacles, competition, daily work, service',
      'Spouse, marriage, partnerships, business relationships, public image',
      'Longevity, sudden events, occult, inheritance, transformation, research',
      'Father, guru, fortune, higher learning, religion, long journeys, dharma',
      'Career, profession, status, authority, reputation, achievements, karma',
      'Income, gains, fulfillment of desires, elder siblings, friends, social circle',
      'Losses, expenses, foreign lands, spirituality, liberation, isolation, sleep',
    ];
    return significations[house - 1];
  }

  Color _getStrengthColor(double strength) {
    if (strength >= 80) return Colors.green;
    if (strength >= 60) return Colors.lightGreen;
    if (strength >= 40) return Colors.orange;
    if (strength >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}
