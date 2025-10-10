import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authed = context.watch<AuthService>().signedIn;
    final code = authed ? 200 : 401;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Status: $code', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(authed ? 'Authorized ✅' : 'Unauthorized ❌'),
          const SizedBox(height: 24),
          if (authed)
            ElevatedButton(
              onPressed: () => context.read<AuthService>().signOut(),
              child: const Text('Logout'),
            ),
        ]),
      ),
    );
  }
}
