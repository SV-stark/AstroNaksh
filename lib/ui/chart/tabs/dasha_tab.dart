import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;

import '../../../data/models.dart';
import '../chart_helpers.dart';

class DashaTab extends StatelessWidget {
  const DashaTab({
    super.key,
    required this.data,
    required this.dashaTabIndex,
    required this.onDashaTabChanged,
  });

  final CompleteChartData data;
  final int dashaTabIndex;
  final ValueChanged<int> onDashaTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for selecting dasha type
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildDashaTabButton(
                context: context,
                label: 'Vimshottari',
                icon: FluentIcons.timeline_progress,
                index: 0,
              ),
              const SizedBox(width: 8),
              _buildDashaTabButton(
                context: context,
                label: 'Yogini',
                icon: FluentIcons.flow,
                index: 1,
              ),
              const SizedBox(width: 8),
              _buildDashaTabButton(
                context: context,
                label: 'Chara',
                icon: FluentIcons.rotate,
                index: 2,
              ),
              const SizedBox(width: 8),
              _buildDashaTabButton(
                context: context,
                label: 'Ashtottari',
                icon: FluentIcons.table,
                index: 3,
              ),
              const SizedBox(width: 8),
              _buildDashaTabButton(
                context: context,
                label: 'Kalachakra',
                icon: FluentIcons.sync,
                index: 4,
              ),
              const SizedBox(width: 8),
              _buildDashaTabButton(
                context: context,
                label: 'Narayana',
                icon: FluentIcons.sync_occurence,
                index: 5,
              ),
            ],
          ),
        ),
        const Divider(),
        // Content based on selected tab
        Expanded(
          child: IndexedStack(
            index: dashaTabIndex,
            children: [
              _buildVimshottariDashaContent(
                context,
                data.dashaData.vimshottari,
              ),
              _buildYoginiDashaContent(context, data.dashaData.yogini),
              _buildCharaDashaContent(context, data.dashaData.chara),
              _buildAshtottariDashaContent(context, data.dashaData.ashtottari),
              _buildKalachakraDashaContent(context, data.dashaData.kalachakra),
              _buildNarayanaDashaContent(context, data.dashaData.narayana),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashaTabButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = dashaTabIndex == index;
    final accentColor = FluentTheme.of(context).accentColor;

    return HoverButton(
      onPressed: () => onDashaTabChanged(index),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? m.Colors.white : accentColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? m.Colors.white : accentColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVimshottariDashaContent(
    BuildContext context,
    VimshottariDasha dasha,
  ) {
    final now = DateTime.now();
    final currentMahaIndex = dasha.mahadashas.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Lord: ${dasha.birthLord}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Balance at Birth: ${dasha.formattedBalanceAtBirth}',
                          style: const TextStyle(
                            color: m.Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mahadasha Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mahadasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Duration',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.mahadashas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final maha = entry.value;
                    final isCurrent = index == currentMahaIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? m.Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Expander(
                        initiallyExpanded: isCurrent,
                        header: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  if (isCurrent)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    maha.lord,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? FluentTheme.of(context).accentColor
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${ChartHelpers.formatDate(maha.startDate)} - ${ChartHelpers.formatDate(maha.endDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                maha.formattedPeriod,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Antardashas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ...maha.antardashas.map((antar) {
                              final isCurrentAntar =
                                  isCurrent &&
                                  now.isAfter(antar.startDate) &&
                                  now.isBefore(antar.endDate);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentAntar
                                      ? FluentTheme.of(
                                          context,
                                        ).accentColor.withAlpha(20)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        antar.lord,
                                        style: TextStyle(
                                          fontWeight: isCurrentAntar
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${antar.periodYears.toStringAsFixed(2)}y',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${ChartHelpers.formatDate(antar.startDate)} - ${ChartHelpers.formatDate(antar.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: m.Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoginiDashaContent(BuildContext context, YoginiDasha dasha) {
    final now = DateTime.now();
    final currentIndex = dasha.mahadashas.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Yogini: ${dasha.startYogini}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Total 8 Yogini periods (36 years cycle)',
                          style: TextStyle(color: m.Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Yogini Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yogini Dasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Yogini',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Years',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.mahadashas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final maha = entry.value;
                    final isCurrent = index == currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? m.Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Expander(
                        initiallyExpanded: isCurrent,
                        header: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  if (isCurrent)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    maha.name,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? FluentTheme.of(context).accentColor
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                maha.lord,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${ChartHelpers.formatDate(maha.startDate)} - ${ChartHelpers.formatDate(maha.endDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${maha.periodYears}y',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Antardashas (Sub-periods):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ...maha.antardashas.map((antar) {
                              final isCurrentAntar =
                                  now.isAfter(antar.startDate) &&
                                  now.isBefore(antar.endDate);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentAntar
                                      ? FluentTheme.of(
                                          context,
                                        ).accentColor.withAlpha(20)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Expander(
                                  initiallyExpanded: isCurrentAntar,
                                  header: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          antar.name,
                                          style: TextStyle(
                                            fontWeight: isCurrentAntar
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${ChartHelpers.formatDate(antar.startDate)} - ${ChartHelpers.formatDate(antar.endDate)}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Pratyantardashas (Sub-sub-periods):',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      ...antar.pratyantardashas.map((pratyan) {
                                        final isCurrentPratyan =
                                            now.isAfter(pratyan.startDate) &&
                                            now.isBefore(pratyan.endDate);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 4,
                                          ),
                                          color: isCurrentPratyan
                                              ? FluentTheme.of(
                                                  context,
                                                ).accentColor.withAlpha(10)
                                              : null,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '  - ${pratyan.name}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: isCurrentPratyan
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  '${ChartHelpers.formatDate(pratyan.startDate)} - ${ChartHelpers.formatDate(pratyan.endDate)}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: m.Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharaDashaContent(BuildContext context, CharaDasha dasha) {
    final now = DateTime.now();
    final currentIndex = dasha.periods.indexWhere(
      (p) => now.isAfter(p.startDate) && now.isBefore(p.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Sign: ${ChartHelpers.getSignName(dasha.startSign)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Jaimini Chara Dasha System',
                          style: TextStyle(color: m.Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chara Dasha Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chara Dasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Sign',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Years',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.periods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final period = entry.value;
                    final isCurrent = index == currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? m.Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                if (isCurrent)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: FluentTheme.of(
                                        context,
                                      ).accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  period.signName,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? FluentTheme.of(context).accentColor
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              period.lord,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${ChartHelpers.formatDate(period.startDate)} - ${ChartHelpers.formatDate(period.endDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${period.periodYears.toInt()}y',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAshtottariDashaContent(
    BuildContext context,
    AshtottariDasha dasha,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Nakshatra: ${dasha.birthNakshatra}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Balance of First Dasha: ${dasha.balanceOfFirstDasha.toStringAsFixed(2)} years',
                          style: const TextStyle(
                            color: m.Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanetBasedDashaContent(
            context: context,
            title: 'Ashtottari Dasha Periods',
            periods: dasha.mahadashas
                .map(
                  (p) => _DashaPeriodAdapter(
                    lord: p.lordName,
                    startDate: p.startDate,
                    endDate: p.endDate,
                    periodYears: p.periodYears,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKalachakraDashaContent(
    BuildContext context,
    KalachakraDasha dasha,
  ) {
    return _buildSignBasedDashaContent(
      context: context,
      title: 'Kalachakra Dasha Periods',
      periods: dasha.mahadashas
          .map(
            (p) => _DashaPeriodAdapter(
              signName: p.signName,
              startDate: p.startDate,
              endDate: p.endDate,
              periodYears: p.periodYears,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNarayanaDashaContent(BuildContext context, NarayanaDasha dasha) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Narayana Dasha (Jaimini)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '12-sign cycle based on lagna/7th house strength',
                          style: TextStyle(color: m.Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildSignBasedDashaContent(
            context: context,
            title: 'Narayana Dasha Periods',
            periods: dasha.periods
                .map(
                  (p) => _DashaPeriodAdapter(
                    signName: p.signName,
                    lord: p.lord,
                    startDate: p.startDate,
                    endDate: p.endDate,
                    periodYears: p.periodYears,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetBasedDashaContent({
    required BuildContext context,
    required String title,
    required List<_DashaPeriodAdapter> periods,
  }) {
    final now = DateTime.now();
    final currentIndex = periods.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FluentTheme.of(context).typography.subtitle),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: FluentTheme.of(context).accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Lord',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Period',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Duration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...periods.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final isCurrent = index == currentIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? FluentTheme.of(context).accentColor.withAlpha(40)
                      : (index % 2 == 0 ? m.Colors.grey.withAlpha(10) : null),
                  borderRadius: BorderRadius.circular(4),
                  border: isCurrent
                      ? Border.all(
                          color: FluentTheme.of(context).accentColor,
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (isCurrent)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: FluentTheme.of(context).accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            p.lord ?? '--',
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCurrent
                                  ? FluentTheme.of(context).accentColor
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${ChartHelpers.formatDate(p.startDate)} - ${ChartHelpers.formatDate(p.endDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${p.periodYears.toStringAsFixed(1)}y',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSignBasedDashaContent({
    required BuildContext context,
    required String title,
    required List<_DashaPeriodAdapter> periods,
  }) {
    final now = DateTime.now();
    final currentIndex = periods.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FluentTheme.of(context).typography.subtitle),
              const SizedBox(height: 12),
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Sign',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Lord',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Period',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Duration',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Table Rows
              ...periods.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                final isCurrent = index == currentIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? FluentTheme.of(context).accentColor.withAlpha(40)
                        : (index % 2 == 0 ? m.Colors.grey.withAlpha(10) : null),
                    borderRadius: BorderRadius.circular(4),
                    border: isCurrent
                        ? Border.all(
                            color: FluentTheme.of(context).accentColor,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            if (isCurrent)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: FluentTheme.of(context).accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              p.signName ?? '--',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? FluentTheme.of(context).accentColor
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.lord ?? '--',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${ChartHelpers.formatDate(p.startDate)} - ${ChartHelpers.formatDate(p.endDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${p.periodYears.toStringAsFixed(1)}y',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashaPeriodAdapter {
  _DashaPeriodAdapter({
    this.signName,
    this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final String? signName;
  final String? lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}
