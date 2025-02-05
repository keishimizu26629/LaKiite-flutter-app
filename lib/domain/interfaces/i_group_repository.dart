import 'package:tarakite/domain/entity/group.dart';

abstract class IGroupRepository {
  Future<List<Group>> getGroups();
  Future<Group> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String createdBy,
  });
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<void> addMember(String groupId, String userId);
  Future<void> removeMember(String groupId, String userId);
  Stream<List<Group>> watchUserGroups(String userId);
}
