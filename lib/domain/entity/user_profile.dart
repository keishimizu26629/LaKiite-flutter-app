import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// 他ユーザーにも公開されるプロフィール情報。
@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String displayName,
    required String searchId,
    String? iconUrl,
    String? shortBio,
  }) = _PublicProfile;
}

/// 本人と内部処理で扱う非公開プロフィール情報。
@freezed
class PrivateProfile with _$PrivateProfile {
  const factory PrivateProfile({
    required String name,
    required List<String> lists,
    required DateTime createdAt,
    String? fcmToken,
  }) = _PrivateProfile;
}

/// 公開プロフィール、非公開プロフィール、所属関係をまとめたユーザープロフィール。
///
/// Firestore の保存形式は持たず、変換は infrastructure の mapper が担当する。
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required PublicProfile publicProfile,
    required PrivateProfile privateProfile,
    required List<String> friends,
    required List<String> groups,
    String? fcmToken,
  }) = _UserProfile;
}
