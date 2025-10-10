import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'mock_store.dart';
import 'app_router.dart';
import 'theme.dart';

void main() => runApp(const Root());

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MockStore()..seed()), // mock trips
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
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
