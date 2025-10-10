import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock_store.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final f = NumberFormat.currency(locale: 'th_TH', symbol: 'THB ');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Trips')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: store.trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = store.trips[i];
          return Card(
            child: ListTile(
              title: Text(t.title),
              subtitle: Text(
                '${t.start.toString().split(' ').first} → ${t.end.toString().split(' ').first}',
              ),
              trailing: Text(f.format(t.total)),
              onTap: () => context.go('/trip/${t.id}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // ไว้ภายหลัง: หน้า Create Trip (ตอนนี้ยังไม่ทำ)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Trip: UI coming soon')),
          );
        },
        label: const Text('Add Trip'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
