import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class ExpenseService {
  /// ---- Exchange Rate ----
  static Future<double> _resolveFxRate(String currency) async {
    if (currency == 'THB') return 1.0;

    final rows = await _sb
        .from('exchange_rates')
        .select('thb_per_1')
        .eq('currency', currency)
        .order('rate_date', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      final num v = rows.first['thb_per_1'] as num;
      return v.toDouble();
    }
    return 1.0; // fallback
  }

  /// ---- Create Expense (Equal / Custom Split) ----
  static Future<void> createExpense({
    required String tripId,
    required String payerProfileId,
    required double amount,
    String currency = 'THB',
    String? note,
    required List<String> participantProfileIds,
    Map<String, double>? customShares,
  }) async {
    final fxRate = await _resolveFxRate(currency);
    final totalThb = amount * fxRate;

    late final List<String> participants;
    late final Map<String, double> shareThbByMember;

    if (customShares != null && customShares.isNotEmpty) {
      participants = customShares.keys.toList();
      shareThbByMember = {
        for (final e in customShares.entries) e.key: e.value * fxRate,
      };
    } else {
      participants = participantProfileIds;
      final shareThb = totalThb / participants.length;
      shareThbByMember = {
        for (final pid in participants) pid: shareThb,
      };
    }

    final exp = await _sb
        .from('expenses')
        .insert({
          'trip_id': tripId,
          'profile_id': payerProfileId,
          'amount': amount,
          'currency': currency,
          'fx_rate': fxRate,
          'note': note,
          'created_by': _sb.auth.currentUser!.id,
        })
        .select('id')
        .single();

    final expenseId = exp['id'] as String;

    final rows = shareThbByMember.entries.map((e) {
      return {
        'expense_id': expenseId,
        'trip_id': tripId,
        'member_id': e.key,
        'share_amount': e.value,
      };
    }).toList();

    await _sb.from('expense_splits').insert(rows);
  }

  /// ---- Balances per Trip ----
  static Future<List<MemberBalance>> getBalances(String tripId) async {
    final rows = await _sb
        .from('v_trip_balances')
        .select()
        .eq('trip_id', tripId);

    return rows.map<MemberBalance>((r) {
      return MemberBalance(
        memberId: r['member_id'] as String,
        name: r['full_name'] as String? ?? 'Member',
        paid: (r['paid'] as num?)?.toDouble() ?? 0,
        owed: (r['owed'] as num?)?.toDouble() ?? 0,
        balance:
            ((r['paid'] as num?)?.toDouble() ?? 0) - ((r['owed'] as num?)?.toDouble() ?? 0),
      );
    }).toList();
  }

  /// ---- Expense History (per trip) ----
  static Future<List<ExpenseItem>> getTripExpenses(String tripId) async {
    final rows = await _sb
        .from('expenses')
        .select('''
          id,
          trip_id,
          profile_id,
          amount,
          currency,
          amount_thb,
          note,
          created_at,
          is_settled,
          profiles:profiles!expenses_profile_id_fkey (
            full_name,
            email
          )
        ''')
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);

    return rows.map<ExpenseItem>((r) {
      final payer = (r['profiles'] ?? {}) as Map<String, dynamic>;
      return ExpenseItem(
        id: r['id'] as String,
        tripId: r['trip_id'] as String,
        payerId: r['profile_id'] as String,
        payerName:
            payer['full_name'] ?? payer['email']?.split('@').first ?? 'Unknown',
        amount: (r['amount'] as num).toDouble(),
        currency: (r['currency'] as String?) ?? 'THB',
        amountThb: (r['amount_thb'] as num).toDouble(),
        note: r['note'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        isSettled: (r['is_settled'] as bool?) ?? false,
      );
    }).toList();
  }

  /// ---- Mark settled / unsettle ----
  static Future<void> setExpenseSettled(String expenseId, bool settled) async {
    await _sb
        .from('expenses')
        .update({'is_settled': settled})
        .eq('id', expenseId);
  }

  /// ---- Delete Expense ----
  static Future<void> deleteExpense(String expenseId) async {
    await _sb.from('expense_splits').delete().eq('expense_id', expenseId);
    await _sb.from('expenses').delete().eq('id', expenseId);
  }

  /// ---- รวมยอด balance ของ user ทุกทริป ----
  static Future<double> getMyTotalBalance() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0.0;

    final rows = await _sb
        .from('v_trip_balances')
        .select('balance')
        .eq('member_id', uid);

    double total = 0.0;
    for (final r in rows) {
      final num? b = r['balance'] as num?;
      if (b != null) total += b.toDouble();
    }
    return total;
  }

  /// ---- History: bills paid by current user ----
  static Future<List<MyPaidExpenseItem>> getMyPaidExpenses() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _sb
        .from('expenses')
        .select('''
          id,
          trip_id,
          amount,
          currency,
          amount_thb,
          note,
          created_at,
          is_settled,
          trip:trips!expenses_trip_id_fkey ( name )
        ''')
        .eq('profile_id', uid)
        .order('created_at', ascending: false);

    return rows.map<MyPaidExpenseItem>((r) {
      final trip = (r['trip'] ?? {}) as Map<String, dynamic>;
      return MyPaidExpenseItem(
        id: r['id'] as String,
        tripId: r['trip_id'] as String,
        tripName: (trip['name'] as String?) ?? 'Unnamed trip',
        amount: (r['amount'] as num).toDouble(),
        currency: (r['currency'] as String?) ?? 'THB',
        amountThb: (r['amount_thb'] as num).toDouble(),
        note: r['note'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        isSettled: (r['is_settled'] as bool?) ?? false,
      );
    }).toList();
  }

  // =====================================================================
  // 🔥 Trip Report (Total, Contributions, Balances, Category Breakdown)
  // =====================================================================

  static Future<TripReport> getTripReport(String tripId) async {
    final rows = await _sb
        .from('expenses')
        .select('''
          id,
          amount_thb,
          profile_id,
          category,
          profiles:profiles!expenses_profile_id_fkey ( full_name, email )
        ''')
        .eq('trip_id', tripId);

    // 1) Total expenses
    double total = 0;
    for (final r in rows) {
      total += (r['amount_thb'] as num? ?? 0).toDouble();
    }

    // 2) Per-member contribution
    final Map<String, MemberContribution> byMember = {};

    for (final r in rows) {
      final String id = r['profile_id'];
      final payer = (r['profiles'] ?? {}) as Map<String, dynamic>;
      final String name =
          payer['full_name'] ??
          payer['email']?.split('@').first ??
          'Unknown';

      final double amt = (r['amount_thb'] as num? ?? 0).toDouble();

      if (byMember[id] == null) {
        byMember[id] = MemberContribution(
          memberId: id,
          name: name,
          totalPaidThb: amt,
        );
      } else {
        byMember[id] =
            MemberContribution(
              memberId: id,
              name: name,
              totalPaidThb: byMember[id]!.totalPaidThb + amt,
            );
      }
    }

    // 3) Category breakdown
    final Map<String, double> byCat = {};
    for (final r in rows) {
      final String cat = r['category'] ?? 'Other';
      final double amt = (r['amount_thb'] as num? ?? 0).toDouble();
      byCat[cat] = (byCat[cat] ?? 0) + amt;
    }

    // 4) Balances from view
    final balances = await getBalances(tripId);

    return TripReport(
      totalExpensesThb: total,
      contributions: byMember.values.toList(),
      categories: byCat.entries
          .map((e) => CategoryTotal(category: e.key, totalThb: e.value))
          .toList(),
      balances: balances,
    );
  }
}

// =====================================================================
// Models
// =====================================================================

class MemberBalance {
  final String memberId;
  final String name;
  final double paid;
  final double owed;
  final double balance;

  MemberBalance({
    required this.memberId,
    required this.name,
    required this.paid,
    required this.owed,
    required this.balance,
  });
}

class ExpenseItem {
  final String id;
  final String tripId;
  final String payerId;
  final String payerName;
  final double amount;
  final String currency;
  final double amountThb;
  final String? note;
  final DateTime createdAt;
  final bool isSettled;

  ExpenseItem({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.currency,
    required this.amountThb,
    required this.note,
    required this.createdAt,
    required this.isSettled,
  });
}

class MyPaidExpenseItem {
  final String id;
  final String tripId;
  final String tripName;
  final double amount;
  final String currency;
  final double amountThb;
  final String? note;
  final DateTime createdAt;
  final bool isSettled;

  MyPaidExpenseItem({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.amount,
    required this.currency,
    required this.amountThb,
    required this.note,
    required this.createdAt,
    required this.isSettled,
  });
}

// ---------------- Trip Report Models -----------------

class MemberContribution {
  final String memberId;
  final String name;
  final double totalPaidThb;

  MemberContribution({
    required this.memberId,
    required this.name,
    required this.totalPaidThb,
  });
}

class CategoryTotal {
  final String category;
  final double totalThb;

  CategoryTotal({
    required this.category,
    required this.totalThb,
  });
}

class TripReport {
  final double totalExpensesThb;
  final List<MemberContribution> contributions;
  final List<MemberBalance> balances;
  final List<CategoryTotal> categories;

  TripReport({
    required this.totalExpensesThb,
    required this.contributions,
    required this.balances,
    required this.categories,
  });
}
