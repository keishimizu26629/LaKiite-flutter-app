import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class AppUser with _$AppUser {
  factory AppUser({
    required String id, // ユーザーID（ユニークで、8文字以上の文字列）
    required Profile profile, // プロフィール情報
    List<String>? friends, // フレンドリスト（ユーザーIDのリスト）
    List<String>? groups, // 所属グループリスト（グループIDのリスト）
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

@freezed
class Profile with _$Profile {
  factory Profile({
    required String name, // 表示名
    // その他プロフィール情報を追加可能
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}