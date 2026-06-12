import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entity/list.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_access_grant_repository.dart';
import '../domain/interfaces/i_schedule_repository.dart';
import '../domain/service/schedule_recipient_diff_calculator.dart';
import '../domain/value/schedule_month_range.dart';
import '../utils/logger.dart';
import 'encryption/schedule_encryption_service.dart';
import 'mapper/schedule_mapper.dart';
import 'schedule_enrichment_cache.dart';

class ScheduleRepository
    implements IScheduleRepository, IScheduleAccessGrantRepository {
  ScheduleRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ScheduleEncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ??
            ScheduleEncryptionService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ScheduleEncryptionService _encryptionService;

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

    final uid = _auth.currentUser!.uid;
    await _encryptionService.tryEnsureCurrentUserKey(uid);
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
      final currentUserId = _auth.currentUser!.uid;
      final decryptedDetails = await _encryptionService
          .decryptDetailsForCurrentUser(doc: doc, currentUserId: currentUserId);

      final schedule = ScheduleMapper.fromFirestore(
        doc,
        decryptedDetails: decryptedDetails,
      );

      final (reactionCount, commentCount) =
          await _fetchInteractionCounts(doc.reference);

      return schedule.copyWith(
        reactionCount: reactionCount,
        commentCount: commentCount,
      );
    } catch (e) {
      AppLogger.error('Error enriching schedule: $e');
      return ScheduleMapper.fromFirestore(doc);
    }
  }

  Future<Schedule?> _enrichScheduleIfDisplayable(DocumentSnapshot doc) async {
    await _ensureAuthenticated();

    final data = doc.data() as Map<String, dynamic>?;
    final currentUserId = _auth.currentUser!.uid;
    if (!ScheduleEncryptionService.canDecryptScheduleData(
      data,
      currentUserId: currentUserId,
    )) {
      AppLogger.debug(
        'Skipping encrypted schedule without key for current user: ${doc.id}',
      );
      return null;
    }

    return _enrichSchedule(doc);
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

    final schedules = await Future.wait(
      snapshot.docs.map((doc) => _enrichScheduleIfDisplayable(doc)),
    );
    return schedules.whereType<Schedule>().toList();
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

    final schedules = await Future.wait(
      snapshot.docs.map((doc) => _enrichScheduleIfDisplayable(doc)),
    );
    return schedules.whereType<Schedule>().toList();
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    try {
      await _ensureAuthenticated();
      AppLogger.debug(
          'ScheduleRepository: Starting encrypted schedule creation');
      AppLogger.debug('OwnerId: ${schedule.ownerId}');
      AppLogger.debug('SharedLists: ${schedule.sharedLists}');
      AppLogger.debug('VisibleTo: ${schedule.visibleTo}');

      final data = await _encryptionService.toEncryptedFirestoreData(
        schedule: schedule,
        currentUserId: _auth.currentUser!.uid,
      );

      final docRef = await _firestore.collection('schedules').add(data);
      final doc = await docRef.get();
      if (!doc.exists) {
        AppLogger.error('Created document does not exist: ${docRef.id}');
        throw Exception('Created document not found');
      }

      final enrichedSchedule = await _enrichSchedule(doc);
      AppLogger.debug('Encrypted schedule creation completed successfully');
      return enrichedSchedule;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _ensureAuthenticated();
      AppLogger.debug(
          'Starting encrypted schedule update for ID: ${schedule.id}');
      AppLogger.debug('SharedLists: ${schedule.sharedLists}');
      AppLogger.debug('VisibleTo: ${schedule.visibleTo}');

      final docRef = _firestore.collection('schedules').doc(schedule.id);
      final existingDoc = await docRef.get();
      final currentUserId = _auth.currentUser!.uid;
      final existingData = existingDoc.data();
      final beforeSharedListIds = List<String>.from(
        existingData?['sharedLists'] as List? ?? [],
      );
      final afterSharedListIds = schedule.sharedLists;
      final membersByListId = await _currentMembersByListId({
        ...beforeSharedListIds,
        ...afterSharedListIds,
      });
      final recipientDiff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: currentUserId,
        beforeSharedListIds: beforeSharedListIds,
        afterSharedListIds: afterSharedListIds,
        membersByListId: membersByListId,
      );

      if (existingDoc.exists && recipientDiff.requiresRekey) {
        await _rekeyScheduleForRecipients(
          doc: existingDoc,
          recipientIds: recipientDiff.afterRecipientIds,
          currentUserId: currentUserId,
          scheduleOverride: schedule,
        );
        invalidateScheduleCache(schedule.id);
        return;
      }

      final scheduleForEncryption = schedule.copyWith(
        visibleTo: recipientDiff.afterRecipientIds.toList(),
      );
      final data = await _encryptionService.toEncryptedFirestoreData(
        schedule: scheduleForEncryption,
        currentUserId: currentUserId,
        existingDoc: existingDoc.exists ? existingDoc : null,
      );
      data['visibleTo'] = [currentUserId];

      await docRef.update(data);
      invalidateScheduleCache(schedule.id);
      AppLogger.debug('Encrypted schedule update completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> grantListSchedulesAccessToUser({
    required String listId,
    required String userId,
  }) async {
    await _ensureAuthenticated();

    final snapshot = await _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final visibleTo = List<String>.from(data['visibleTo'] as List? ?? []);
      if (visibleTo.contains(userId)) continue;

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (data['encrypted'] == true) {
        final encryptedKey =
            await _encryptionService.encryptedScheduleKeyForAdditionalViewer(
          doc: doc,
          currentUserId: _auth.currentUser!.uid,
          viewerId: userId,
        );
        if (encryptedKey == null) {
          continue;
        }
        final encryptedKeys = Map<String, dynamic>.from(
          data['encryptedKeys'] as Map? ?? {},
        );
        encryptedKeys[userId] = encryptedKey.toJson();
        updates['encryptedKeys'] = encryptedKeys;
      }
      updates['visibleTo'] = FieldValue.arrayUnion([userId]);

      await doc.reference.update(updates);
      invalidateScheduleCache(doc.id);
    }
  }

  @override
  Future<void> syncListSchedulesAccess({
    required UserList beforeList,
    required UserList afterList,
  }) async {
    await _ensureAuthenticated();
    final currentUserId = _auth.currentUser!.uid;
    if (beforeList.ownerId != currentUserId ||
        afterList.ownerId != currentUserId) {
      return;
    }

    final today = DateTime.now();
    final todayIso =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final snapshot = await _firestore
        .collection('schedules')
        .where('ownerId', isEqualTo: currentUserId)
        .where('startDateTime', isGreaterThanOrEqualTo: todayIso)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['encrypted'] != true) {
        continue;
      }

      final sharedListIds =
          List<String>.from(data['sharedLists'] as List? ?? []);
      if (!sharedListIds.contains(afterList.id)) {
        continue;
      }

      final beforeMembersByListId = await _membersByListId(
        sharedListIds,
        changedList: beforeList,
      );
      final afterMembersByListId = await _membersByListId(
        sharedListIds,
        changedList: afterList,
      );
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: currentUserId,
        beforeSharedListIds: sharedListIds,
        afterSharedListIds: sharedListIds,
        membersByListId: beforeMembersByListId,
        afterMembersByListId: afterMembersByListId,
      );

      if (diff.hasNoKeyChange) {
        continue;
      }

      if (diff.requiresRekey) {
        await _rekeyScheduleForRecipients(
          doc: doc,
          recipientIds: diff.afterRecipientIds,
          currentUserId: currentUserId,
        );
      } else if (diff.requiresRewrap) {
        await _rewrapScheduleForAddedRecipients(
          doc: doc,
          addedUserIds: diff.addedUserIds,
          currentUserId: currentUserId,
        );
      }

      invalidateScheduleCache(doc.id);
    }
  }

  Future<Map<String, Iterable<String>>> _membersByListId(
    Iterable<String> listIds, {
    required UserList changedList,
  }) async {
    final entries = await Future.wait(listIds.map((listId) async {
      if (listId == changedList.id) {
        return MapEntry(listId, changedList.memberIds);
      }

      final doc = await _firestore.collection('lists').doc(listId).get();
      final data = doc.data();
      return MapEntry(
        listId,
        List<String>.from(data?['memberIds'] as List? ?? []),
      );
    }));
    return Map.fromEntries(entries);
  }

  Future<Map<String, Iterable<String>>> _currentMembersByListId(
    Iterable<String> listIds,
  ) async {
    final entries = await Future.wait(listIds.map((listId) async {
      final doc = await _firestore.collection('lists').doc(listId).get();
      final data = doc.data();
      return MapEntry(
        listId,
        List<String>.from(data?['memberIds'] as List? ?? []),
      );
    }));
    return Map.fromEntries(entries);
  }

  Future<void> _rewrapScheduleForAddedRecipients({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required Set<String> addedUserIds,
    required String currentUserId,
  }) async {
    final data = doc.data();
    final encryptedKeys = Map<String, dynamic>.from(
      data['encryptedKeys'] as Map? ?? {},
    );

    for (final userId in addedUserIds) {
      if (userId == currentUserId || encryptedKeys.containsKey(userId)) {
        continue;
      }

      final encryptedKey =
          await _encryptionService.encryptedScheduleKeyForAdditionalViewer(
        doc: doc,
        currentUserId: currentUserId,
        viewerId: userId,
      );
      if (encryptedKey != null) {
        encryptedKeys[userId] = encryptedKey.toJson();
      }
    }

    await doc.reference.update({
      'encryptedKeys': encryptedKeys,
      'visibleTo': [currentUserId],
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _rekeyScheduleForRecipients({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required Set<String> recipientIds,
    required String currentUserId,
    Schedule? scheduleOverride,
  }) async {
    final schedule =
        (scheduleOverride ?? await _decryptedSchedule(doc)).copyWith(
      visibleTo: recipientIds.toList(),
      updatedAt: DateTime.now(),
    );
    final commentSnapshot = await doc.reference.collection('comments').get();
    final decryptedComments = await Future.wait(
      commentSnapshot.docs.map((commentDoc) async {
        final commentData = commentDoc.data();
        final content = commentData['encrypted'] == true
            ? await _encryptionService.decryptCommentContentForCurrentUser(
                scheduleDoc: doc,
                currentUserId: currentUserId,
                commentData: commentData,
              )
            : commentData['content'] as String? ?? '';
        return MapEntry(commentDoc.reference, content);
      }),
    );

    final rekeyed = await _encryptionService.toRekeyedFirestoreData(
      schedule: schedule,
      currentUserId: currentUserId,
      existingDoc: doc,
    );
    rekeyed.scheduleData['visibleTo'] = [currentUserId];

    final batch = _firestore.batch();
    batch.update(doc.reference, rekeyed.scheduleData);
    for (final comment in decryptedComments) {
      final contentData =
          await _encryptionService.toEncryptedCommentContentDataWithScheduleKey(
        scheduleKey: rekeyed.scheduleKey,
        content: comment.value,
      );
      batch.update(comment.key, {
        ...contentData,
        'content': FieldValue.delete(),
      });
    }
    await batch.commit();
  }

  Future<Schedule> _decryptedSchedule(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final currentUserId = _auth.currentUser!.uid;
    final decryptedDetails =
        await _encryptionService.decryptDetailsForCurrentUser(
      doc: doc,
      currentUserId: currentUserId,
    );
    return ScheduleMapper.fromFirestore(
      doc,
      decryptedDetails: decryptedDetails,
    );
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
      final schedules = await Future.wait(
        snapshot.docs.map((doc) => _enrichScheduleIfDisplayable(doc)),
      );
      return schedules.whereType<Schedule>().toList();
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
            snapshot.docs.map((doc) => _enrichScheduleIfDisplayable(doc)),
          );
          yield schedules.whereType<Schedule>().toList();
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
                return await _enrichScheduleIfDisplayable(doc);
              } catch (e) {
                AppLogger.error('Error enriching cached schedule: $e');
                return null;
              }
            }),
          ))
              .whereType<Schedule>()
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
            return await _enrichScheduleIfDisplayable(doc);
          } catch (e) {
            AppLogger.error('Error enriching schedule in batch: $e');
            return null;
          }
        }),
      );

      results.addAll(batchResults.whereType<Schedule>());
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
