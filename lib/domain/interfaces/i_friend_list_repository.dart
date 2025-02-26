abstract class IFriendListRepository {
  Future<List<String>?> getListMemberIds(String listId);
}
