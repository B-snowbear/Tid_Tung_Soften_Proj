import 'dart:math';                     // ⬅️ add this
import 'package:flutter/foundation.dart';
import 'models.dart';

class MockStore extends ChangeNotifier {
  final List<Trip> _trips = [];
  List<Trip> get trips => List.unmodifiable(_trips);

  void seed() {
    if (_trips.isNotEmpty) return;

    final m1 = Member(id: 'u1', name: 'Nus');
    final m2 = Member(id: 'u2', name: 'Boom');
    final m3 = Member(id: 'u3', name: 'Tk');

    final t1 = Trip(
      id: 't1',
      title: 'Trip to Tokyo',
      start: DateTime(2025, 3, 1),
      end: DateTime(2025, 3, 7),
      members: [m1, m2, m3],
    );

    final t2 = Trip(
      id: 't2',
      title: 'Trip to Pattaya',
      start: DateTime(2025, 4, 10),
      end: DateTime(2025, 4, 12),
      members: [m1, m2],
    );

    final t3 = Trip(
      id: 't3',
      title: 'Trip to Bangkok',
      start: DateTime(2025, 5, 20),
      end: DateTime(2025, 5, 23),
      members: [m1, m3],
    );

    _trips.addAll([t1, t2, t3]);
  }

  Trip? getTrip(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void addExpense(String tripId, Expense e) {
    final t = getTrip(tripId);
    if (t == null) return;
    t.expenses.add(e);
    notifyListeners();
  }

  // ⬇️ the missing function
  String genId(String prefix) => '$prefix-${Random().nextInt(1 << 32)}';
}
