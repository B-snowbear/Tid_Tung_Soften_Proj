import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/expense_service.dart';

class ExpenseHistoryPage extends StatefulWidget {
  final String tripId;
  final String tripName;

  const ExpenseHistoryPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  late Future<List<ExpenseItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExpenseService.getTripExpenses(widget.tripId);
  }

  void _reload() {
    setState(() {
      _future = ExpenseService.getTripExpenses(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM y HH:mm');
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,

      // ----------- AppBar แบบ BalancePage -----------
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5AA8),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text('History • ${widget.tripName}'),
      ),

      body: FutureBuilder<List<ExpenseItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No expenses yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              final createdStr = dateFmt.format(e.createdAt);
              final isPayer = currentUserId != null && currentUserId == e.payerId;

              return Card(
                color: const Color(0xFF202124),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    '${e.payerName} paid ${e.amount.toStringAsFixed(2)} ${e.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '≈ ${e.amountThb.toStringAsFixed(2)} THB',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (e.note != null && e.note!.isNotEmpty)
                        Text(
                          'Note: ${e.note}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      Text(
                        createdStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),

                  // ----------- Menu สำหรับคนที่สร้างบิลเท่านั้น -----------
                  trailing: isPayer
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle') {
                              await ExpenseService.setExpenseSettled(
                                e.id,
                                !e.isSettled,
                              );
                              _reload();
                            } else if (value == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete bill'),
                                  content: const Text(
                                      'Are you sure you want to delete this bill?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ExpenseService.deleteExpense(e.id);
                                _reload();
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                e.isSettled
                                    ? 'Mark as not settled'
                                    : 'Mark as settled',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete bill',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                          icon: Icon(
                            e.isSettled
                                ? Icons.verified_rounded
                                : Icons.more_vert,
                            color: e.isSettled
                                ? Colors.greenAccent
                                : Colors.white,
                          ),
                        )

                      // ------------ คนอื่นที่ไม่ใช่ผู้จ่าย เห็นแค่ icon -------------
                      : e.isSettled
                          ? const Icon(
                              Icons.verified_rounded,
                              color: Colors.greenAccent,
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
