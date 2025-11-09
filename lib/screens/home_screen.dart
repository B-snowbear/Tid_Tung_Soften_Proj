import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../services/trip_api_service.dart';
import 'add_trip_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = TripApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.list();
      _trips = data;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load trips: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final res = await showAddTripDialog(context);
    if (res == null) return;
    try {
      await _api.create(
        name: res.name,
        destination: res.destination,
        start: res.start,
        end: res.end,
        description: res.description,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip created')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Trips')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = _trips[i];
                final dt = _buildDateRange(t['start_date'], t['end_date'], f);
                return Card(
                  child: ListTile(
                    title: Text(t['name'] ?? ''),
                    subtitle: Text(dt),
                    onTap: () => context.go('/trip/${t['id']}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        label: const Text('Add Trip'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _buildDateRange(dynamic s, dynamic e, DateFormat f) {
    try {
      final sd = DateTime.parse(s.toString());
      final ed = DateTime.parse(e.toString());
      return '${f.format(sd)} — ${f.format(ed)}';
    } catch (_) {
      return '';
    }
  }
}
