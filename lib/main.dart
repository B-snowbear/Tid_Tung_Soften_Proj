import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'auth_service.dart';
import 'mock_store.dart';
import 'app_router.dart';
import 'theme_provider.dart';   // 👈 NEW
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Listen Supabase Password Recovery
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).go('/reset-password');
      }
    }
  });

  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MockStore()..seed()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),   // 👈 NEW
      ],
      child: const TidTungApp(),
    );
  }
}

class TidTungApp extends StatelessWidget {
  const TidTungApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(context);

    return MaterialApp.router(
      title: 'Tid Tung',
      
      // 👇 ใช้ ThemeProvider แทน buildAppTheme()
      theme: context.watch<ThemeProvider>().theme,

      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
