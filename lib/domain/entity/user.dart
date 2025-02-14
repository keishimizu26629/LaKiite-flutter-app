import 'package:freezed_annotation/freezed_annotation.dart';
import '../value/user_id.dart';
import '../service/user_id_generator.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// UserIdのJSON変換を行うコンバーター
class UserIdConverter implements JsonConverter<UserId, String> {
  const UserIdConverter();

  @override
  UserId fromJson(String json) => UserId(json);

  @override
  String toJson(UserId userId) => userId.toString();
}

/// ユーザーの公開情報を表現するモデルクラス
@freezed
class PublicUserModel with _$PublicUserModel {
  const factory PublicUserModel({
    required String id,
    required String displayName,
    @UserIdConverter()
    required UserId searchId,
    String? iconUrl,
  }) = _PublicUserModel;

  const PublicUserModel._();

  factory PublicUserModel.fromJson(Map<String, dynamic> json) =>
      _$PublicUserModelFromJson(json);
}

/// ユーザーの非公開情報を表現するモデルクラス
@freezed
class PrivateUserModel with _$PrivateUserModel {
  const factory PrivateUserModel({
    required String id,
    required String name,
    required List<String> friends,
    required List<String> groups,
    required List<String> lists,
    required DateTime createdAt,
  }) = _PrivateUserModel;

  const PrivateUserModel._();

  factory PrivateUserModel.fromJson(Map<String, dynamic> json) =>
      _$PrivateUserModelFromJson(json);
}

/// ユーザー情報を表現するモデルクラス
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required PublicUserModel publicProfile,
    required PrivateUserModel privateProfile,
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.create({
    required String id,
    required String name,
  }) {
    final searchId = UserIdGenerator.generateUserId();
    return UserModel(
      publicProfile: PublicUserModel(
        id: id,
        displayName: name,
        searchId: searchId,
        iconUrl: null,
      ),
      privateProfile: PrivateUserModel(
        id: id,
        name: name,
        friends: const [],
        groups: const [],
        lists: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  String get id => privateProfile.id;
  String get name => privateProfile.name;
  String get displayName => publicProfile.displayName;
  UserId get searchId => publicProfile.searchId;
  List<String> get friends => privateProfile.friends;
  List<String> get groups => privateProfile.groups;
  String? get iconUrl => publicProfile.iconUrl;
  DateTime get createdAt => privateProfile.createdAt;

  UserModel updateProfile({
    String? name,
    String? displayName,
    UserId? searchId,
    String? iconUrl,
  }) {
    return UserModel(
      publicProfile: PublicUserModel(
        id: this.id,
        displayName: displayName ?? this.displayName,
        searchId: searchId ?? this.searchId,
        iconUrl: iconUrl ?? this.iconUrl,
      ),
      privateProfile: PrivateUserModel(
        id: this.id,
        name: name ?? this.name,
        friends: this.friends,
        groups: this.groups,
        lists: this.privateProfile.lists,
        createdAt: this.createdAt,
      ),
    );
  }
}

/// ユーザー検索結果を表現するモデルクラス
class SearchUserModel {
  final String id;
  final String displayName;
  final String searchId;
  final String? iconUrl;

  const SearchUserModel({
    required this.id,
    required this.displayName,
    required this.searchId,
    this.iconUrl,
  });

  factory SearchUserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SearchUserModel(
      id: id,
      displayName: data['displayName'] as String,
      searchId: data['searchId'] as String,
      iconUrl: data['iconUrl'] as String?,
    );
  }

  factory SearchUserModel.fromUserModel(UserModel user) {
    return SearchUserModel(
      id: user.id,
      displayName: user.displayName,
      searchId: user.searchId.toString(),
      iconUrl: user.iconUrl,
    );
  }
}
