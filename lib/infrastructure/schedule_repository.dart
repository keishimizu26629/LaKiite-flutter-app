import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_repository.dart';
import '../domain/value/schedule_month_range.dart';
import '../utils/logger.dart';
import 'mapper/schedule_mapper.dart';
import 'schedule_enrichment_cache.dart';

class ScheduleRepository implements IScheduleRepository {
  ScheduleRepository()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final ScheduleEnrichmentCache _enrichmentCache = ScheduleEnrichmentCache();

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

  // リアクション数とコメント数を一括で取得（バッチ処理）
  Future<(int, int)> _fetchInteractionCounts(DocumentReference docRef) async {
    final scheduleId = docRef.id;

    final cachedCounts = _enrichmentCache.getInteractionCounts(scheduleId);
    if (cachedCounts != null) {
      return (cachedCounts.reactionCount, cachedCounts.commentCount);
    }

    // 並列でリアクション数とコメント数を取得
    final reactionsFuture = docRef.collection('reactions').count().get();
    final commentsFuture = docRef.collection('comments').count().get();

    final results = await Future.wait([reactionsFuture, commentsFuture]);
    final reactionCount = results[0].count ?? 0;
    final commentCount = results[1].count ?? 0;

    _enrichmentCache.storeInteractionCounts(
      scheduleId,
      reactionCount: reactionCount,
      commentCount: commentCount,
    );

    return (reactionCount, commentCount);
  }

  Future<Schedule> _enrichSchedule(DocumentSnapshot doc) async {
    await _ensureAuthenticated();

    try {
      // 基本的なスケジュール情報を取得
      final schedule = ScheduleMapper.fromFirestore(doc);

      // リアクション数とコメント数を一括取得
      final (reactionCount, commentCount) =
          await _fetchInteractionCounts(doc.reference);

      // リアクション数とコメント数を更新したスケジュールを作成
      final enrichedSchedule = schedule.copyWith(
        reactionCount: reactionCount,
        commentCount: commentCount,
      );

      return enrichedSchedule;
    } catch (e) {
      AppLogger.error('Error enriching schedule: $e');
      // エラーが発生した場合でも基本的なスケジュール情報は返す
      return ScheduleMapper.fromFirestore(doc);
    }
  }

  // キャッシュをクリア（必要に応じて呼び出す）
  void clearCache() {
    _enrichmentCache.clear();
  }

  // 特定のスケジュールのキャッシュを更新（更新があった場合など）
  void invalidateScheduleCache(String scheduleId) {
    _enrichmentCache.invalidateSchedule(scheduleId);
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
    final previousMonthIso = '$year-$month-${day}T00:00:00.000';

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

      // スケジュールをそのままFirestoreに保存
      final data = ScheduleMapper.toFirestore(schedule);
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

      // 作成時と同じFirestore保存形式に揃えて更新する
      final data = ScheduleMapper.toFirestore(schedule);
      AppLogger.debug('Prepared update data:');
      AppLogger.debug(data.toString());

      AppLogger.debug('Attempting to update document in Firestore');
      await _firestore.collection('schedules').doc(schedule.id).update(data);
      invalidateScheduleCache(schedule.id);
      AppLogger.debug('Schedule update completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
    invalidateScheduleCache(scheduleId);
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) {
    // 6ヶ月前の1日を計算（前月の代わりに6ヶ月前に変更）
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

    // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
    final year = sixMonthsAgo.year.toString();
    final month = sixMonthsAgo.month.toString().padLeft(2, '0');
    final day = sixMonthsAgo.day.toString().padLeft(2, '0');
    final sixMonthsAgoIso = '$year-$month-${day}T00:00:00.000';

    return _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .where('startDateTime', isGreaterThanOrEqualTo: sixMonthsAgoIso)
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

      // 6ヶ月前の1日を計算（前月の代わりに6ヶ月前に変更）
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      // 日付形式を正確に整形（必ず2桁になるようにフォーマット）
      final year = sixMonthsAgo.year.toString();
      final month = sixMonthsAgo.month.toString().padLeft(2, '0');
      final day = sixMonthsAgo.day.toString().padLeft(2, '0');
      final sixMonthsAgoIso = '$year-$month-${day}T00:00:00.000';

      final stream = _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .where('startDateTime', isGreaterThanOrEqualTo: sixMonthsAgoIso)
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

      final range = ScheduleMonthRange.forDisplayMonth(displayMonth);

      // 最初に素早くキャッシュからデータを取得（データがあれば即時返却）
      try {
        final cachedSnapshot = await _firestore
            .collection('schedules')
            .where('visibleTo', arrayContains: userId)
            .where(
              'startDateTime',
              isLessThan: range.endExclusiveIso,
            )
            .where(
              'endDateTime',
              isGreaterThanOrEqualTo: range.startInclusiveIso,
            )
            .orderBy('startDateTime', descending: false)
            .orderBy('endDateTime', descending: false)
            .get(const GetOptions(source: Source.cache));

        if (cachedSnapshot.docs.isNotEmpty) {
          // キャッシュからのデータを非同期でエンリッチして即時返却
          final cachedSchedules = (await Future.wait(
            cachedSnapshot.docs.map((doc) async {
              try {
                return await _enrichSchedule(doc);
              } catch (e) {
                // エンリッチ中のエラーは無視してマッピングのみを行う
                return ScheduleMapper.fromFirestore(doc);
              }
            }),
          ))
              .where(range.overlaps)
              .toList();

          // キャッシュデータを即時返却（早く表示するため）
          yield cachedSchedules;
        }
      } catch (e) {
        // キャッシュからの取得に失敗しても続行（サーバーから取得）
        AppLogger.debug('Cache fetch failed, continuing with server fetch: $e');
      }

      // サーバーからのリアルタイム取得（バックグラウンドで最新データを取得）
      final stream = _firestore
          .collection('schedules')
          .where('visibleTo', arrayContains: userId)
          .where(
            'startDateTime',
            isLessThan: range.endExclusiveIso,
          )
          .where(
            'endDateTime',
            isGreaterThanOrEqualTo: range.startInclusiveIso,
          )
          .orderBy('startDateTime', descending: false)
          .orderBy('endDateTime', descending: false)
          .snapshots();

      await for (final snapshot in stream) {
        try {
          // バッチ処理でエンリッチメントを高速化
          final schedules = (await _enrichSchedulesInBatches(snapshot.docs))
              .where(range.overlaps)
              .toList();
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

  // ドキュメントのバッチをより効率的に処理するヘルパーメソッド
  Future<List<Schedule>> _enrichSchedulesInBatches(
      List<DocumentSnapshot> docs) async {
    // 最大同時処理数（大きすぎると逆に遅くなる）
    const int batchSize = 10;

    final results = <Schedule>[];

    // バッチ処理
    for (int i = 0; i < docs.length; i += batchSize) {
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      final batch = docs.sublist(i, end);

      // 並列処理
      final batchResults = await Future.wait(
        batch.map((doc) async {
          try {
            return await _enrichSchedule(doc);
          } catch (e) {
            // エラー時はベーシックな情報だけでスケジュールを作成
            AppLogger.error('Error enriching schedule in batch: $e');
            return ScheduleMapper.fromFirestore(doc);
          }
        }),
      );

      results.addAll(batchResults);
    }

    return results;
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
