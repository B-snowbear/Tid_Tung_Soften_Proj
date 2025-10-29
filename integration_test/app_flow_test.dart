import "package:integration_test/integration_test.dart";
import "package:flutter_test/flutter_test.dart";

// RELATIVE import to your entrypoint (avoids package-name resolution issues)
import "../lib/main.dart" as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("E2E-001: boots and shows login or dashboard", (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final login = find.text("Sign in with Google");
    final dashboard = find.textContaining("Dashboard");

    expect(login.evaluate().isNotEmpty || dashboard.evaluate().isNotEmpty, true);
  });
}
