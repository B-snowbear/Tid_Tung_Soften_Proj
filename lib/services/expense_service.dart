import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class ExpenseService {
  /// ---- Exchange Rate ----
  /// ดึงอัตราแลกเปลี่ยนเป็น THB ต่อ 1 หน่วยของ [currency]
  /// - ถ้าเป็น 'THB' → 1.0
  /// - ถ้าไม่เจอเรท → 1.0 กันพังไว้ก่อน
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
    // กรณีไม่เจอเรทเลย
    return 1.0;
  }

  /// ---- Create Expense (Equal / Custom Split) ----
  /// - [amount] เป็นยอดรวมตามสกุลเงินที่เลือก (เช่น 100 USD)
  /// - ถ้าไม่ส่ง [customShares] → หารเท่ากันด้วย participantProfileIds
  /// - ถ้าส่ง [customShares] → หารไม่เท่ากัน (key = profileId, value = amount ในสกุลเงินของบิล)
  static Future<void> createExpense({
    required String tripId,
    required String payerProfileId, // = profiles.id (auth.uid)
    required double amount,
    String currency = 'THB',
    String? note,
    String? category, // 👈 ถ้ามี field category ในตาราง expenses
    required List<String> participantProfileIds,
    Map<String, double>? customShares,
  }) async {
    // 1) rate ของสกุลนี้ (THB per 1 unit)
    final fxRate = await _resolveFxRate(currency);

    // 2) ยอดรวมเป็น THB
    final totalThb = amount * fxRate;

    // 3) เตรียมส่วนแบ่งของแต่ละคน (หน่วย THB)
    late final List<String> participants;
    late final Map<String, double> shareThbByMember;

    if (customShares != null && customShares.isNotEmpty) {
      // custom split: จำนวนเงินในสกุลของบิล → แปลงเป็น THB
      participants = customShares.keys.toList();
      shareThbByMember = {
        for (final e in customShares.entries) e.key: e.value * fxRate,
      };
    } else {
      // หารเท่ากัน
      participants = participantProfileIds;
      final shareThb = totalThb / participants.length;
      shareThbByMember = {
        for (final pid in participants) pid: shareThb,
      };
    }

    // 4) insert ที่ expenses
    final exp = await _sb
        .from('expenses')
        .insert({
          'trip_id': tripId,
          'profile_id': payerProfileId,
          'amount': amount,
          'currency': currency,
          'fx_rate': fxRate,
          'note': note,
          'category': category, // 👈 ถ้า null DB ก็เก็บเป็น null ได้
          'created_by': _sb.auth.currentUser!.id,
        })
        .select('id')
        .single();

    final expenseId = exp['id'] as String;

    // 5) insert splits เป็น THB ต่อคน
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
        balance: ((r['paid'] as num?)?.toDouble() ?? 0) -
            ((r['owed'] as num?)?.toDouble() ?? 0),
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
          category,
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
        category: r['category'] as String?, // 👈 ใช้ใน report
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

  /// ======================================================
  /// 🔥 รวมยอด balance ทั้งหมดของ user จากทุกทริป
  ///   ใช้ v_trip_balances โดยตรง
  /// ======================================================
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
      if (b != null) {
        total += b.toDouble();
      }
    }
    return total;
  }

  /// ======================================================
  /// 🔥 History: บิลที่เราเป็นคนจ่ายเองทุกทริป
  /// ======================================================
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
          category,
          trip:trips!expenses_trip_id_fkey (
            name
          )
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
        category: r['category'] as String?,
      );
    }).toList();
  }

  /// ======================================================
  /// 🔥 Trip report data (ใช้สำหรับหน้า report + กราฟ)
  /// - totalThb : ยอดรวม THB ทั้งทริป
  /// - byCategory : map category -> total THB
  /// - byPayer : map payerName -> total THB
  /// - memberBalances : ใช้แสดง amount owed/received ต่อคน
  /// ======================================================
  static Future<TripReportData> getTripReport(String tripId) async {
    // 1) ดึง expenses ของทริปนี้
    final expenses = await getTripExpenses(tripId);

    // 2) รวมยอดทั้งหมด + แยกตาม category/payer
    double total = 0.0;
    final Map<String, double> byCategory = {};
    final Map<String, double> byPayer = {};

    for (final e in expenses) {
      total += e.amountThb;

      final cat = (e.category?.isNotEmpty ?? false) ? e.category! : 'Other';
      byCategory[cat] = (byCategory[cat] ?? 0) + e.amountThb;

      final payer = e.payerName.isNotEmpty ? e.payerName : 'Unknown';
      byPayer[payer] = (byPayer[payer] ?? 0) + e.amountThb;
    }

    // 3) ดึง balances ของสมาชิกแต่ละคน
    final balances = await getBalances(tripId);

    return TripReportData(
      totalThb: total,
      byCategory: byCategory,
      byPayer: byPayer,
      memberBalances: balances,
    );
  }
}

/// ===== models =====

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
  final String? category;

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
    this.category,
  });
}

/// ใช้สำหรับ History รวมทุกทริปที่เราเป็นคนจ่าย
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
  final String? category;

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
    this.category,
  });
}

/// ใช้สำหรับ Trip report
class TripReportData {
  final double totalThb;
  final Map<String, double> byCategory;
  final Map<String, double> byPayer;
  final List<MemberBalance> memberBalances;

  TripReportData({
    required this.totalThb,
    required this.byCategory,
    required this.byPayer,
    required this.memberBalances,
  });
}
