import 'package:flutter_test/flutter_test.dart';
import 'date_formatter.dart';

void main() {
  test('DateFormatter.formatRelativeTime すべてのケースを確認', () {
    final now = DateTime.now();

    // 30秒前
    final seconds30 = now.subtract(const Duration(seconds: 30));
    print('30秒前: ${DateFormatter.formatRelativeTime(seconds30)}');

    // 5分前
    final minutes5 = now.subtract(const Duration(minutes: 5));
    print('5分前: ${DateFormatter.formatRelativeTime(minutes5)}');

    // 2時間前
    final hours2 = now.subtract(const Duration(hours: 2));
    print('2時間前: ${DateFormatter.formatRelativeTime(hours2)}');

    // 3日前
    final days3 = now.subtract(const Duration(days: 3));
    print('3日前: ${DateFormatter.formatRelativeTime(days3)}');

    // 40日前
    final days40 = now.subtract(const Duration(days: 40));
    print('40日前: ${DateFormatter.formatRelativeTime(days40)}');
  });
}
