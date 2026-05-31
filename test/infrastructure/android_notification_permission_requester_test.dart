import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/firebase/android_notification_permission_requester.dart';

void main() {
  group('AndroidNotificationPermissionRequester', () {
    test('Android通知権限リクエストを実行する', () async {
      var requestCount = 0;
      final requester = AndroidNotificationPermissionRequester(
        requestPermission: () async {
          requestCount++;
          return true;
        },
      );

      final granted = await requester.request();

      expect(granted, isTrue);
      expect(requestCount, 1);
    });
  });
}
