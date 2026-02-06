import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../../logic/planetary_maitri_service.dart';

class PlanetaryMaitriScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const PlanetaryMaitriScreen({super.key, required this.chartData});

  @override
  State<PlanetaryMaitriScreen> createState() => _PlanetaryMaitriScreenState();
}

class _PlanetaryMaitriScreenState extends State<PlanetaryMaitriScreen> {
  int _selectedTab = 0;
  late PlanetaryMaitriData _maitriData;

  @override
  void initState() {
    super.initState();
    _maitriData = PlanetaryMaitriService.getAllMaitriData(widget.chartData.baseChart);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Planetary Maitri (Friendship)'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Natural\n(Naisargika)', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Temporary\n(Tatkalika)', 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Compound\n(Panchadha)', 2),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildNaturalMaitriTab(),
                _buildTemporaryMaitriTab(),
                _buildCompoundMaitriTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    final accentColor = FluentTheme.of(context).accentColor;

    return HoverButton(
      onPressed: () => setState(() => _selectedTab = index),
      builder: (context, states) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : accentColor.withAlpha(50),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : accentColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNaturalMaitriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Natural (Naisargika) Maitri',
            'Permanent planetary relationships based on inherent nature. These relationships are constant across all charts and represent the natural affinity between planets.',
          ),
          const SizedBox(height: 16),
          _buildNaturalFriendshipTable(),
          const SizedBox(height: 24),
          _buildNaturalLegend(),
        ],
      ),
    );
  }

  Widget _buildTemporaryMaitriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Temporary (Tatkalika) Maitri',
            'Relationships based on planetary positions in the birth chart. Planets in 2nd, 3rd, 4th, 10th, 11th, 12th houses from each other become temporary friends. Others are temporary enemies.',
          ),
          const SizedBox(height: 16),
          _buildTemporaryFriendshipTable(),
          const SizedBox(height: 24),
          _buildTemporaryLegend(),
        ],
      ),
    );
  }

  Widget _buildCompoundMaitriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Compound (Panchadha) Maitri',
            'Five-fold relationships combining natural and temporary maitri. This is the final relationship status used for predictions.',
          ),
          const SizedBox(height: 16),
          _buildCompoundFriendshipTable(),
          const SizedBox(height: 24),
          _buildCompoundLegend(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String description) {
    return Card(
      backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.info,
                  color: FluentTheme.of(context).accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaturalFriendshipTable() {
    final planets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Natural Friendship Matrix',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  const DataColumn(
                    label: Text('Planet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...planets.map((p) => DataColumn(
                    label: Text(
                      _getPlanetSymbol(p),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )),
                ],
                rows: planets.map((planet) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        _getPlanetName(planet),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      ...planets.map((other) {
                        if (planet == other) {
                          return const DataCell(
                            Center(child: Text('-', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        final relation = PlanetaryMaitriService.getNaturalRelationship(planet, other);
                        return DataCell(
                          Center(child: _buildRelationshipIcon(relation)),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporaryFriendshipTable() {
    final planets = _maitriData.chart.planets.keys.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporary Friendship Matrix (Chart Specific)',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  const DataColumn(
                    label: Text('Planet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...planets.map((p) => DataColumn(
                    label: Text(
                      _getPlanetSymbol(p),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )),
                ],
                rows: planets.map((planet) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        _getPlanetName(planet),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      ...planets.map((other) {
                        if (planet == other) {
                          return const DataCell(
                            Center(child: Text('-', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        final relation = _maitriData.temporary[planet]?[other] ?? RelationshipType.neutral;
                        return DataCell(
                          Center(child: _buildRelationshipIcon(relation)),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompoundFriendshipTable() {
    final planets = _maitriData.chart.planets.keys.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compound (Panchadha) Friendship Matrix',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  const DataColumn(
                    label: Text('Planet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...planets.map((p) => DataColumn(
                    label: Text(
                      _getPlanetSymbol(p),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )),
                ],
                rows: planets.map((planet) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        _getPlanetName(planet),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      ...planets.map((other) {
                        if (planet == other) {
                          return const DataCell(
                            Center(child: Text('-', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        final relation = _maitriData.compound[planet]?[other] ?? CompoundRelationship.neutral;
                        return DataCell(
                          Center(child: _buildCompoundRelationshipIcon(relation)),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipIcon(RelationshipType type) {
    switch (type) {
      case RelationshipType.friend:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(200),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.check_mark, size: 14, color: Colors.white),
        );
      case RelationshipType.neutral:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(150),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.remove, size: 14, color: Colors.white),
        );
      case RelationshipType.enemy:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(200),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
        );
    }
  }

  Widget _buildCompoundRelationshipIcon(CompoundRelationship type) {
    switch (type) {
      case CompoundRelationship.bestFriend:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.withAlpha(150), width: 2),
          ),
          child: const Icon(FluentIcons.favorite_star, size: 14, color: Colors.white),
        );
      case CompoundRelationship.friend:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(200),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.check_mark, size: 14, color: Colors.white),
        );
      case CompoundRelationship.neutral:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(150),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.remove, size: 14, color: Colors.white),
        );
      case CompoundRelationship.enemy:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(200),
            shape: BoxShape.circle,
          ),
          child: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
        );
    }
  }

  Widget _buildNaturalLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.check_mark, size: 14, color: Colors.white),
              ),
              'Friend (Mitr) - Natural allies that support each other',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.remove, size: 14, color: Colors.white),
              ),
              'Neutral (Sama) - No special relationship',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
              ),
              'Enemy (Satru) - Natural opposition',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporaryLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Temporary Relationships Work',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),
            const Text(
              'Based on house positions from each other:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.check_mark, size: 14, color: Colors.white),
              ),
              'Temporary Friends: 2nd, 3rd, 4th, 10th, 11th, 12th houses',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
              ),
              'Temporary Enemies: 1st, 5th, 6th, 7th, 8th, 9th houses',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompoundLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compound Relationship Legend',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withAlpha(150), width: 2),
                ),
                child: const Icon(FluentIcons.favorite_star, size: 14, color: Colors.white),
              ),
              'Best Friend (Adhi Mitr) - Natural Friend + Temporary Friend',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.check_mark, size: 14, color: Colors.white),
              ),
              'Friend (Mitr) - Natural Friend + Temporary Enemy OR Natural Neutral + Temporary Friend',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.remove, size: 14, color: Colors.white),
              ),
              'Neutral (Sama) - Natural Neutral + Temporary Enemy OR Natural Enemy + Temporary Friend',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
              ),
              'Enemy (Satru) - Natural Enemy + Temporary Enemy',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Widget icon, String text) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _getPlanetName(Planet planet) {
    return planet.name.substring(0, 1).toUpperCase() + planet.name.substring(1);
  }

  String _getPlanetSymbol(Planet planet) {
    switch (planet) {
      case Planet.sun:
        return '☉';
      case Planet.moon:
        return '☽';
      case Planet.mars:
        return '♂';
      case Planet.mercury:
        return '☿';
      case Planet.jupiter:
        return '♃';
      case Planet.venus:
        return '♀';
      case Planet.saturn:
        return '♄';
      case Planet.rahu:
        return '☊';
      case Planet.ketu:
        return '☋';
      default:
        return planet.name.substring(0, 1).toUpperCase();
    }
  }
}
