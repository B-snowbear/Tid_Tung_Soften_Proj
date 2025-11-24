import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme.dart';
import '../../services/expense_service.dart';

class MyPaidHistoryPage extends StatelessWidget {
  const MyPaidHistoryPage({super.key});

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy • HH:mm').format(dt);
  }

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
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'My payments',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: FutureBuilder<List<MyPaidExpenseItem>>(
                  future: ExpenseService.getMyPaidExpenses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading history',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No payments yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final e = items[index];
                        final amt = e.amount.toStringAsFixed(2);
                        final amtThb = e.amountThb.toStringAsFixed(2);

                        return InkWell(
                          onTap: () {
                            // ⭐⭐ ส่งชื่อทริปไปด้วย ให้ TripDetail แสดงชื่อถูกต้อง
                            context.push(
                              '/trip/${e.tripId}',
                              extra: e.tripName,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF212121).withOpacity(.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Trip name
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.tripName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.white70),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // "You paid XXX"
                                Text(
                                  'You paid $amt ${e.currency}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '≈ $amtThb THB',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),

                                if (e.note != null && e.note!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Note: ${e.note}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 6),

                                // Footer: date + settled?
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(e.createdAt),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      e.isSettled ? 'Settled' : 'Pending',
                                      style: TextStyle(
                                        color: e.isSettled
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFFFFD54F),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
