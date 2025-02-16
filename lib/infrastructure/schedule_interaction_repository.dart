import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';

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
        print('Reaction Data from Firestore: $data');
        print('Reaction type from Firestore: ${data['type']} (${data['type'].runtimeType})');
        final reaction = ScheduleReaction.fromJson(data);
        print('Converted Reaction: $reaction');
        return reaction;
      } catch (e, stackTrace) {
        print('Error converting reaction: $e');
        print('Stack trace: $stackTrace');
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
  Future<void> addReaction(
    String scheduleId,
    String userId,
    ReactionType type,
  ) async {
    final reactionDoc = _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    await reactionDoc.set({
      'userId': userId,
      'type': type == ReactionType.going ? 'going' : 'thinking',
      'createdAt': FieldValue.serverTimestamp(),
      'userDisplayName': userData?['displayName'],
      'userPhotoUrl': userData?['photoUrl'],
    });
  }

  /// 指定された[scheduleId]と[userId]に対応するリアクションを削除
  ///
  /// `schedules/{scheduleId}/reactions/{userId}`のドキュメントを削除します。
  @override
  Future<void> removeReaction(String scheduleId, String userId) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId)
        .delete();
  }

  /// 指定された[scheduleId]のリアクションをリアルタイムで監視
  ///
  /// リアクションコレクションの変更を監視し、変更があるたびに
  /// 最新の[ScheduleReaction]のリストを提供します。
  @override
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId) {
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) {
          final reactions = snapshot.docs.map((doc) {
            try {
              final data = {...doc.data(), 'id': doc.id};
              print('Reaction Data from Firestore (Watch): $data');
              print('Reaction type from Firestore: ${data['type']} (${data['type'].runtimeType})');
              final reaction = ScheduleReaction.fromJson(data);
              print('Converted Reaction (Watch): $reaction');
              return reaction;
            } catch (e, stackTrace) {
              print('Error converting reaction: $e');
              print('Stack trace: $stackTrace');
              rethrow;
            }
          }).toList();
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
        print('Comment Data from Firestore: $data');
        final comment = ScheduleComment.fromJson(data);
        print('Converted Comment: $comment');
        return comment;
      } catch (e, stackTrace) {
        print('Error converting comment: $e');
        print('Stack trace: $stackTrace');
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
  Future<void> addComment(
    String scheduleId,
    String userId,
    String content,
  ) async {
    try {
      print('Adding comment - scheduleId: $scheduleId, userId: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      print('User data fetched: $userData');

      final commentData = {
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'userDisplayName': userData?['displayName'],
        'userPhotoUrl': userData?['photoUrl'],
      };
      print('Comment data to save: $commentData');

      await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .collection('comments')
          .add(commentData);
      print('Comment added successfully');
    } catch (e, stackTrace) {
      print('Error adding comment: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 指定された[scheduleId]と[commentId]に対応するコメントを削除
  ///
  /// `schedules/{scheduleId}/comments/{commentId}`のドキュメントを削除します。
  @override
  Future<void> deleteComment(String scheduleId, String commentId) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  /// 指定された[scheduleId]のコメントをリアルタイムで監視
  ///
  /// コメントコレクションの変更を監視し、作成日時の降順でソートされた
  /// 最新の[ScheduleComment]のリストを提供します。
  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) {
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs.map((doc) {
            try {
              final data = {...doc.data(), 'id': doc.id};
              print('Comment Data from Firestore (Watch): $data');
              final comment = ScheduleComment.fromJson(data);
              print('Converted Comment (Watch): $comment');
              return comment;
            } catch (e, stackTrace) {
              print('Error converting comment: $e');
              print('Stack trace: $stackTrace');
              rethrow;
            }
          }).toList();
          return comments;
        });
  }
}