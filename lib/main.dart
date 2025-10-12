import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'mock_store.dart';
import 'app_router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uhcbqydmqobksobjycvw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoY2JxeWRtcW9ia3NvYmp5Y3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3Mzc5NDksImV4cCI6MjA3NTMxMzk0OX0.Ft_SKCRP9a4Ee6l7MqwJcJ1VbO20gOeFTsnRNPrDdr0',
  // authFlowType: AuthFlowType.pkce,   // <-- REMOVE this line if it errors
);


  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),   // ← will listen to auth changes
        ChangeNotifierProvider(create: (_) => MockStore()..seed()),
      ],
      child: const TidTungApp(),
    );
  }
}

class TidTungApp extends StatelessWidget {
  const TidTungApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(context); // see step 4 for redirect guard
    return MaterialApp.router(
      title: 'Tid Tung',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
