class Trip {
  final String id;
  String title;
  DateTime start;
  DateTime end;
  final String currency;
  final List<Member> members;
  final List<Expense> expenses;

  Trip({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.currency = 'THB',
    List<Member>? members,
    List<Expense>? expenses,
  })  : members = members ?? [],
        expenses = expenses ?? [];

  double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);
}

class Member {
  final String id;
  String name;
  Member({required this.id, required this.name});
}

class Expense {
  final String id;
  String title;
  double amount;
  DateTime date;
  Member payer;
  String category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.payer,
    required this.category,
  });
}
