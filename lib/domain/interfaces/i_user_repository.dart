import 'dart:typed_data';
import '../entity/user.dart';
import '../value/user_id.dart';

abstract class IUserRepository {
  Future<UserModel?> getUser(String id);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes);
  Future<void> deleteUserIcon(String userId);
  Future<bool> isUserIdUnique(UserId userId);
  Future<UserModel?> findByUserId(UserId userId);
}
