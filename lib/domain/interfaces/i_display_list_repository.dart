import 'package:lakiite/domain/entity/display_list.dart';

abstract class IDisplayListRepository {
  Future<List<DisplayList>> getDisplayLists(String ownerId);

  Stream<List<DisplayList>> watchDisplayLists(String ownerId);

  Future<DisplayList> createDisplayList({
    required String ownerId,
    required String name,
    required String colorKey,
    required List<String> memberIds,
  });

  Future<void> updateDisplayList(DisplayList displayList);

  Future<void> deleteDisplayList({
    required String ownerId,
    required String displayListId,
  });

  Future<void> addMember({
    required String ownerId,
    required String displayListId,
    required String userId,
  });

  Future<void> removeMember({
    required String ownerId,
    required String displayListId,
    required String userId,
  });
}
