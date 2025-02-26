import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_repository.dart';
import '../domain/interfaces/i_friend_list_repository.dart';
import '../utils/logger.dart';
import 'mapper/schedule_mapper.dart';

class ScheduleRepository implements IScheduleRepository {
  final FirebaseFirestore _firestore;
  final IFriendListRepository _friendListRepository;
  final FirebaseAuth _auth;

  ScheduleRepository(this._friendListRepository)
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance;

  Future<void> _ensureAuthenticated() async {
    // 認証の初期化を待つ
    if (_auth.currentUser == null) {
      AppLogger.debug('Waiting for auth initialization...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_auth.currentUser == null) {
        throw Exception('User not authenticated');
      }
    }
  }

  Future<Schedule> _enrichSchedule(DocumentSnapshot doc) async {
    await _ensureAuthenticated();

    try {
      // リアクション数を取得
      final reactionsSnapshot =
          await doc.reference.collection('reactions').count().get();
      final reactionCount = reactionsSnapshot.count ?? 0;

      // コメント数を取得
      final commentsSnapshot =
          await doc.reference.collection('comments').count().get();
      final commentCount = commentsSnapshot.count ?? 0;

      // 基本的なスケジュール情報を取得
      final schedule = ScheduleMapper.fromFirestore(doc);

      // リアクション数とコメント数を更新
      return schedule.copyWith(
        reactionCount: reactionCount,
        commentCount: commentCount,
      );
    } catch (e) {
      AppLogger.error('Error enriching schedule: $e');
      // エラーが発生した場合でも基本的なスケジュール情報は返す
      return ScheduleMapper.fromFirestore(doc);
    }
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
    // 前月の1日を計算
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
    final year = previousMonth.year.toString();
    final month = previousMonth.month.toString().padLeft(2, '0');
    final day = previousMonth.day.toString().padLeft(2, '0');
    final previousMonthIso = "$year-$month-${day}T00:00:00.000";

    final snapshot = await _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .where('startDateTime', isGreaterThanOrEqualTo: previousMonthIso)
        .orderBy('startDateTime', descending: false)
        .get(const GetOptions(source: Source.cache))
        .catchError((error) async {
      // キャッシュが利用できない場合はサーバーから取得
      return await _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .where('startDateTime', isGreaterThanOrEqualTo: previousMonthIso)
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
      AppLogger.debug('ScheduleRepository: Starting schedule creation');
      AppLogger.debug('Schedule details:');
      AppLogger.debug('Title: ${schedule.title}');
      AppLogger.debug('Description: ${schedule.description}');
      AppLogger.debug('Location: ${schedule.location}');
      AppLogger.debug('StartDateTime: ${schedule.startDateTime}');
      AppLogger.debug('EndDateTime: ${schedule.endDateTime}');
      AppLogger.debug('OwnerId: ${schedule.ownerId}');
      AppLogger.debug('OwnerDisplayName: ${schedule.ownerDisplayName}');
      AppLogger.debug('OwnerPhotoUrl: ${schedule.ownerPhotoUrl}');
      AppLogger.debug('SharedLists: ${schedule.sharedLists}');
      AppLogger.debug('VisibleTo: ${schedule.visibleTo}');
      AppLogger.debug('CreatedAt: ${schedule.createdAt}');
      AppLogger.debug('UpdatedAt: ${schedule.updatedAt}');

      // 共有リストのメンバーを取得
      final Set<String> newVisibleTo = {...schedule.visibleTo};
      AppLogger.debug('Processing shared lists for visibility');
      for (final listId in schedule.sharedLists) {
        AppLogger.debug('Processing list ID: $listId');
        try {
          final memberIds =
              await _friendListRepository.getListMemberIds(listId);
          if (memberIds != null) {
            AppLogger.debug('Retrieved members for list $listId: $memberIds');
            newVisibleTo.addAll(memberIds);
          } else {
            AppLogger.warning('No members found for list: $listId');
          }
        } catch (e) {
          AppLogger.error('Error processing list $listId: $e');
          continue;
        }
      }
      AppLogger.debug('Final visibleTo list after processing: $newVisibleTo');

      final updatedSchedule =
          schedule.copyWith(visibleTo: newVisibleTo.toList());
      final data = ScheduleMapper.toFirestore(updatedSchedule);
      AppLogger.debug('Prepared Firestore data:');
      AppLogger.debug(data.toString());

      AppLogger.debug('Attempting to create document in Firestore');
      final docRef = await _firestore.collection('schedules').add(data);
      AppLogger.debug('Document created with ID: ${docRef.id}');

      AppLogger.debug('Fetching created document');
      final doc = await docRef.get();
      if (!doc.exists) {
        AppLogger.error('Created document does not exist: ${docRef.id}');
        throw Exception('Created document not found');
      }

      AppLogger.debug('Enriching schedule data');
      final enrichedSchedule = await _enrichSchedule(doc);
      AppLogger.debug('Schedule creation completed successfully');
      return enrichedSchedule;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      AppLogger.debug('Starting schedule update for ID: ${schedule.id}');
      AppLogger.debug('Current schedule details:');
      AppLogger.debug('Title: ${schedule.title}');
      AppLogger.debug('Description: ${schedule.description}');
      AppLogger.debug('Location: ${schedule.location}');
      AppLogger.debug('StartDateTime: ${schedule.startDateTime}');
      AppLogger.debug('EndDateTime: ${schedule.endDateTime}');
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
          } else {
            AppLogger.warning('No members found for list: $listId');
          }
        } catch (e) {
          AppLogger.error('Error processing list $listId: $e');
          continue;
        }
      }
      AppLogger.debug('Final visibleTo list: $newVisibleTo');

      final data = schedule.copyWith(visibleTo: newVisibleTo.toList()).toJson();
      AppLogger.debug('Prepared update data:');
      AppLogger.debug(data.toString());

      AppLogger.debug('Attempting to update document in Firestore');
      await _firestore.collection('schedules').doc(schedule.id).update(data);
      AppLogger.debug('Schedule update completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) {
    // 前月の1日を計算
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
    final year = previousMonth.year.toString();
    final month = previousMonth.month.toString().padLeft(2, '0');
    final day = previousMonth.day.toString().padLeft(2, '0');
    final previousMonthIso = "$year-$month-${day}T00:00:00.000";

    return _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .where('startDateTime', isGreaterThanOrEqualTo: previousMonthIso)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final schedules =
          await Future.wait(snapshot.docs.map((doc) => _enrichSchedule(doc)));
      return schedules;
    });
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) async* {
    try {
      await _ensureAuthenticated();

      // 前月の1日を計算
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);

      // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
      final year = previousMonth.year.toString();
      final month = previousMonth.month.toString().padLeft(2, '0');
      final day = previousMonth.day.toString().padLeft(2, '0');
      final previousMonthIso = "$year-$month-${day}T00:00:00.000";

      final stream = _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .where('startDateTime', isGreaterThanOrEqualTo: previousMonthIso)
          .orderBy('startDateTime', descending: false)
          .snapshots();

      await for (final snapshot in stream) {
        try {
          final schedules = await Future.wait(
            snapshot.docs.map((doc) => _enrichSchedule(doc)),
          );
          yield schedules;
        } catch (e) {
          AppLogger.error('Error processing schedule snapshot: $e');
          // エラーが発生した場合は空のリストを返す
          yield [];
        }
      }
    } catch (e) {
      AppLogger.error('Error in watchUserSchedules: $e');
      yield [];
    }
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
      String userId, DateTime displayMonth) async* {
    try {
      await _ensureAuthenticated();

      // 表示月の前月の1日を計算
      final previousMonth =
          DateTime(displayMonth.year, displayMonth.month - 1, 1);

      // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
      final year = previousMonth.year.toString();
      final month = previousMonth.month.toString().padLeft(2, '0');
      final day = previousMonth.day.toString().padLeft(2, '0');
      final previousMonthIso = "$year-$month-${day}T00:00:00.000";

      AppLogger.debug(
          'Fetching schedules from: $previousMonthIso for display month: ${displayMonth.year}-${displayMonth.month}');

      final stream = _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .where('startDateTime', isGreaterThanOrEqualTo: previousMonthIso)
          .orderBy('startDateTime', descending: false)
          .snapshots();

      await for (final snapshot in stream) {
        try {
          final schedules = await Future.wait(
            snapshot.docs.map((doc) => _enrichSchedule(doc)),
          );
          AppLogger.debug(
              'Retrieved ${schedules.length} schedules for month: ${displayMonth.year}-${displayMonth.month}');
          yield schedules;
        } catch (e) {
          AppLogger.error('Error processing schedule snapshot for month: $e');
          // エラーが発生した場合は空のリストを返す
          yield [];
        }
      }
    } catch (e) {
      AppLogger.error('Error in watchUserSchedulesForMonth: $e');
      yield [];
    }
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
