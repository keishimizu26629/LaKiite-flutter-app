import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/user_profile.dart';
import 'package:lakiite/infrastructure/mapper/user_profile_mapper.dart';

void main() {
  group('UserProfileMapper', () {
    test('Firestore dataからUserProfileを復元する', () {
      final createdAt = DateTime(2026);

      final profile = UserProfileMapper.fromFirestore(
        id: 'user-1',
        data: {
          'displayName': 'Display Name',
          'searchId': 'SEARCH01',
          'iconUrl': 'https://example.com/icon.png',
          'shortBio': 'bio',
          'private': {
            'name': 'Private Name',
            'lists': ['list-1'],
            'createdAt': Timestamp.fromDate(createdAt),
            'fcmToken': 'token-1',
          },
          'friends': ['friend-1'],
          'groups': ['group-1'],
          'fcmToken': 'root-token',
        },
      );

      expect(profile.id, 'user-1');
      expect(profile.publicProfile.displayName, 'Display Name');
      expect(profile.publicProfile.searchId, 'SEARCH01');
      expect(profile.privateProfile.name, 'Private Name');
      expect(profile.privateProfile.createdAt, createdAt);
      expect(profile.friends, ['friend-1']);
      expect(profile.groups, ['group-1']);
    });

    test('UserProfileをFirestore保存用dataへ変換する', () {
      final createdAt = DateTime(2026);
      const publicProfile = PublicProfile(
        displayName: 'Display Name',
        searchId: 'SEARCH01',
        shortBio: 'bio',
      );
      final privateProfile = PrivateProfile(
        name: 'Private Name',
        lists: const ['list-1'],
        createdAt: createdAt,
      );
      final profile = UserProfile(
        id: 'user-1',
        publicProfile: publicProfile,
        privateProfile: privateProfile,
        friends: const ['friend-1'],
        groups: const ['group-1'],
      );

      final data = UserProfileMapper.toFirestore(profile);

      expect(data, isNot(contains('id')));
      expect(data['displayName'], 'Display Name');
      expect(data['searchId'], 'SEARCH01');
      expect(data['private'], isA<Map<String, dynamic>>());
      expect((data['private'] as Map<String, dynamic>)['createdAt'],
          Timestamp.fromDate(createdAt));
      expect(data['friends'], ['friend-1']);
      expect(data['groups'], ['group-1']);
    });
  });
}
