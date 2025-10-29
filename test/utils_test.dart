import 'package:flutter_test/flutter_test.dart';

// Simple utility function to test
String formatTHB(num amount) => '฿${amount.toStringAsFixed(2)}';

void main() {
  group('Utils – formatTHB', () {
    test('formats number with two decimal places', () {
      expect(formatTHB(1000), '฿1000.00');
      expect(formatTHB(99.5), '฿99.50');
    });

    test('formats zero correctly', () {
      expect(formatTHB(0), '฿0.00');
    });
  });
}
