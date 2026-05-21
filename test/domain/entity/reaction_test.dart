import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/reaction.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';

void main() {
  group('Reaction', () {
    test('Firestore JSONのtypeをReactionTypeとして復元する', () {
      final reaction = Reaction.fromJson({
        'id': 'reaction-1',
        'scheduleId': 'schedule-1',
        'userId': 'user-1',
        'type': 'going',
        'userDisplayName': 'User One',
        'userPhotoUrl': null,
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      });

      expect(reaction.type, ReactionType.going);
    });

    test('ReactionTypeをFirestore JSONのtype文字列へ変換する', () {
      final reaction = Reaction(
        id: 'reaction-1',
        scheduleId: 'schedule-1',
        userId: 'user-1',
        type: ReactionType.thinking,
        userDisplayName: 'User One',
        createdAt: DateTime(2026),
      );

      expect(reaction.toJson()['type'], 'thinking');
    });
  });
}
