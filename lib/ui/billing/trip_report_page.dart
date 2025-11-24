import 'package:flutter/material.dart';
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

  String _money(double v) =>
      NumberFormat.currency(symbol: '฿', decimalDigits: 2).format(v);

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
        body: SafeArea(
          child: Column(
            children: [
              // AppBar-like row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Report • $tripName',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: FutureBuilder<TripReport>(
                  future: ExpenseService.getTripReport(tripId),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }
                    if (snap.hasError || snap.data == null) {
                      return Center(
                        child: Text(
                          'Failed to load report',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      );
                    }

                    final report = snap.data!;

                    return ListView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        // 1) Total card
                        _SummaryCard(
                          title: 'Total expenses',
                          value: _money(report.totalExpensesThb),
                        ),
                        const SizedBox(height: 12),

                        // 2) Member contributions
                        Text(
                          'Contributions per member',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ...report.contributions.map(
                          (c) => _RowTile(
                            left: c.name,
                            right: _money(c.totalPaidThb),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3) Owed / received (balances)
                        Text(
                          'Amount owed / received',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ...report.balances.map((b) {
                          final bal = b.balance;
                          final color = bal >= 0
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF6E40);
                          final label = bal >= 0 ? 'to receive' : 'to pay';
                          return _RowTile(
                            left: b.name,
                            right: '${_money(bal.abs())} $label',
                            valueColor: color,
                          );
                        }),
                        const SizedBox(height: 16),

                        // 4) Category breakdown
                        Text(
                          'Spending by category',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ...report.categories.map(
                          (cat) => _RowTile(
                            left: cat.category,
                            right: _money(cat.totalThb),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // TODO: charts section (future step)
                        // คุณสามารถเอา fl_chart มาใช้วาด pie / bar จาก report.categories & report.contributions
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212121).withOpacity(.9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final String left;
  final String right;
  final Color? valueColor;

  const _RowTile({
    required this.left,
    required this.right,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            right,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
