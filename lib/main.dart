import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'auth_service.dart';
import 'services/notification_api_service.dart';
import 'app_router.dart';
import 'theme.dart';
import 'language_provider.dart';
// import 'mock_store.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // handle password recovery redirect
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
        ChangeNotifierProvider(create: (_) => NotificationApiService()),        
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        // ChangeNotifierProvider(create: (_) => MockStore()..seed()),
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
    final themeProvider = context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();

    return MaterialApp.router(
      title: langProvider.text.appTitle,
      theme: themeProvider.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
