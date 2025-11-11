import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'mock_store.dart';
import 'app_router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");


  await Supabase.initialize(
     url: dotenv.env['SUPABASE_URL']!,
     anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
     authOptions: const FlutterAuthClientOptions(
       autoRefreshToken: true,
     ),
   );


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