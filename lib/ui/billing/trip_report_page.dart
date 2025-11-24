import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/expense_service.dart';
import '../../theme.dart';

class TripReportPage extends StatelessWidget {
  final String tripId;
  final String tripName;

  const TripReportPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Report — $tripName'),
          centerTitle: true,
        ),
        body: FutureBuilder<TripReportData>(
          future: ExpenseService.getTripReport(tripId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final data = snapshot.data!;
            final totalFmt =
                NumberFormat('#,##0.00', 'en_US').format(data.totalThb);

            final hasCategoryData =
                data.byCategory.values.any((v) => v > 0.0);
            final hasPayerData =
                data.byPayer.values.any((v) => v > 0.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Total summary ----------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total expenses',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: TTColors.cB7EDFF),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalFmt THB',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------- Pie chart: spending by category ----------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending by category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasCategoryData)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No data yet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 220,
                            child: Row(
                              children: [
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: _buildCategorySections(
                                        data.byCategory,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _CategoryLegend(byCategory: data.byCategory),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------- Bar chart: contributions per member ----------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contributions per member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasPayerData)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No data yet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 260,
                            child: _PayerBarChart(byPayer: data.byPayer),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------- Member balances list ----------
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount owed / received per member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: data.memberBalances.map((mb) {
                            final balFmt = mb.balance.toStringAsFixed(2);
                            final isPositive = mb.balance >= 0;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                mb.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                (isPositive ? '+ ' : '- ') +
                                    balFmt.replaceFirst('-', '') +
                                    ' THB',
                                style: TextStyle(
                                  color: isPositive
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFF6E40),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- Helpers for PieChart ----------
  List<PieChartSectionData> _buildCategorySections(
      Map<String, double> byCategory) {
    final total = byCategory.values.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) return [];

    final List<Color> palette = [
      const Color(0xFF0DBCF6),
      const Color(0xFF1877F2),
      const Color(0xFFFFD54F),
      const Color(0xFFFF6E40),
      const Color(0xFF66BB6A),
      const Color(0xFFAB47BC),
    ];

    int i = 0;
    return byCategory.entries.map((e) {
      final value = e.value;
      final percent = (value / total) * 100;
      final color = palette[i % palette.length];
      i++;

      return PieChartSectionData(
        color: color,
        value: value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }
}

// ---------- Legend widget ----------
class _CategoryLegend extends StatelessWidget {
  final Map<String, double> byCategory;

  const _CategoryLegend({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = byCategory.values.fold<double>(0.0, (a, b) => a + b);
    final List<Color> palette = [
      const Color(0xFF0DBCF6),
      const Color(0xFF1877F2),
      const Color(0xFFFFD54F),
      const Color(0xFFFF6E40),
      const Color(0xFF66BB6A),
      const Color(0xFFAB47BC),
    ];

    int i = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byCategory.entries.map((e) {
        final color = palette[i % palette.length];
        i++;
        final percent = total > 0 ? (e.value / total) * 100 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${e.key} (${percent.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------- BarChart widget ----------
class _PayerBarChart extends StatelessWidget {
  final Map<String, double> byPayer;

  const _PayerBarChart({required this.byPayer});

  @override
  Widget build(BuildContext context) {
    final payers = byPayer.keys.toList();
    final values = byPayer.values.toList();

    if (payers.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY =
        values.fold<double>(0.0, (prev, v) => v > prev ? v : prev) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= payers.length) {
                  return const SizedBox.shrink();
                }
                final name = payers[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(payers.length, (index) {
          final v = values[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: v,
                color: TTColors.c0DBCF6,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
