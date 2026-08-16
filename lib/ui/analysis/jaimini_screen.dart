import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';

import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../logic/jaimini_service.dart';
import '../../ui/utils/responsive_helper.dart';

class JaiminiScreen extends StatefulWidget {
  const JaiminiScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  State<JaiminiScreen> createState() => _JaiminiScreenState();
}

class _JaiminiScreenState extends State<JaiminiScreen> {
  int _selectedTab = 0;
  int _selectedDashaType = 0; // 0 for Chara, 1 for Narayana
  late final JaiminiAnalysis _analysis;

  @override
  void initState() {
    super.initState();
    final svc = JaiminiAnalysisService();
    _analysis = svc.getJaiminiAnalysis(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        title: Row(
          children: [
            if (!ResponsiveHelper.useMobileLayout(context))
              IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            if (ResponsiveHelper.useMobileLayout(context))
              IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            const SizedBox(width: 8),
            const Text('Jaimini Astrology'),
          ],
        ),
      ),
      content: ScaffoldPage(
        header: PageHeader(title: _buildTabRow()),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _selectedTab == 0
              ? _buildOverviewTab()
              : _selectedTab == 1
              ? _buildArudhaTab()
              : _selectedTab == 2
              ? _buildArgalaTab()
              : _buildDashasTab(),
        ),
      ),
    );
  }

  Widget _buildTabRow() {
    final tabs = [
      (FluentIcons.view_list, 'Overview'),
      (FluentIcons.calendar_agenda, 'Arudha Padas'),
      (FluentIcons.flow, 'Argala'),
      (FluentIcons.timer, 'Jaimini Dashas'),
    ];
    return Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final idx = e.key;
            final (icon, label) = e.value;
            final selected = _selectedTab == idx;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Button(
                style: selected
                    ? ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          FluentTheme.of(context).accentColor.withAlpha(50),
                        ),
                      )
                    : null,
                onPressed: () => setState(() => _selectedTab = idx),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: selected
                          ? FluentTheme.of(context).accentColor
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? FluentTheme.of(context).accentColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // OVERVIEW TAB
  // ──────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final analysis = _analysis;
    final arudha = analysis.arudhaPadas;

    return ListView(
      children: [
        _buildInfoCard(
          icon: FluentIcons.contact,
          title: 'Atmakaraka (AK)',
          subtitle: 'Planet with highest degree — soul indicator',
          value: analysis.atmakaraka.displayName,
          valueColor: FluentTheme.of(context).accentColor,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: FluentIcons.lightbulb,
          title: 'Karakamsa',
          subtitle: 'AK placed in Navamsa — spiritual progress / moksha',
          value: analysis.karakamsa.karakamsaSign.name,
          valueColor: Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildCharaKarakasCard(),
        const SizedBox(height: 12),

        // Key Arudha Padas card
        Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(FluentIcons.calendar_agenda, 'Key Arudha Padas'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniArudhaCard(
                      'Arudha Lagna (AL)',
                      'House 1 — public appearance',
                      arudha.arudhaLagna.sign.name,
                      arudha.arudhaLagna.houseFromLagna,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _miniArudhaCard(
                      'Upapada (UL)',
                      'House 12 — spouse & marriage',
                      arudha.upapada.sign.name,
                      arudha.upapada.houseFromLagna,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Button(
                onPressed: () => setState(() => _selectedTab = 1),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View all 12 Arudha Padas'),
                    SizedBox(width: 4),
                    Icon(FluentIcons.chevron_right, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rashi Drishti summary
        Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(
                FluentIcons.sync_occurence,
                'Rashi Drishti (Sign Aspects)',
              ),
              const SizedBox(height: 8),
              if (analysis.rashiDrishti.isEmpty)
                const Text('No significant Rashi Drishti found')
              else
                ...analysis.rashiDrishti
                    .take(6)
                    .map(
                      (rd) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              FluentIcons.chevron_right_small,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${rd.aspectingSign.name} → ${rd.aspectedSign.name}',
                            ),
                          ],
                        ),
                      ),
                    ),
              if (analysis.rashiDrishti.length > 6)
                Text(
                  '+${analysis.rashiDrishti.length - 6} more…',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharaKarakasCard() {
    final karakas = _analysis.charaKarakas.karakas;

    final karakaLabels = [
      ('Atmakaraka (AK)', 'Soul / Self / Life Purpose'),
      ('Amatyakaraka (AmK)', 'Career / Intellect / Status'),
      ('Bhratrukaraka (BK)', 'Siblings / Mentor / Efforts'),
      ('Matrukaraka (MK)', 'Mother / Home / Property'),
      ('Putrakaraka (PK)', 'Children / Education / Creativity'),
      ('Gnatikaraka (GK)', 'Obstacles / Health / Relatives'),
      ('Darakaraka (DK)', 'Spouse / Partners / Business'),
      ('Apoklima/Pitrukaraka', 'Father / Father\'s lineage'),
    ];

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            FluentIcons.contact_card,
            'Chara Karakas (Planetary Ranks)',
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.2),
            },
            children: [
              const TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Rank',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Degree',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Dignity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...List.generate(karakas.length, (index) {
                final planet = karakas[index];
                final (title, desc) = index < karakaLabels.length
                    ? karakaLabels[index]
                    : ('Apoklima ${index + 1}', 'Special Rank');

                // Get degree and dignity
                var degreeStr = '';
                var dignityStr = '';

                final baseChart = widget.chartData.baseChart;
                final isRahu =
                    planet == Planet.meanNode || planet == Planet.trueNode;

                if (isRahu) {
                  final longitude = baseChart.rahu.longitude;
                  final deg = longitude % 30;
                  degreeStr = '${deg.toStringAsFixed(2)}°';
                  dignityStr = baseChart.rahu.dignity.english;
                } else {
                  final info = baseChart.planets[planet];
                  if (info != null) {
                    final deg = info.longitude % 30;
                    degreeStr = '${deg.toStringAsFixed(2)}°';
                    dignityStr = info.dignity.english;
                  }
                }

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault.withAlpha(50),
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(planet.displayName),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(degreeStr),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(dignityStr),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FluentTheme.of(context).accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: FluentTheme.of(context).accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.withAlpha(160),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniArudhaCard(
    String title,
    String subtitle,
    String sign,
    int houseFromLagna,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(160)),
          ),
          const SizedBox(height: 8),
          Text(
            sign,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            'House $houseFromLagna from Lagna',
            style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(160)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ARUDHA PADAS TAB — all 12
  // ──────────────────────────────────────────────

  Widget _buildArudhaTab() {
    final result = _analysis.arudhaPadas;

    const descMap = {
      1: 'Maya / public image (AL)',
      2: 'Wealth & family image (A2)',
      3: 'Courage & siblings image (A3)',
      4: 'Home & mother image (A4)',
      5: 'Children & intelligence image (A5)',
      6: 'Enemies & service image (A6)',
      7: 'Spouse & partnership image (A7)',
      8: 'Hidden matters & longevity image (A8)',
      9: 'Dharma & fortune image (A9)',
      10: 'Career & actions image (A10)',
      11: 'Gains & social network image (A11)',
      12: 'Spouse / Upapada Lagna (UL)',
    };

    return ListView(
      children: [
        const InfoBar(
          title: Text('Arudha Padas'),
          content: Text(
            'Arudha Padas show how the world perceives each house. '
            'Calculated by counting the same distance from the lord as the lord is from the house.',
          ),
          severity: InfoBarSeverity.info,
        ),
        const SizedBox(height: 16),
        ...List.generate(12, (i) {
          final house = i + 1;
          final pada = result.getPada(house);
          if (pada == null) return const SizedBox.shrink();
          final isKeyPada = house == 1 || house == 12;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isKeyPada
                          ? FluentTheme.of(context).accentColor.withAlpha(40)
                          : Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        pada.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isKeyPada
                              ? FluentTheme.of(context).accentColor
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descMap[house] ?? 'House $house',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Falls in: House ${pada.houseFromLagna} from Lagna',
                          style: TextStyle(
                            color: Colors.grey.withAlpha(160),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pada.sign.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isKeyPada
                              ? FluentTheme.of(context).accentColor
                              : null,
                        ),
                      ),
                      Text(
                        'H${pada.houseFromLagna}',
                        style: TextStyle(
                          color: Colors.grey.withAlpha(160),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // ARGALA TAB — all 12 houses
  // ──────────────────────────────────────────────

  Widget _buildArgalaTab() {
    final argalas = _analysis.argalas;

    return ListView(
      children: [
        const InfoBar(
          title: Text('Argala (Planetary Intervention)'),
          content: Text(
            'Argala occurs when planets in the 2nd, 4th, 11th or 5th house from a given house '
            'intervene in its affairs. Virodha Argala (obstruction) occurs from 12th, 10th, 3rd or 9th.',
          ),
          severity: InfoBarSeverity.info,
        ),
        const SizedBox(height: 16),
        ...List.generate(12, (i) {
          final house = i + 1;
          final list = argalas[house] ?? [];
          final unobstructed = list.where((a) => !a.isObstructed).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Expander(
              initiallyExpanded: house == 1,
              header: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: list.isEmpty
                          ? Colors.grey.withAlpha(20)
                          : unobstructed > 0
                          ? Colors.green.withAlpha(30)
                          : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'H$house',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'House $house',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  _argalaCountBadge(list),
                ],
              ),
              content: list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No Argalas affecting this house.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(children: list.map(_argalaRow).toList()),
            ),
          );
        }),
      ],
    );
  }

  Widget _argalaCountBadge(List<ArgalaInfo> list) {
    if (list.isEmpty) {
      return Text(
        'None',
        style: TextStyle(color: Colors.grey.withAlpha(160), fontSize: 12),
      );
    }
    final unobstructed = list.where((a) => !a.isObstructed).length;
    final obstructed = list.length - unobstructed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unobstructed > 0) _badge('$unobstructed Active', Colors.green),
        if (unobstructed > 0 && obstructed > 0) const SizedBox(width: 4),
        if (obstructed > 0) _badge('$obstructed Virodha', Colors.orange),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _argalaRow(ArgalaInfo argala) {
    final isVirodha = argala.type == ArgalaType.virodha;
    final color = isVirodha ? Colors.orange : Colors.green;
    final icon = isVirodha ? FluentIcons.warning : FluentIcons.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${argala.type.name} from House ${argala.sourceHouse}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Caused by: ${argala.causingPlanets.map((p) => p.displayName).join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (argala.isObstructed && argala.obstructingPlanets.isNotEmpty)
                  Text(
                    'Obstructed by: ${argala.obstructingPlanets.map((p) => p.displayName).join(", ")}',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Str: ${(argala.strength * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                argala.type.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.withAlpha(160),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FluentTheme.of(context).accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: FluentTheme.of(
            context,
          ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDashasTab() {
    final charaDasha = widget.chartData.dashaData.chara;
    final narayanaDasha = widget.chartData.dashaData.narayana;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<int>(
          groupValue: _selectedDashaType,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedDashaType = value);
            }
          },
          child: const Row(
            children: [
              RadioButton<int>(value: 0, content: Text('Chara Dasha')),
              SizedBox(width: 16),
              RadioButton<int>(value: 1, content: Text('Narayana Dasha')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedDashaType == 0
              ? _buildCharaDashaList(charaDasha)
              : _buildNarayanaDashaList(narayanaDasha),
        ),
      ],
    );
  }

  Widget _buildCharaDashaList(CharaDasha dasha) {
    if (dasha.periods.isEmpty) {
      return const Center(child: Text('No Chara Dasha periods available.'));
    }
    final now = DateTime.now();
    return ListView.builder(
      itemCount: dasha.periods.length,
      itemBuilder: (context, index) {
        final period = dasha.periods[index];
        final isActive =
            now.isAfter(period.startDate) && now.isBefore(period.endDate);
        return _buildPeriodRow(
          sign: period.signName,
          lord: period.lord,
          years: period.periodYears,
          start: period.startDate,
          end: period.endDate,
          isActive: isActive,
        );
      },
    );
  }

  Widget _buildNarayanaDashaList(NarayanaDasha dasha) {
    if (dasha.periods.isEmpty) {
      return const Center(child: Text('No Narayana Dasha periods available.'));
    }
    final now = DateTime.now();
    return ListView.builder(
      itemCount: dasha.periods.length,
      itemBuilder: (context, index) {
        final period = dasha.periods[index];
        final isActive =
            now.isAfter(period.startDate) && now.isBefore(period.endDate);
        return _buildPeriodRow(
          sign: period.signName,
          lord: period.lord,
          years: period.periodYears,
          start: period.startDate,
          end: period.endDate,
          isActive: isActive,
        );
      },
    );
  }

  Widget _buildPeriodRow({
    required String sign,
    required String lord,
    required double years,
    required DateTime start,
    required DateTime end,
    required bool isActive,
  }) {
    final theme = FluentTheme.of(context);
    final textStyle = TextStyle(
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      color: isActive ? theme.accentColor : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        backgroundColor: isActive ? theme.accentColor.withAlpha(20) : null,
        borderColor: isActive ? theme.accentColor.withAlpha(80) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sign, style: textStyle.copyWith(fontSize: 16)),
                    Text(
                      'Lord: $lord',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${years.toStringAsFixed(0)} Years',
                  style: textStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppFormatters.formatDate(start)} to',
                      style: textStyle.copyWith(fontSize: 13),
                    ),
                    Text(
                      AppFormatters.formatDate(end),
                      style: textStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
