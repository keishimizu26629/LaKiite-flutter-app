import 'package:freezed_annotation/freezed_annotation.dart';
import '../value/user_id.dart';
import '../service/user_id_generator.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  @JsonSerializable(explicitToJson: true)
  const factory UserModel({
    required String id,
    required String name,
    required String displayName,
    @JsonKey(fromJson: UserModel._searchIdFromJson, toJson: UserModel._searchIdToJson)
    required UserId searchId,
    required List<String> friends,
    String? iconUrl,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  factory UserModel.create({
    required String id,
    required String name,
  }) {
    return UserModel(
      id: id,
      name: name,
      displayName: name,
      searchId: UserIdGenerator.generateUserId(),
      friends: const [],
      iconUrl: null,
    );
  }

  static UserId _searchIdFromJson(String value) => UserId(value);
  static String _searchIdToJson(UserId userId) => userId.toString();
}
