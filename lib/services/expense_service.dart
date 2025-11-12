import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class ExpenseService {
  // สร้างบิล + เพิ่ม splits (หารเท่า)
  static Future<void> createExpense({
    required String tripId,
    required String payerProfileId,            // = profiles.id (auth.uid)
    required double amount,
    String? note,
    required List<String> participantProfileIds, // profiles.id ของผู้ร่วมบิล
  }) async {
    final exp = await _sb.from('expenses').insert({
      'trip_id'   : tripId,
      'profile_id': payerProfileId,
      'amount'    : amount,
      'note'      : note,
      'created_by': _sb.auth.currentUser!.id,
    }).select('id').single();

    final expenseId = exp['id'] as String;
    final share = amount / participantProfileIds.length;

    final rows = participantProfileIds.map((pid) => {
      'expense_id'  : expenseId,
      'trip_id'     : tripId,
      'member_id'   : pid,
      'share_amount': share,
    }).toList();

    await _sb.from('expense_splits').insert(rows);
  }

  // โหลด balance จาก view
  static Future<List<MemberBalance>> getBalances(String tripId) async {
    final rows = await _sb
        .from('v_trip_balances')
        .select()
        .eq('trip_id', tripId);

    return rows.map<MemberBalance>((r) => MemberBalance(
      memberId: r['member_id'] as String,
      name    : (r['full_name'] as String?) ?? 'Member',
      paid    : (r['paid'] as num?)?.toDouble() ?? 0,
      owed    : (r['owed'] as num?)?.toDouble() ?? 0,
      balance : (r['balance'] as num?)?.toDouble() ?? 0,
    )).toList();
  }
}

class MemberBalance {
  final String memberId, name;
  final double paid, owed, balance;
  MemberBalance({required this.memberId, required this.name,
    required this.paid, required this.owed, required this.balance});
}
