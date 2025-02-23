import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_repository.dart';
import '../domain/interfaces/i_friend_list_repository.dart';
import '../utils/logger.dart';

class ScheduleRepository implements IScheduleRepository {
  final FirebaseFirestore _firestore;
  final IFriendListRepository _friendListRepository;

  ScheduleRepository(this._friendListRepository)
      : _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _toFirestore(Schedule schedule) {
    return {
      'title': schedule.title,
      'description': schedule.description,
      'location': schedule.location,
      'startDateTime': Timestamp.fromDate(schedule.startDateTime),
      'endDateTime': Timestamp.fromDate(schedule.endDateTime),
      'ownerId': schedule.ownerId,
      'ownerDisplayName': schedule.ownerDisplayName,
      'ownerPhotoUrl': schedule.ownerPhotoUrl,
      'sharedLists': schedule.sharedLists,
      'visibleTo': schedule.visibleTo,
      'createdAt': schedule.id.isEmpty
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(schedule.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<Schedule> _enrichSchedule(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // リアクション数を取得
    final reactionsSnapshot =
        await doc.reference.collection('reactions').count().get();
    final reactionCount = reactionsSnapshot.count ?? 0;

    // コメント数を取得
    final commentsSnapshot =
        await doc.reference.collection('comments').count().get();
    final commentCount = commentsSnapshot.count ?? 0;

    return Schedule(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String?,
      startDateTime:
          (data['startDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDateTime:
          (data['endDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: data['ownerId'] as String,
      ownerDisplayName: data['ownerDisplayName'] as String,
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      sharedLists: List<String>.from(data['sharedLists'] as List? ?? []),
      visibleTo: List<String>.from(data['visibleTo'] as List? ?? []),
      reactionCount: reactionCount,
      commentCount: commentCount,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<List<Schedule>> getListSchedules(String listId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .orderBy('startDateTime', descending: false)
        .get(const GetOptions(source: Source.cache))
        .catchError((error) async {
      // キャッシュが利用できない場合はサーバーから取得
      return await _firestore
          .collection('schedules')
          .where('sharedLists', arrayContains: listId)
          .orderBy('startDateTime', descending: false)
          .get();
    });

    final schedules =
        await Future.wait(snapshot.docs.map((doc) => _enrichSchedule(doc)));
    return schedules;
  }

  @override
  Future<List<Schedule>> getUserSchedules(String userId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .orderBy('startDateTime', descending: false)
        .get(const GetOptions(source: Source.cache))
        .catchError((error) async {
      // キャッシュが利用できない場合はサーバーから取得
      return await _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .orderBy('startDateTime', descending: false)
          .get();
    });

    final schedules =
        await Future.wait(snapshot.docs.map((doc) => _enrichSchedule(doc)));
    return schedules;
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    try {
      AppLogger.debug('ScheduleRepository: Creating schedule with data:');
      AppLogger.debug('Title: ${schedule.title}');
      AppLogger.debug('Description: ${schedule.description}');
      AppLogger.debug('StartDateTime: ${schedule.startDateTime}');
      AppLogger.debug('EndDateTime: ${schedule.endDateTime}');
      AppLogger.debug('OwnerId: ${schedule.ownerId}');
      AppLogger.debug('OwnerDisplayName: ${schedule.ownerDisplayName}');
      AppLogger.debug('SharedLists: ${schedule.sharedLists}');
      AppLogger.debug('VisibleTo: ${schedule.visibleTo}');

      // 共有リストのメンバーを取得
      final Set<String> newVisibleTo = {...schedule.visibleTo};
      for (final listId in schedule.sharedLists) {
        AppLogger.debug('Processing list: $listId');
        try {
          final memberIds =
              await _friendListRepository.getListMemberIds(listId);
          if (memberIds != null) {
            AppLogger.debug('Adding members from list $listId: $memberIds');
            newVisibleTo.addAll(memberIds);
          }
        } catch (e) {
          // エラーが発生しても処理を続行
          continue;
        }
      }
      AppLogger.debug('Final visibleTo list: $newVisibleTo');

      final data = schedule.copyWith(visibleTo: newVisibleTo.toList()).toJson();

      AppLogger.debug('ScheduleRepository: Converted to Firestore data:');
      AppLogger.debug(data.toString());

      final docRef = await _firestore.collection('schedules').add(data);
      AppLogger.debug(
          'ScheduleRepository: Document created with ID: ${docRef.id}');

      // 作成したドキュメントを取得して返す
      final doc = await docRef.get();
      return _enrichSchedule(doc);
    } catch (e) {
      AppLogger.error('ScheduleRepository: Error creating schedule: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      AppLogger.debug('Updating schedule: ${schedule.id}');
      AppLogger.debug('Current sharedLists: ${schedule.sharedLists}');

      // 共有リストのメンバーを取得
      final Set<String> newVisibleTo = {...schedule.visibleTo};
      for (final listId in schedule.sharedLists) {
        AppLogger.debug('Processing list: $listId');
        try {
          final memberIds =
              await _friendListRepository.getListMemberIds(listId);
          if (memberIds != null) {
            AppLogger.debug('Adding members from list $listId: $memberIds');
            newVisibleTo.addAll(memberIds);
          }
        } catch (e) {
          // エラーが発生しても処理を続行
          continue;
        }
      }
      AppLogger.debug('Final visibleTo list: $newVisibleTo');

      final data = schedule.copyWith(visibleTo: newVisibleTo.toList()).toJson();
      await _firestore.collection('schedules').doc(schedule.id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) {
    return _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final schedules =
          await Future.wait(snapshot.docs.map((doc) => _enrichSchedule(doc)));
      return schedules;
    });
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    AppLogger.debug(
        'ScheduleRepository: watchUserSchedules called for user: $userId');

    final query = _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .orderBy('startDateTime', descending: false);

    AppLogger.debug('ScheduleRepository: Query: ${query.parameters}');

    return query.snapshots().asyncMap((snapshot) async {
      AppLogger.debug(
          'ScheduleRepository: Received snapshot with ${snapshot.docs.length} documents');
      final schedules =
          await Future.wait(snapshot.docs.map((doc) => _enrichSchedule(doc)));
      return schedules;
    });
  }

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) {
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      return _enrichSchedule(doc);
    });
  }
}
