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
  required String payerProfileId, // default payer (เช่น user ปัจจุบัน)
  required List<MemberOption> members,
}) async {
  final amountCtl = TextEditingController();
  final noteCtl = TextEditingController();

  // คนที่ร่วมบิล (default = ทุกคนในทริป)
  final selected = <String>{for (final m in members) m.id};

  // dropdown “Paid by”
  String payerId = payerProfileId;

  // 💰 สกุลเงินที่เลือก (default = THB)
  String selectedCurrency = 'THB';

  // โหมด split
  bool useCustomSplit = false;

  // controller สำหรับ custom amount ของแต่ละคน (หน่วย = selectedCurrency)
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Bill',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  /// --------- Paid by ---------- ///
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

                  /// --------- Currency selector ---------- ///
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
                          setState(() {
                            selectedCurrency = value;
                          });
                        },
                      ),
                    ],
                  ),

                  /// --------- Amount + Note ---------- ///
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

                  /// --------- Split mode ---------- ///
                  Row(
                    children: [
                      const Text('Split mode:'),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Equal'),
                        selected: !useCustomSplit,
                        onSelected: (s) {
                          if (!s) return;
                          setState(() => useCustomSplit = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: useCustomSplit,
                        onSelected: (s) {
                          if (!s) return;
                          setState(() => useCustomSplit = true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// --------- Participants ---------- ///
                  const Text('Participants'),
                  Wrap(
                    spacing: 8,
                    children: members.map((m) {
                      final on = selected.contains(m.id);
                      return FilterChip(
                        label: Text(m.name),
                        selected: on,
                        onSelected: (s) => setState(
                          () => s ? selected.add(m.id) : selected.remove(m.id),
                        ),
                      );
                    }).toList(),
                  ),

                  /// --------- Custom split fields ---------- ///
                  if (useCustomSplit) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Custom amounts per person ($selectedCurrency)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
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
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: ctl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: selectedCurrency,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountCtl.text.trim()) ?? 0;
                      if (amount <= 0 || selected.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'กรอกจำนวนเงินให้ถูกต้องและเลือกผู้ร่วมบิลอย่างน้อย 1 คน',
                            ),
                          ),
                        );
                        return;
                      }

                      Map<String, double>? customShares;

                      if (useCustomSplit) {
                        customShares = {};
                        double sum = 0.0;

                        for (final memberId in selected) {
                          final text =
                              shareCtrls[memberId]!.text.trim();
                          final value = double.tryParse(text) ?? 0;

                          // ถ้าจะให้บางคน “ไม่ต้องจ่ายเลย” → unselect เขาออกจาก chips
                          if (value <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ใส่จำนวนเงินของ ${members.firstWhere((m) => m.id == memberId).name} ให้ถูกต้อง (> 0)',
                                ),
                              ),
                            );
                            return;
                          }

                          customShares[memberId] = value;
                          sum += value;
                        }

                        // เช็กว่ารวมแล้วตรงกับ amount (เผื่อมีทศนิยมให้ tolerance นิดหน่อย)
                        if ((sum - amount).abs() > 0.01) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ยอด custom รวม ${sum.toStringAsFixed(2)} ต้องเท่ากับ Amount ${amount.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      await ExpenseService.createExpense(
                        tripId: tripId,
                        payerProfileId: payerId,          // ✅ ใช้คนที่เลือกใน Paid by
                        amount: amount,
                        currency: selectedCurrency,
                        note: noteCtl.text.trim().isEmpty
                            ? null
                            : noteCtl.text.trim(),
                        participantProfileIds: selected.toList(),
                        customShares: customShares,        // ✅ null = equal split
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

  // cleanup controller ของ custom shares
  for (final c in shareCtrls.values) {
    c.dispose();
  }
}
