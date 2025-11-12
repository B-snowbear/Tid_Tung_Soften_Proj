import 'package:flutter/material.dart';
import '../../services/expense_service.dart';

class MemberOption { final String id; final String name; MemberOption(this.id,this.name); }

Future<void> showCreateBillSheet(
  BuildContext context, {
  required String tripId,
  required String payerProfileId,
  required List<MemberOption> members,
}) async {
  final amountCtl = TextEditingController();
  final noteCtl   = TextEditingController();
  final selected  = <String>{ for (final m in members) m.id }; // default: ทุกคนร่วม

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16,16,16,bottom+16),
        child: StatefulBuilder(builder: (ctx,setState){
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Create Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtl,
              decoration: const InputDecoration(labelText: 'Amount (THB)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: noteCtl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 8),
            const Text('Participants'),
            Wrap(
              spacing: 8,
              children: members.map((m){
                final on = selected.contains(m.id);
                return FilterChip(
                  label: Text(m.name),
                  selected: on,
                  onSelected: (s)=> setState(()=> s? selected.add(m.id) : selected.remove(m.id)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtl.text.trim()) ?? 0;
                if (amount <= 0 || selected.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('กรอกจำนวนเงินให้ถูกต้องและเลือกผู้ร่วมบิลอย่างน้อย 1 คน')));
                  return;
                }
                await ExpenseService.createExpense(
                  tripId: tripId,
                  payerProfileId: payerProfileId,
                  amount: amount,
                  note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                  participantProfileIds: selected.toList(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ]);
        }),
      );
    },
  );
}
