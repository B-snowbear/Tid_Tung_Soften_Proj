import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // ⬅️ for context.push
import '../theme.dart';
import '../mock_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final trips = store.trips;
    final money = NumberFormat.currency(locale: 'th_TH', symbol: 'THB ');
    final dateFmt = DateFormat('d MMM y');

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tid Tung',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'by houma',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: TTColors.cC9D7FF),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.account_circle, color: Colors.white),
                        onPressed: () => context.push('/profile'), // ⬅️ go to Profile
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 🔒 Protected Status (สำหรับถ่ายสกรีน 401/200) ─────────
                // ใส่ปุ่มไว้บนสุดของ content ใช้ชั่วคราวสำหรับสปรินต์นี้
                // เสร็จงานแล้วจะลบออกก็ได้
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/protected-status'),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Open Protected Status'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.16),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Trips list ────────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final t = trips[i];
                      final total = t.total == 0 ? 'Total Spent' : money.format(t.total);
                      final range = '${dateFmt.format(t.start)}  –  ${dateFmt.format(t.end)}';
                      return _TripCard(
                        title: t.title,
                        totalSpent: total,
                        date: range,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open ${t.title} (coming soon)')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── FAB: Add Trip ────────────────────────────────────────────────
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Trip: UI coming soon')),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a Trip',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.title,
    required this.totalSpent,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String totalSpent;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C5AA8), Color(0xFF3A66C0)],
          ),
          boxShadow: const [
            BoxShadow(blurRadius: 16, offset: Offset(0, 6), color: Color(0x33000000))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('Total Spent',
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(color: TTColors.cB7EDFF)),
            Text(
              totalSpent,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('Date',
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(color: TTColors.cB7EDFF)),
            Text(date,
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
