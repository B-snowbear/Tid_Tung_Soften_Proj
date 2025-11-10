import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';
import '../services/trip_api_service.dart';
import 'add_trip_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = TripApiService();
  final _dateFmt = DateFormat('d MMM y');

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.list();
      setState(() {
        _trips = data;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTrip() async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Trip created')));
      }
      await _loadTrips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    }
  }

  Future<void> _joinTrip(BuildContext context) async {
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Trip'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Enter join code',
            hintText: 'e.g. A1B2C3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);

              try {
                final token = Supabase.instance.client.auth.currentSession?.accessToken;
                final r = await http.post(
                  Uri.parse(kIsWeb
                      ? 'http://localhost:4000/api/trips/join'
                      : 'http://10.0.2.2:4000/api/trips/join'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({'code': code}),
                );

                if (r.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined trip successfully!')),
                  );
                  await _loadTrips();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Join failed: ${r.body}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tid Tung',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                        Text('by houma',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: TTColors.cC9D7FF)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.account_circle, color: Colors.white),
                        onPressed: () => context.push('/profile'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/protected-status'),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Open Protected Status'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.16),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Body: trip list
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Text(_error!, textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _loadTrips, child: const Text('Retry')),
                                ],
                              ),
                            )
                          : _trips.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('No trips yet',
                                          style: TextStyle(color: Colors.white)),
                                      const SizedBox(height: 8),
                                      FilledButton.icon(
                                        onPressed: _addTrip,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add a Trip'),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadTrips,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 96),
                                    itemCount: _trips.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, i) {
                                      final t = _trips[i];
                                      final name = (t['name'] ?? '') as String;
                                      final dest = (t['destination'] ?? '') as String;
                                      String date = '';
                                      if (t['start_date'] != null &&
                                          t['end_date'] != null) {
                                        final s = DateTime.parse('${t['start_date']}');
                                        final e = DateTime.parse('${t['end_date']}');
                                        date =
                                            '${_dateFmt.format(s)}  –  ${_dateFmt.format(e)}';
                                      }
                                      return _TripCard(
                                        title: name.isEmpty
                                            ? (dest.isEmpty ? '(no name)' : dest)
                                            : name,
                                        totalSpent: 'Total Spent',
                                        date: date,
                                        onTap: () => context.go(
                                          '/trip/${t['id']}',
                                          extra: t['name'],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              heroTag: 'join',
              onPressed: () => _joinTrip(context),
              icon: const Icon(Icons.group_add),
              label: const Text('Join Trip'),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: _addTrip,
              icon: const Icon(Icons.add),
              label: const Text('Add Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.title,
    required this.totalSpent,
    required this.date,
    required this.onTap,
  });
  final String title;
  final String totalSpent;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2C5AA8), Color(0xFF3A66C0)],
          ),
          boxShadow: const [
            BoxShadow(blurRadius: 16, offset: Offset(0, 6), color: Color(0x33000000))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Total Spent',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: TTColors.cB7EDFF)),
            Text(totalSpent,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Date',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: TTColors.cB7EDFF)),
            Text(date,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
