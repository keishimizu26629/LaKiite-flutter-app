import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import '../../mock/base_mock.dart';

void main() {
  group('Schedule Entity Tests', () {
    group('Schedule作成テスト', () {
      test('必須パラメータでスケジュールが正常に作成される', () {
        // Arrange
        const id = 'schedule-123';
        const title = 'テストスケジュール';
        const description = 'テスト用の説明';
        final startDateTime = DateTime(2024, 1, 15, 10, 0);
        final endDateTime = DateTime(2024, 1, 15, 11, 0);
        const ownerId = 'owner-123';
        const ownerDisplayName = 'オーナー';
        final createdAt = DateTime(2024, 1, 1, 9, 0);
        final updatedAt = DateTime(2024, 1, 1, 9, 0);

        // Act
        final schedule = Schedule(
          id: id,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          ownerId: ownerId,
          ownerDisplayName: ownerDisplayName,
          sharedLists: const [],
          visibleTo: const [],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        // Assert
        expect(schedule.id, id);
        expect(schedule.title, title);
        expect(schedule.description, description);
        expect(schedule.startDateTime, startDateTime);
        expect(schedule.endDateTime, endDateTime);
        expect(schedule.ownerId, ownerId);
        expect(schedule.ownerDisplayName, ownerDisplayName);
        expect(schedule.sharedLists, isEmpty);
        expect(schedule.visibleTo, isEmpty);
        expect(schedule.reactionCount, 0); // デフォルト値
        expect(schedule.commentCount, 0); // デフォルト値
        expect(schedule.createdAt, createdAt);
        expect(schedule.updatedAt, updatedAt);
      });

      test('オプションパラメータが正しく設定される', () {
        // Arrange
        const location = '東京タワー';
        const ownerPhotoUrl = 'https://example.com/photo.jpg';
        const sharedLists = ['list-1', 'list-2'];
        const visibleTo = ['user-1', 'user-2', 'user-3'];
        const reactionCount = 5;
        const commentCount = 3;

        // Act
        final schedule = BaseMock.createTestSchedule(
          title: 'オプション付きスケジュール',
        ).copyWith(
          location: location,
          ownerPhotoUrl: ownerPhotoUrl,
          sharedLists: sharedLists,
          visibleTo: visibleTo,
          reactionCount: reactionCount,
          commentCount: commentCount,
        );

        // Assert
        expect(schedule.location, location);
        expect(schedule.ownerPhotoUrl, ownerPhotoUrl);
        expect(schedule.sharedLists, sharedLists);
        expect(schedule.visibleTo, visibleTo);
        expect(schedule.reactionCount, reactionCount);
        expect(schedule.commentCount, commentCount);
      });
    });

    group('BaseMockを使用したテスト', () {
      test('BaseMock.createTestScheduleで基本スケジュールが作成される', () {
        // Act
        final schedule = BaseMock.createTestSchedule();

        // Assert
        expect(schedule.id, 'test-schedule-id');
        expect(schedule.title, 'テストスケジュール');
        expect(schedule.description, 'テスト用の説明');
        expect(schedule.ownerId, BaseMock.testUserId);
        expect(schedule.ownerDisplayName, BaseMock.testDisplayName);
        expect(schedule.sharedLists, isEmpty);
        expect(schedule.visibleTo, isEmpty);
        expect(schedule.reactionCount, 0);
        expect(schedule.commentCount, 0);
      });

      test('BaseMock.createTestScheduleでカスタムパラメータが適用される', () {
        // Arrange
        const customId = 'custom-schedule-123';
        const customTitle = 'カスタムスケジュール';
        const customDescription = 'カスタム説明';
        final customStartTime = DateTime(2024, 2, 20, 14, 0);
        final customEndTime = DateTime(2024, 2, 20, 15, 30);
        const customOwnerId = 'custom-owner-456';
        const customOwnerName = 'カスタムオーナー';

        // Act
        final schedule = BaseMock.createTestSchedule(
          id: customId,
          title: customTitle,
          description: customDescription,
          startDateTime: customStartTime,
          endDateTime: customEndTime,
          ownerId: customOwnerId,
          ownerDisplayName: customOwnerName,
        );

        // Assert
        expect(schedule.id, customId);
        expect(schedule.title, customTitle);
        expect(schedule.description, customDescription);
        expect(schedule.startDateTime, customStartTime);
        expect(schedule.endDateTime, customEndTime);
        expect(schedule.ownerId, customOwnerId);
        expect(schedule.ownerDisplayName, customOwnerName);
      });
    });

    group('スケジュールの時間関係テスト', () {
      test('開始時間が終了時間より前である', () {
        // Arrange
        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 0);

        // Act
        final schedule = BaseMock.createTestSchedule(
          startDateTime: startTime,
          endDateTime: endTime,
        );

        // Assert
        expect(schedule.startDateTime.isBefore(schedule.endDateTime), isTrue);
        expect(schedule.endDateTime.isAfter(schedule.startDateTime), isTrue);
      });

      test('同日内のスケジュールの時間差を計算できる', () {
        // Arrange
        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 30);

        // Act
        final schedule = BaseMock.createTestSchedule(
          startDateTime: startTime,
          endDateTime: endTime,
        );

        // Assert
        final duration =
            schedule.endDateTime.difference(schedule.startDateTime);
        expect(duration.inMinutes, 90); // 1時間30分 = 90分
      });

      test('複数日にまたがるスケジュールも正常に扱える', () {
        // Arrange
        final startTime = DateTime(2024, 1, 15, 23, 0);
        final endTime = DateTime(2024, 1, 16, 1, 0);

        // Act
        final schedule = BaseMock.createTestSchedule(
          startDateTime: startTime,
          endDateTime: endTime,
        );

        // Assert
        expect(schedule.startDateTime.day, 15);
        expect(schedule.endDateTime.day, 16);
        final duration =
            schedule.endDateTime.difference(schedule.startDateTime);
        expect(duration.inHours, 2);
      });
    });

    group('JSON シリアライゼーション', () {
      test('ScheduleがJSONに正しくシリアライズされる', () {
        // Arrange
        final schedule = BaseMock.createTestSchedule(
          id: 'json-test-123',
          title: 'JSONテストスケジュール',
        );

        // Act
        final json = schedule.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 'json-test-123');
        expect(json['title'], 'JSONテストスケジュール');
        expect(json['description'], 'テスト用の説明');
        expect(json['ownerId'], BaseMock.testUserId);
        expect(json['ownerDisplayName'], BaseMock.testDisplayName);
        expect(json['sharedLists'], isA<List>());
        expect(json['visibleTo'], isA<List>());
        expect(json['reactionCount'], 0);
        expect(json['commentCount'], 0);
      });

      test('JSONからScheduleが正しくデシリアライズされる', () {
        // Arrange
        final originalSchedule = BaseMock.createTestSchedule(
          id: 'deserialize-test-456',
          title: 'デシリアライズテスト',
        );
        final json = originalSchedule.toJson();

        // Act
        final deserializedSchedule = Schedule.fromJson(json);

        // Assert
        expect(deserializedSchedule.id, originalSchedule.id);
        expect(deserializedSchedule.title, originalSchedule.title);
        expect(deserializedSchedule.description, originalSchedule.description);
        expect(
            deserializedSchedule.startDateTime, originalSchedule.startDateTime);
        expect(deserializedSchedule.endDateTime, originalSchedule.endDateTime);
        expect(deserializedSchedule.ownerId, originalSchedule.ownerId);
        expect(deserializedSchedule.ownerDisplayName,
            originalSchedule.ownerDisplayName);
        expect(deserializedSchedule.sharedLists, originalSchedule.sharedLists);
        expect(deserializedSchedule.visibleTo, originalSchedule.visibleTo);
        expect(
            deserializedSchedule.reactionCount, originalSchedule.reactionCount);
        expect(
            deserializedSchedule.commentCount, originalSchedule.commentCount);
      });

      test('複雑なスケジュールデータもシリアライゼーションできる', () {
        // Arrange
        final schedule = BaseMock.createTestSchedule().copyWith(
          location: '会議室A',
          ownerPhotoUrl: 'https://example.com/owner.jpg',
          sharedLists: ['family', 'work'],
          visibleTo: ['user1', 'user2', 'user3'],
          reactionCount: 10,
          commentCount: 5,
        );

        // Act
        final json = schedule.toJson();
        final deserializedSchedule = Schedule.fromJson(json);

        // Assert
        expect(deserializedSchedule.location, schedule.location);
        expect(deserializedSchedule.ownerPhotoUrl, schedule.ownerPhotoUrl);
        expect(deserializedSchedule.sharedLists, schedule.sharedLists);
        expect(deserializedSchedule.visibleTo, schedule.visibleTo);
        expect(deserializedSchedule.reactionCount, schedule.reactionCount);
        expect(deserializedSchedule.commentCount, schedule.commentCount);
      });
    });

    group('Freezed の copyWith テスト', () {
      late Schedule originalSchedule;

      setUp(() {
        originalSchedule = BaseMock.createTestSchedule(
          title: 'オリジナルタイトル',
          description: 'オリジナル説明',
        );
      });

      test('タイトルのみ更新される', () {
        // Arrange
        const newTitle = '更新されたタイトル';

        // Act
        final updatedSchedule = originalSchedule.copyWith(title: newTitle);

        // Assert
        expect(updatedSchedule.title, newTitle);
        expect(updatedSchedule.description,
            originalSchedule.description); // 他は変更されない
        expect(updatedSchedule.id, originalSchedule.id);
        expect(updatedSchedule.ownerId, originalSchedule.ownerId);
      });

      test('複数のプロパティが同時に更新される', () {
        // Arrange
        const newTitle = '新しいタイトル';
        const newDescription = '新しい説明';
        const newLocation = '新しい場所';
        const newReactionCount = 15;

        // Act
        final updatedSchedule = originalSchedule.copyWith(
          title: newTitle,
          description: newDescription,
          location: newLocation,
          reactionCount: newReactionCount,
        );

        // Assert
        expect(updatedSchedule.title, newTitle);
        expect(updatedSchedule.description, newDescription);
        expect(updatedSchedule.location, newLocation);
        expect(updatedSchedule.reactionCount, newReactionCount);
        expect(updatedSchedule.id, originalSchedule.id); // IDは変更されない
        expect(updatedSchedule.ownerId, originalSchedule.ownerId);
      });

      test('イミュータブルであることを確認（元のオブジェクトは変更されない）', () {
        // Arrange
        const newTitle = '変更されたタイトル';
        final originalTitle = originalSchedule.title;

        // Act
        final updatedSchedule = originalSchedule.copyWith(title: newTitle);

        // Assert
        expect(originalSchedule.title, originalTitle); // 元のオブジェクトは変更されない
        expect(updatedSchedule.title, newTitle);
        expect(originalSchedule, isNot(same(updatedSchedule))); // 異なるインスタンス
      });
    });

    group('等価性テスト', () {
      test('同じプロパティを持つScheduleは等しい', () {
        // Arrange
        final schedule1 = BaseMock.createTestSchedule(id: 'same-id');
        final schedule2 = BaseMock.createTestSchedule(id: 'same-id');

        // Act & Assert
        // Freezed により自動的に等価性が実装される
        expect(schedule1 == schedule2, isTrue);
        expect(schedule1.hashCode, schedule2.hashCode);
      });

      test('異なるプロパティを持つScheduleは等しくない', () {
        // Arrange
        final schedule1 = BaseMock.createTestSchedule(id: 'id-1');
        final schedule2 = BaseMock.createTestSchedule(id: 'id-2');

        // Act & Assert
        expect(schedule1 == schedule2, isFalse);
        expect(schedule1.hashCode, isNot(schedule2.hashCode));
      });
    });

    group('境界値・特殊ケーステスト', () {
      test('極端に短い時間のスケジュール（1分間）', () {
        // Arrange
        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 10, 1);

        // Act
        final schedule = BaseMock.createTestSchedule(
          startDateTime: startTime,
          endDateTime: endTime,
        );

        // Assert
        expect(schedule.startDateTime, startTime);
        expect(schedule.endDateTime, endTime);
        final duration =
            schedule.endDateTime.difference(schedule.startDateTime);
        expect(duration.inMinutes, 1);
      });

      test('極端に長い時間のスケジュール（1週間）', () {
        // Arrange
        final startTime = DateTime(2024, 1, 1, 0, 0);
        final endTime = DateTime(2024, 1, 8, 0, 0);

        // Act
        final schedule = BaseMock.createTestSchedule(
          startDateTime: startTime,
          endDateTime: endTime,
        );

        // Assert
        expect(schedule.startDateTime, startTime);
        expect(schedule.endDateTime, endTime);
        final duration =
            schedule.endDateTime.difference(schedule.startDateTime);
        expect(duration.inDays, 7);
      });

      test('大量の共有リストとユーザーを持つスケジュール', () {
        // Arrange
        final largeSharedLists = List.generate(100, (index) => 'list-$index');
        final largeVisibleTo = List.generate(1000, (index) => 'user-$index');

        // Act
        final schedule = BaseMock.createTestSchedule().copyWith(
          sharedLists: largeSharedLists,
          visibleTo: largeVisibleTo,
        );

        // Assert
        expect(schedule.sharedLists.length, 100);
        expect(schedule.visibleTo.length, 1000);
        expect(schedule.sharedLists.first, 'list-0');
        expect(schedule.sharedLists.last, 'list-99');
        expect(schedule.visibleTo.first, 'user-0');
        expect(schedule.visibleTo.last, 'user-999');
      });
    });
  });
}
