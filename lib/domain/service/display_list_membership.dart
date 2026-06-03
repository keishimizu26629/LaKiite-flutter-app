import 'package:lakiite/domain/entity/display_list.dart';

class DisplayListMembership {
  const DisplayListMembership._();

  static DisplayList? findListForUser({
    required Iterable<DisplayList> displayLists,
    required String userId,
  }) {
    for (final displayList in displayLists) {
      if (displayList.memberIds.contains(userId)) {
        return displayList;
      }
    }
    return null;
  }

  static DisplayList? findConflictingList({
    required Iterable<DisplayList> displayLists,
    required String targetListId,
    required String userId,
  }) {
    for (final displayList in displayLists) {
      if (displayList.id == targetListId) {
        continue;
      }
      if (displayList.memberIds.contains(userId)) {
        return displayList;
      }
    }
    return null;
  }
}
