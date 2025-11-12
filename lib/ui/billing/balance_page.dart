import 'package:flutter/material.dart';
import '../../services/expense_service.dart';

class BalancePage extends StatefulWidget {
  final String tripId;
  const BalancePage({super.key, required this.tripId});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  late Future<List<MemberBalance>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExpenseService.getBalances(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5AA8), // หรือ TTColors.bgStart
        foregroundColor: Colors.white,            // สีตัวอักษรและลูกศร
        title: const Text('Balances'),
      ),
      body: FutureBuilder<List<MemberBalance>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No balance data yet.'));
          }

          // totals (optional)
          final totalPaid = items.fold<double>(0, (a, b) => a + b.paid);
          final totalOwed = items.fold<double>(0, (a, b) => a + b.owed);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Trip summary'),
                  subtitle: Text(
                    'Total paid: ${totalPaid.toStringAsFixed(2)} • '
                    'Total owed: ${totalOwed.toStringAsFixed(2)}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((b) => Card(
                    child: ListTile(
                      title: Text(b.name),
                      subtitle: Text(
                        'Paid: ${b.paid.toStringAsFixed(2)}  •  '
                        'Owed: ${b.owed.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        (b.balance >= 0 ? '+ ' : '- ') +
                            b.balance.abs().toStringAsFixed(2),
                        style: TextStyle(
                          color:
                              b.balance >= 0 ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
