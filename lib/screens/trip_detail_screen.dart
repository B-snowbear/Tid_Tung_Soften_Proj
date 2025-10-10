import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../mock_store.dart';
import '../models.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final trip = store.getTrip(tripId);
    final money = NumberFormat.currency(locale: 'th_TH', symbol: 'THB ');
    final dateFmt = DateFormat('d MMM y');

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found')));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(trip.title),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // Trip meta card
            _MetaCard(
              title: trip.title,
              dateRange:
                  '${dateFmt.format(trip.start)}  –  ${dateFmt.format(trip.end)}',
              total: money.format(trip.total),
            ),
            const SizedBox(height: 12),

            // Expenses list
            ...trip.expenses.map((e) => _ExpenseTile(
                  title: e.title,
                  subtitle:
                      '${e.category} • ${dateFmt.format(e.date)} • Payer: ${e.payer.name}',
                  amount: money.format(e.amount),
                )),
            if (trip.expenses.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: _kCardDeco,
                child: Text(
                  'No expenses yet.\nTap “Add Expense” to create one.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
          ],
        ),
        // Add Expense button
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: () => _openAddExpense(context, trip),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddExpense(BuildContext context, Trip trip) {
    final store = context.read<MockStore>();
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    Member payer = trip.members.first;
    String category = 'Food';
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Expense', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Dinner',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (THB)',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Member>(
                value: payer,
                items: trip.members
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => payer = v ?? payer,
                decoration: const InputDecoration(labelText: 'Payer'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: const ['Food', 'Transport', 'Accommodation', 'Misc']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDate: date,
                        );
                        if (picked != null) date = picked;
                      },
                      child: const Text('Pick Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill valid title & amount > 0')),
                          );
                          return;
                        }
                        final e = Expense(
                          id: store.genId('e'),
                          title: title,
                          amount: amount,
                          date: date,
                          payer: payer,
                          category: category,
                        );
                        store.addExpense(trip.id, e);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- UI bits ----------------

final _kCardDeco = BoxDecoration(
  borderRadius: BorderRadius.circular(18),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C5AA8), Color(0xFF3A66C0)],
  ),
  boxShadow: const [
    BoxShadow(blurRadius: 16, offset: Offset(0, 6), color: Color(0x33000000)),
  ],
);

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.title,
    required this.dateRange,
    required this.total,
  });

  final String title;
  final String dateRange;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _kCardDeco,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Total Spent',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: TTColors.cB7EDFF)),
              const SizedBox(width: 8),
              Text(total,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Date',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: TTColors.cB7EDFF)),
              const SizedBox(width: 8),
              Text(dateRange,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: _kCardDeco,
      child: ListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.9))),
        trailing: Text(amount,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
