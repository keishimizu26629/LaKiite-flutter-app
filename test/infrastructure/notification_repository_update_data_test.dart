import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/notification_repository_update_data.dart';

void main() {
  group('NotificationRepositoryUpdateData', () {
    test('承認更新はステータスと同時に既読へする', () {
      final data = NotificationRepositoryUpdateData.accepted();

      expect(data['status'], 'accepted');
      expect(data['isRead'], isTrue);
      expect(data, contains('updatedAt'));
    });

    test('拒否更新はステータス、拒否回数、既読を同時に更新する', () {
      final data = NotificationRepositoryUpdateData.rejected();

      expect(data['status'], 'rejected');
      expect(data['isRead'], isTrue);
      expect(data, contains('rejectionCount'));
      expect(data, contains('updatedAt'));
    });
  });
}
