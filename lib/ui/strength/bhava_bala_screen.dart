import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/bhava_bala.dart';

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
    return FutureBuilder<Map<int, BhavaStrength>>(
      future: BhavaBala.calculateBhavaBala(widget.chartData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ScaffoldPage(
            header: PageHeader(title: Text('Bhava Bala (House Strength)')),
            content: Center(child: ProgressRing()),
          );
        }

        if (snapshot.hasError) {
          return ScaffoldPage(
            header: PageHeader(
              title: const Text('Bhava Bala (House Strength)'),
            ),
            content: Center(
              child: InfoBar(
                title: const Text('Calculation Error'),
                content: Text(
                  'Failed to calculate Bhava Bala: ${snapshot.error}',
                ),
                severity: InfoBarSeverity.error,
              ),
            ),
          );
        }

        final bhavaBalaData = snapshot.data ?? {};

        // Convert to list for sorting
        List<MapEntry<int, BhavaStrength>> houses = bhavaBalaData.entries
            .toList();

        if (_sortByStrength) {
          houses.sort(
            (a, b) => b.value.totalStrength.compareTo(a.value.totalStrength),
          );
        } else {
          houses.sort((a, b) => a.key.compareTo(b.key));
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Bhava Bala (House Strength)'),
            leading: IconButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
            commandBar: CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: Icon(
                    _sortByStrength ? FluentIcons.sort : FluentIcons.sort_lines,
                  ),
                  label: Text(
                    _sortByStrength ? 'Sort by Number' : 'Sort by Strength',
                  ),
                  onPressed: () {
                    setState(() {
                      _sortByStrength = !_sortByStrength;
                    });
                  },
                ),
              ],
            ),
          ),
          content: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              // Educational info
              Card(
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(FluentIcons.info, color: Colors.teal),
                          const SizedBox(width: 8),
                          const Text(
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

              const SizedBox(height: 16),

              // House strength grid
              _buildHouseGrid(houses),

              const SizedBox(height: 16),

              // Detailed house cards
              ...houses.map((entry) => _buildHouseCard(entry.key, entry.value)),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHouseGrid(List<MapEntry<int, BhavaStrength>> houses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strength Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: houses.map((entry) {
                final strength = entry.value.totalStrength;
                return Container(
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStrengthColor(strength).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStrengthColor(strength).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'H${entry.key}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        strength.toStringAsFixed(0),
                        style: TextStyle(
                          color: _getStrengthColor(strength),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseCard(int house, BhavaStrength strength) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Expander(
        header: Row(
          children: [
            Icon(_getHouseIcon(house), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'House $house - ${_getHouseName(house)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Strength: ${strength.totalStrength.toStringAsFixed(2)} units',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStrengthColor(strength.totalStrength),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          children: [
            _buildBalaRow(
              'Adhipati Bala (Lord Strength)',
              strength.components['Lord Strength'] ?? 0.0,
            ),
            _buildBalaRow(
              'Dig Bala (Directional)',
              strength.components['Directional'] ?? 0.0,
            ),
            _buildBalaRow(
              'Drishti Bala (Aspect)',
              strength.components['Aspects'] ?? 0.0,
            ),
            _buildBalaRow(
              'Occupant Strength',
              strength.components['Occupants'] ?? 0.0,
            ),
            const Divider(),
            _buildBalaRow(
              'Total Strength',
              strength.totalStrength,
              isTotal: true,
            ),
            const SizedBox(height: 12),
            Text(
              _getHouseSignifications(house),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalaRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? _getStrengthColor(value) : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor(double value) {
    if (value >= 500) return Colors.green;
    if (value >= 400) return Colors.teal;
    if (value >= 300) return Colors.orange;
    return Colors.red;
  }

  String _getHouseName(int house) {
    const names = [
      'Ascendant - Self & Body',
      '2nd House - Wealth & Family',
      '3rd House - Courage & Skills',
      '4th House - Happiness & Home',
      '5th House - Intelligence & Children',
      '6th House - Debts & Diseases',
      '7th House - Partners & Marriage',
      '8th House - Longevity & Transformation',
      '9th House - Fortune & Dharma',
      '10th House - Career & Status',
      '11th House - Gains & Friends',
      '12th House - Losses & Liberation',
    ];
    return names[house - 1];
  }

  IconData _getHouseIcon(int house) {
    // Better mapping:
    switch (house) {
      case 1:
        return FluentIcons.contact;
      case 2:
        return FluentIcons.money;
      case 3:
        return FluentIcons.group;
      case 4:
        return FluentIcons.home;
      case 5:
        return FluentIcons.education; // Intelligence
      case 6:
        return FluentIcons.health;
      case 7:
        return FluentIcons.people; // Partnerships
      case 8:
        return FluentIcons.lightning_bolt; // Sudden events
      case 9:
        return FluentIcons.compass_n_w; // Long journeys/Dharma
      case 10:
        return FluentIcons.calendar; // Placeholder for Career
      case 11:
        return FluentIcons.savings;
      case 12:
        return FluentIcons.sign_out; // Exit/Losses
    }
    return FluentIcons.circle_ring;
  }

  String _getHouseSignifications(int house) {
    const significations = [
      'Physical appearance, health, vitality, overall personality, self-confidence',
      'Accumulated wealth, family, speech, food, early education, values',
      'Younger siblings, courage, short journeys, communication, skills, efforts',
      'Mother, home, property, vehicles, comfort, emotional foundation, education',
      'Children, creativity, romance, speculation, higher intelligence, purva punya',
      'Health, debts, enemies, daily routine, service, pets, competition',
      'Marriage, business partnerships, legal contracts, public image, open enemies',
      'Longevity, secrets, obstacles, sudden changes, research, unearned wealth',
      'Virtue, father, long journeys, higher education, philosophy, guru, merit',
      'Profession, social status, reputation, authority, government, public life',
      'Gains, wishes, elder siblings, social circle, networking, income',
      'Spirituality, liberation, expenditures, losses, hospitals, foreign lands',
    ];
    return significations[house - 1];
  }
}
