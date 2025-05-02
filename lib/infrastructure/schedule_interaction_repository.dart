import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import '../utils/logger.dart';

/// スケジュールの相互作用（リアクション・コメント）に関するデータアクセスを管理
///
/// [FirebaseFirestore]を使用してスケジュールに対するリアクションとコメントの
/// 作成、取得、更新、削除、およびリアルタイム監視を行います。
class ScheduleInteractionRepository implements IScheduleInteractionRepository {
  /// Firestoreのインスタンス
  final FirebaseFirestore _firestore;

  /// [ScheduleInteractionRepository]のコンストラクタ
  ///
  /// [firestore]が指定されない場合は、デフォルトのインスタンスを使用します。
  /// テスト時にモックの[FirebaseFirestore]インスタンスを注入できます。
  ScheduleInteractionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// スケジュールのカウンターを更新する内部メソッド
  Future<void> _updateScheduleCounters(String scheduleId) async {
    AppLogger.debug('Updating schedule counters for scheduleId: $scheduleId');

    try {
      await _firestore.runTransaction((transaction) async {
        final scheduleRef = _firestore.collection('schedules').doc(scheduleId);

        // リアクション数を取得
        final reactionsSnapshot = await _firestore
            .collection('schedules')
            .doc(scheduleId)
            .collection('reactions')
            .get();
        final reactionCount = reactionsSnapshot.docs.length;
        AppLogger.debug('Current reaction count: $reactionCount');

        // コメント数を取得
        final commentsSnapshot = await _firestore
            .collection('schedules')
            .doc(scheduleId)
            .collection('comments')
            .get();
        final commentCount = commentsSnapshot.docs.length;
        AppLogger.debug('Current comment count: $commentCount');

        // スケジュールドキュメントを更新
        transaction.update(scheduleRef, {
          'reactionCount': reactionCount,
          'commentCount': commentCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppLogger.debug('Schedule counters updated in transaction');
      }, maxAttempts: 3);

      AppLogger.debug('Schedule counters transaction completed successfully');
    } catch (e, stack) {
      AppLogger.error('Error updating schedule counters: $e');
      AppLogger.error('Stack trace: $stack');
      rethrow;
    }
  }

  /// 指定された[scheduleId]に関連する全リアクションを取得
  ///
  /// Firestoreから`schedules/{scheduleId}/reactions`コレクションの
  /// ドキュメントを取得し、[ScheduleReaction]のリストに変換します。
  @override
  Future<List<ScheduleReaction>> getReactions(String scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .get();

    final reactions = snapshot.docs.map((doc) {
      try {
        final data = {...doc.data(), 'id': doc.id};
        AppLogger.debug('Reaction Data from Firestore: $data');
        AppLogger.debug(
            'Reaction type from Firestore: ${data['type']} (${data['type'].runtimeType})');
        final reaction = ScheduleReaction.fromJson(data);
        AppLogger.debug('Converted Reaction: $reaction');
        return reaction;
      } catch (e, stackTrace) {
        AppLogger.error('Error converting reaction: $e');
        AppLogger.error('Stack trace: $stackTrace');
        rethrow;
      }
    }).toList();
    return reactions;
  }

  /// 指定された[scheduleId]のスケジュールに新しいリアクションを追加
  ///
  /// [userId]をドキュメントIDとして使用し、ユーザーごとに1つのリアクションのみを
  /// 許可します。[type]には'going'または'thinking'が指定可能です。
  @override
  Future<String> addReaction(
    String scheduleId,
    String userId,
    ReactionType type,
  ) async {
    AppLogger.debug(
        'addReaction: Adding reaction for schedule: $scheduleId, user: $userId, type: $type');
    final reactionDoc = _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    AppLogger.debug('User data fetched: $userData');

    final now = Timestamp.now();
    final reactionData = {
      'userId': userId,
      'type': type == ReactionType.going ? 'going' : 'thinking',
      'createdAt': now,
      'userDisplayName': userData?['displayName'],
      'userPhotoUrl': userData?['iconUrl'],
    };
    AppLogger.debug('Reaction data to save: $reactionData');

    await reactionDoc.set(reactionData);
    AppLogger.debug(
        'addReaction: Successfully added reaction with createdAt: $now');

    // カウンターはCloud Functionsで自動的に更新されるため削除
    // await _updateScheduleCounters(scheduleId);
    AppLogger.debug(
        'Reaction added - counter will be updated by Cloud Functions');

    return userId;
  }

  /// 指定された[scheduleId]と[userId]に対応するリアクションを削除
  ///
  /// `schedules/{scheduleId}/reactions/{userId}`のドキュメントを削除します。
  @override
  Future<void> removeReaction(String scheduleId, String userId) async {
    AppLogger.debug(
        'Removing reaction - scheduleId: $scheduleId, userId: $userId');
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId)
        .delete();
    AppLogger.debug('Successfully removed reaction for user: $userId');

    // カウンターはCloud Functionsで自動的に更新されるため削除
    // await _updateScheduleCounters(scheduleId);
    AppLogger.debug(
        'Reaction removed - counter will be updated by Cloud Functions');
  }

  /// 指定された[scheduleId]のリアクションをリアルタイムで監視
  ///
  /// リアクションコレクションの変更を監視し、変更があるたびに
  /// 最新の[ScheduleReaction]のリストを提供します。
  @override
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId) {
    AppLogger.debug(
        'watchReactions: Starting to watch reactions for schedule: $scheduleId');

    // スナップショットごとの変更をカウントするカウンター
    int snapshotCounter = 0;

    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      snapshotCounter++;
      AppLogger.debug(
          'watchReactions: Snapshot #$snapshotCounter received with ${snapshot.docs.length} documents');
      AppLogger.debug(
          'watchReactions: Document changes: ${snapshot.docChanges.length}');

      // 変更の詳細をログ出力
      for (var change in snapshot.docChanges) {
        final changeType = change.type.toString();
        final docId = change.doc.id;
        final docData = change.doc.data();
        AppLogger.debug('Document change - type: $changeType, doc ID: $docId');
        AppLogger.debug('Document data: $docData');
      }

      final reactions = snapshot.docs.map((doc) {
        try {
          final originalData = doc.data();
          AppLogger.debug('Original Firestore data: $originalData');

          final data = {...originalData, 'id': doc.id};
          AppLogger.debug('Reaction Data with ID added: $data');

          // 型情報を詳細に確認
          final typeValue = data['type'];
          final typeType = typeValue?.runtimeType;
          AppLogger.debug(
              'Reaction type value: "$typeValue" (type: $typeType)');

          // createdAtの情報確認
          final createdAtValue = data['createdAt'];
          final createdAtType = createdAtValue?.runtimeType;
          AppLogger.debug('createdAt value type: $createdAtType');

          final reaction = ScheduleReaction.fromJson(data);
          AppLogger.debug(
              'Successfully converted to ScheduleReaction: $reaction');
          return reaction;
        } catch (e, stackTrace) {
          AppLogger.error('Error converting reaction: $e');
          AppLogger.error('Stack trace: $stackTrace');
          rethrow;
        }
      }).toList();

      AppLogger.debug(
          'watchReactions: Converted ${reactions.length} reactions');

      // 結果確認
      if (reactions.isNotEmpty) {
        AppLogger.debug('First reaction in list: ${reactions.first}');
      }

      return reactions;
    });
  }

  /// 指定された[scheduleId]に関連する全コメントを取得
  ///
  /// コメントは作成日時の降順でソートされ、[ScheduleComment]のリストとして返されます。
  @override
  Future<List<ScheduleComment>> getComments(String scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    final comments = snapshot.docs.map((doc) {
      try {
        final data = {...doc.data(), 'id': doc.id};
        AppLogger.debug('Comment Data from Firestore: $data');
        final comment = ScheduleComment.fromJson(data);
        AppLogger.debug('Converted Comment: $comment');
        return comment;
      } catch (e, stackTrace) {
        AppLogger.error('Error converting comment: $e');
        AppLogger.error('Stack trace: $stackTrace');
        rethrow;
      }
    }).toList();
    return comments;
  }

  /// 指定された[scheduleId]のスケジュールに新しいコメントを追加
  ///
  /// [userId]に対応するユーザー情報（表示名、プロフィール画像URL）も
  /// コメントと共に保存されます。
  @override
  Future<String> addComment(
    String scheduleId,
    String userId,
    String content,
  ) async {
    try {
      AppLogger.debug(
          'Adding comment - scheduleId: $scheduleId, userId: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      AppLogger.debug('User data fetched: $userData');

      final now = Timestamp.now();
      final commentData = {
        'userId': userId,
        'content': content,
        'createdAt': now,
        'userDisplayName': userData?['displayName'],
        'userPhotoUrl': userData?['iconUrl'],
      };
      AppLogger.debug('Comment data to save: $commentData');

      final docRef = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .collection('comments')
          .add(commentData);
      AppLogger.debug('Comment added successfully with ID: ${docRef.id}');

      // カウンターを更新
      await _updateScheduleCounters(scheduleId);

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding comment: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 指定された[scheduleId]と[commentId]に対応するコメントを削除
  ///
  /// `schedules/{scheduleId}/comments/{commentId}`のドキュメントを削除します。
  @override
  Future<void> deleteComment(String scheduleId, String commentId) async {
    AppLogger.debug(
        'Deleting comment - scheduleId: $scheduleId, commentId: $commentId');
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .doc(commentId)
        .delete();
    AppLogger.debug('Successfully deleted comment: $commentId');

    // カウンターを更新
    await _updateScheduleCounters(scheduleId);
  }

  /// 指定された[scheduleId]のコメントをリアルタイムで監視
  ///
  /// コメントコレクションの変更を監視し、作成日時の降順でソートされた
  /// 最新の[ScheduleComment]のリストを提供します。
  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) {
    AppLogger.debug('Watching comments for schedule: $scheduleId');
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.debug(
          'Received comment snapshot with ${snapshot.docs.length} documents');
      final comments = snapshot.docs.map((doc) {
        try {
          final data = {...doc.data(), 'id': doc.id};
          AppLogger.debug('Comment Data from Firestore (Watch): $data');
          final comment = ScheduleComment.fromJson(data);
          AppLogger.debug('Converted Comment (Watch): $comment');
          return comment;
        } catch (e, stackTrace) {
          AppLogger.error('Error converting comment: $e');
          AppLogger.error('Stack trace: $stackTrace');
          rethrow;
        }
      }).toList();
      AppLogger.debug('Converted ${comments.length} comments');
      return comments;
    });
  }
}
