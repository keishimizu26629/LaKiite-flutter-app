import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/user_profile.dart';

/// Firestore のユーザープロフィールデータと domain model を相互変換する mapper。
class UserProfileMapper {
  const UserProfileMapper._();

  /// Firestore のドキュメント ID とデータから [UserProfile] を生成する。
  static UserProfile fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return UserProfile(
      id: id,
      publicProfile: PublicProfile(
        displayName: data['displayName'] as String,
        searchId: data['searchId'] as String,
        iconUrl: data['iconUrl'] as String?,
        shortBio: data['shortBio'] as String?,
      ),
      privateProfile: _privateProfileFromFirestore(
        data['private'] as Map<String, dynamic>? ?? const {},
      ),
      friends: List<String>.from(data['friends'] ?? []),
      groups: List<String>.from(data['groups'] ?? []),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  /// [UserProfile] を Firestore 保存用の Map に変換する。
  ///
  /// ドキュメント ID として扱う [UserProfile.id] は保存データに含めない。
  static Map<String, dynamic> toFirestore(UserProfile profile) {
    return {
      ..._publicProfileToFirestore(profile.publicProfile),
      'private': _privateProfileToFirestore(profile.privateProfile),
      'friends': profile.friends,
      'groups': profile.groups,
      if (profile.fcmToken != null) 'fcmToken': profile.fcmToken,
    };
  }

  static PrivateProfile _privateProfileFromFirestore(
    Map<String, dynamic> data,
  ) {
    return PrivateProfile(
      name: data['name'] as String? ?? '',
      lists: List<String>.from(data['lists'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  static Map<String, dynamic> _publicProfileToFirestore(
    PublicProfile profile,
  ) {
    return {
      'displayName': profile.displayName,
      'searchId': profile.searchId,
      if (profile.iconUrl != null) 'iconUrl': profile.iconUrl,
      if (profile.shortBio != null) 'shortBio': profile.shortBio,
    };
  }

  static Map<String, dynamic> _privateProfileToFirestore(
    PrivateProfile profile,
  ) {
    return {
      'name': profile.name,
      'lists': profile.lists,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      if (profile.fcmToken != null) 'fcmToken': profile.fcmToken,
    };
  }
}
