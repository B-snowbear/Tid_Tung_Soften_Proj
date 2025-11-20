import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class ExpenseService {
  /// ดึงอัตราแลกเปลี่ยนเป็น THB ต่อ 1 หน่วยของ [currency]
  /// - ถ้าเป็น 'THB' → 1.0
  /// - ถ้าไม่เจอเรทในตาราง → fallback เป็น 1.0 (กันพัง)
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

    // กันเคสไม่มีข้อมูลใน exchange_rates
    return 1.0;
  }

  /// สร้างบิล + เพิ่ม splits
  /// - [amount] เป็นยอดรวม “ตามสกุลเงินที่เลือก” (เช่น 100 USD)
  /// - [currency] default = 'THB'
  /// - ในตาราง:
  ///   - expenses.amount      = amount (สกุลเดิม)
  ///   - expenses.currency    = currency
  ///   - expenses.fx_rate     = fxRate (THB per 1 unit)
  ///   - expenses.amount_thb  = amount * fx_rate (generated column)
  ///   - expense_splits.share_amount = ส่วนแบ่งต่อคน **หน่วย THB**
  ///
  /// - [participantProfileIds] ใช้ในกรณีหารเท่า ๆ กัน
  /// - [customShares] ใช้ในกรณีหารไม่เท่ากัน:
  ///     key   = profileId ของสมาชิก
  ///     value = จำนวนเงินส่วนของคนนั้น (หน่วย = currency ของบิล)
  static Future<void> createExpense({
    required String tripId,
    required String payerProfileId, // = profiles.id (auth.uid)
    required double amount,
    String currency = 'THB',
    String? note,
    required List<String> participantProfileIds,
    Map<String, double>? customShares,
  }) async {
    // 1) หา fx rate สำหรับสกุลนี้ (THB per 1 unit)
    final fxRate = await _resolveFxRate(currency);

    // 2) ยอดรวมในหน่วย THB
    final totalThb = amount * fxRate;

    // 3) เตรียมส่วนแบ่งของแต่ละคน (ในหน่วย THB)
    late final List<String> participants;
    late final Map<String, double> shareThbByMember;

    if (customShares != null && customShares.isNotEmpty) {
      // 🔹 กรณี custom split:
      //   customShares เก็บเป็นสกุลของบิล (เช่น USD) → แปลงเป็น THB ทีละคน
      participants = customShares.keys.toList();

      shareThbByMember = {
        for (final entry in customShares.entries)
          entry.key: entry.value * fxRate,
      };

      // (เราเช็ค sum == amount ไปแล้วฝั่ง UI ถ้าอยากเช็คซ้ำก็ทำได้)
    } else {
      // 🔹 กรณีหารเท่ากัน
      participants = participantProfileIds;
      final shareThb = totalThb / participants.length;

      shareThbByMember = {
        for (final pid in participants) pid: shareThb,
      };
    }

    // 4) สร้างแถวใน expenses
    final exp = await _sb
        .from('expenses')
        .insert({
          'trip_id': tripId,
          'profile_id': payerProfileId,
          'amount': amount, // หน่วยเป็นสกุลที่เลือก (เช่น USD)
          'currency': currency,
          'fx_rate': fxRate, // THB ต่อ 1 หน่วยของ currency
          'note': note,
          'created_by': _sb.auth.currentUser!.id,
        })
        .select('id')
        .single();

    final expenseId = exp['id'] as String;

    // 5) บันทึก splits เป็น THB ต่อคน
    final rows = shareThbByMember.entries.map((e) {
      return {
        'expense_id': expenseId,
        'trip_id': tripId,
        'member_id': e.key,
        'share_amount': e.value, // หน่วย THB
      };
    }).toList();

    await _sb.from('expense_splits').insert(rows);
  }

  // โหลด balance จาก view (ค่าใน view ตอนนี้เป็น THB แล้ว)
  static Future<List<MemberBalance>> getBalances(String tripId) async {
    final rows = await _sb
        .from('v_trip_balances')
        .select()
        .eq('trip_id', tripId);

    return rows
        .map<MemberBalance>(
          (r) => MemberBalance(
            memberId: r['member_id'] as String,
            name: (r['full_name'] as String?) ?? 'Member',
            paid: (r['paid'] as num?)?.toDouble() ?? 0,
            owed: (r['owed'] as num?)?.toDouble() ?? 0,
            // เผื่อในอนาคตเพิ่มคอลัมน์ balance ใน view
            balance: (r['balance'] as num?)?.toDouble() ??
                ((r['paid'] as num?)?.toDouble() ?? 0) -
                    ((r['owed'] as num?)?.toDouble() ?? 0),
          ),
        )
        .toList();
  }
}

class MemberBalance {
  final String memberId, name;
  final double paid, owed, balance;

  MemberBalance({
    required this.memberId,
    required this.name,
    required this.paid,
    required this.owed,
    required this.balance,
  });
}
