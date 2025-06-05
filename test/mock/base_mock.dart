import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/value/user_id.dart';

/// モック基底クラス - 共通機能を提供
abstract class BaseMock {
  static const String testUserId = 'test-user-id';
  static const String testEmail = 'test@example.com';
  static const String testDisplayName = 'テストユーザー';

  /// テスト用ユーザーデータ
  static UserModel createTestUser({
    String? id,
    String? name,
    String? displayName,
  }) {
    return UserModel.create(
      id: id ?? testUserId,
      name: name ?? 'テストユーザー',
      displayName: displayName ?? testDisplayName,
    );
  }

  /// テスト用スケジュールデータ
  static Schedule createTestSchedule({
    String? id,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? ownerId,
    String? ownerDisplayName,
  }) {
    final scheduleId = id ?? 'test-schedule-id';

    // 固定のベース時間を使用して、同じIDなら同じ時間を返す
    final baseTime = DateTime(2024, 1, 15, 10, 0);
    final fixedCreatedAt = DateTime(2024, 1, 1, 9, 0);
    final fixedUpdatedAt = DateTime(2024, 1, 1, 9, 0);

    return Schedule(
      id: scheduleId,
      title: title ?? 'テストスケジュール',
      description: description ?? 'テスト用の説明',
      startDateTime: startDateTime ?? baseTime,
      endDateTime: endDateTime ?? baseTime.add(const Duration(hours: 1)),
      ownerId: ownerId ?? testUserId,
      ownerDisplayName: ownerDisplayName ?? testDisplayName,
      sharedLists: const [],
      visibleTo: const [],
      reactionCount: 0,
      commentCount: 0,
      createdAt: fixedCreatedAt,
      updatedAt: fixedUpdatedAt,
    );
  }

  /// テスト用のUserId
  static UserId createTestUserId([String? value]) {
    return UserId(value ?? 'abcd1234');
  }
}
