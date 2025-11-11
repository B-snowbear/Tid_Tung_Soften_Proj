import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final String tripName;
  final DateTime? startDate;
  final DateTime? endDate;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    this.startDate,
    this.endDate,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembers(widget.tripId);
  }

  Future<List<Map<String, dynamic>>> _fetchMembers(String tripId) async {
    final supabase = Supabase.instance.client;
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Missing Supabase session token.');

    final url = Uri.parse('http://10.0.2.2:4000/api/trips/$tripId/members');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('Failed to load members: ${res.body}');
    }

    final data = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return data;
  }

  void _reload() {
    setState(() => _membersFuture = _fetchMembers(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM y');
    final dateRange = (widget.startDate != null && widget.endDate != null)
        ? '${dateFmt.format(widget.startDate!)} – ${dateFmt.format(widget.endDate!)}'
        : 'No date info';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(widget.tripName),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C5AA8), Color(0xFF3A66C0)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 16,
                      offset: Offset(0, 6),
                      color: Color(0x33000000),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.tripName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 8),
                    Text(dateRange,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Trip ID: ${widget.tripId}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: TTColors.cB7EDFF),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.tripId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Trip ID copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Members section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return const Center(
                        child: Text('No members yet.',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }

                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final member = members[i];
                        final profile = member['profiles'] ?? {};
                        final role = member['role'];
                        final name = profile['full_name'] ??
                            (profile['email']?.split('@').first ?? 'Unknown');
                        final email = profile['email'] ?? 'Unknown email';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: TTColors.cB7EDFF,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Row(
                              children: [
                                Text(name,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                if (role == 'owner')
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Text(
                                      '(Owner)',
                                      style: TextStyle(
                                        color: TTColors.c0DBCF6,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(email,
                                style:
                                    const TextStyle(color: Colors.white70)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.receipt_long,
                    label: 'Create Bill',
                    onTap: () {
                      // TODO: navigate to bill creation
                    },
                  ),
                  _ActionButton(
                    icon: Icons.account_balance_wallet,
                    label: 'See Balance',
                    onTap: () {
                      // TODO: navigate to balance screen
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Return button
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/protected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Return to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: TTColors.c0DBCF6,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
