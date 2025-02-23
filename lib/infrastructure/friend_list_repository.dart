import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/interfaces/i_friend_list_repository.dart';
import '../utils/logger.dart';

class FriendListRepository implements IFriendListRepository {
  final FirebaseFirestore _firestore;

  FriendListRepository() : _firestore = FirebaseFirestore.instance;

  @override
  Future<List<String>?> getListMemberIds(String listId) async {
    try {
      final listDoc = await _firestore.collection('lists').doc(listId).get();
      if (!listDoc.exists) {
        AppLogger.warning('List not found: $listId');
        return null;
      }

      final data = listDoc.data();
      if (data == null) {
        AppLogger.warning('List data is null: $listId');
        return null;
      }

      final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
      AppLogger.debug(
          'Retrieved ${memberIds.length} members for list: $listId');
      return memberIds;
    } catch (e) {
      AppLogger.error('Error getting list members: $e');
      return null;
    }
  }
}
