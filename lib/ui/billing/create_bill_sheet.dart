import 'package:flutter/material.dart';
import '../../services/expense_service.dart';

class MemberOption {
  final String id;
  final String name;
  MemberOption(this.id, this.name);
}

Future<void> showCreateBillSheet(
  BuildContext context, {
  required String tripId,
  required String payerProfileId,
  required List<MemberOption> members,
}) async {
  final amountCtl = TextEditingController();
  final noteCtl = TextEditingController();

  final selected = <String>{for (final m in members) m.id};

  String payerId = payerProfileId;

  String selectedCurrency = 'THB';

  bool useCustomSplit = false;

  final Map<String, TextEditingController> shareCtrls = {
    for (final m in members) m.id: TextEditingController(),
  };

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Bill',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  // ---- Paid by ----
                  Row(
                    children: [
                      const Text('Paid by:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: payerId,
                          isExpanded: true,
                          items: members
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              payerId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ---- Currency ----
                  Row(
                    children: [
                      const Text('Currency:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedCurrency,
                        items: const [
                          DropdownMenuItem(
                            value: 'THB',
                            child: Text('THB (฿)'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD (\$)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedCurrency = value);
                        },
                      ),
                    ],
                  ),

                  // ---- Amount & Note ----
                  TextField(
                    controller: amountCtl,
                    decoration: InputDecoration(
                      labelText: 'Amount ($selectedCurrency)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: noteCtl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---- Split mode ----
                  Row(
                    children: [
                      const Text('Split mode:'),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Equal'),
                        selected: !useCustomSplit,
                        onSelected: (s) {
                          if (s) setState(() => useCustomSplit = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: useCustomSplit,
                        onSelected: (s) {
                          if (s) setState(() => useCustomSplit = true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---- Participants ----
                  const Text('Participants'),
                  Wrap(
                    spacing: 8,
                    children: members.map((m) {
                      final on = selected.contains(m.id);
                      return FilterChip(
                        label: Text(m.name),
                        selected: on,
                        onSelected: (s) {
                          setState(() {
                            if (s) {
                              selected.add(m.id);
                            } else {
                              selected.remove(m.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // ---- Custom split ----
                  if (useCustomSplit) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Custom amounts ($selectedCurrency)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Column(
                      children: members
                          .where((m) => selected.contains(m.id))
                          .map((m) {
                        final ctl = shareCtrls[m.id]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.name)),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: ctl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      InputDecoration(labelText: selectedCurrency),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  ],

                  const SizedBox(height: 16),

                  // ---- Create button ----
                  FilledButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountCtl.text.trim()) ?? 0;
                      if (amount <= 0 || selected.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content:
                                Text('กรอกจำนวนเงินให้ถูกต้องและเลือกผู้ร่วมบิล'),
                          ),
                        );
                        return;
                      }

                      Map<String, double>? customShares;

                      if (useCustomSplit) {
                        customShares = {};
                        double sum = 0.0;

                        for (final id in selected) {
                          final value =
                              double.tryParse(shareCtrls[id]!.text.trim()) ?? 0;

                          if (value <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'จำนวนเงินของ ${members.firstWhere((m) => m.id == id).name} ไม่ถูกต้อง (> 0)',
                                ),
                              ),
                            );
                            return;
                          }

                          customShares[id] = value;
                          sum += value;
                        }

                        if ((sum - amount).abs() > 0.01) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ยอดรวม ${sum.toStringAsFixed(2)} ต้องเท่ากับ Amount ${amount.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      await ExpenseService.createExpense(
                        tripId: tripId,
                        payerProfileId: payerId,
                        amount: amount,
                        currency: selectedCurrency,
                        note: noteCtl.text.trim().isEmpty
                            ? null
                            : noteCtl.text.trim(),
                        participantProfileIds: selected.toList(),
                        customShares: customShares,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  for (final c in shareCtrls.values) {
    c.dispose();
  }
}
