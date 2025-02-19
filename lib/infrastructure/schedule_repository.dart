import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_repository.dart';

class ScheduleRepository implements IScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository() : _firestore = FirebaseFirestore.instance;

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
      'createdAt': schedule.id.isEmpty ? FieldValue.serverTimestamp() : Timestamp.fromDate(schedule.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<Schedule> _enrichSchedule(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // リアクション数を取得
    final reactionsSnapshot = await doc.reference.collection('reactions').count().get();
    final reactionCount = reactionsSnapshot.count ?? 0;

    // コメント数を取得
    final commentsSnapshot = await doc.reference.collection('comments').count().get();
    final commentCount = commentsSnapshot.count ?? 0;

    return Schedule(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String?,
      startDateTime: (data['startDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDateTime: (data['endDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

    final schedules = await Future.wait(
      snapshot.docs.map((doc) => _enrichSchedule(doc))
    );
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

    final schedules = await Future.wait(
      snapshot.docs.map((doc) => _enrichSchedule(doc))
    );
    return schedules;
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    print('ScheduleRepository: Creating schedule with data:');
    print('Title: ${schedule.title}');
    print('Description: ${schedule.description}');
    print('StartDateTime: ${schedule.startDateTime}');
    print('EndDateTime: ${schedule.endDateTime}');
    print('OwnerId: ${schedule.ownerId}');
    print('OwnerDisplayName: ${schedule.ownerDisplayName}');
    print('SharedLists: ${schedule.sharedLists}');
    print('VisibleTo: ${schedule.visibleTo}');

    try {
      final data = _toFirestore(schedule);
      print('ScheduleRepository: Converted to Firestore data:');
      print(data);

      final docRef = await _firestore.collection('schedules').add(data);
      print('ScheduleRepository: Document created with ID: ${docRef.id}');

      // 作成後にキャッシュを更新するため、サーバーから最新データを取得
      final doc = await docRef.get(const GetOptions(source: Source.server));
      return _enrichSchedule(doc);
    } catch (e) {
      print('ScheduleRepository: Error creating schedule: $e');
      throw e;
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    print('Updating schedule: ${schedule.id}');
    print('Current sharedLists: ${schedule.sharedLists}');

    // 常に新しいvisibleToリストを作成（ownerIdのみを含む）
    List<String> newVisibleTo = [schedule.ownerId];

    // 選択されているリストのメンバーを追加
    for (String listId in schedule.sharedLists) {
      print('Processing list: $listId');
      final listDoc = await _firestore
          .collection('lists')
          .doc(listId)
          .get();

      if (listDoc.exists) {
        final listData = listDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(listData['memberIds'] as List? ?? []);
        print('Adding members from list $listId: $memberIds');
        newVisibleTo.addAll(memberIds);
      }
    }

    // 重複を除去
    newVisibleTo = newVisibleTo.toSet().toList();
    print('Final visibleTo list: $newVisibleTo');

    // スケジュールを更新（visibleToを新しいリストで上書き）
    final updatedSchedule = schedule.copyWith(visibleTo: newVisibleTo);
    await _firestore
        .collection('schedules')
        .doc(schedule.id)
        .update(_toFirestore(updatedSchedule));
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
          final schedules = await Future.wait(
            snapshot.docs.map((doc) => _enrichSchedule(doc))
          );
          return schedules;
        });
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    print('ScheduleRepository: watchUserSchedules called for user: $userId');
    final query = _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .orderBy('startDateTime', descending: false);

    print('ScheduleRepository: Query: ${query.parameters}');

    return query.snapshots().asyncMap((snapshot) async {
      print('ScheduleRepository: Received snapshot with ${snapshot.docs.length} documents');
      final schedules = await Future.wait(
        snapshot.docs.map((doc) => _enrichSchedule(doc))
      );
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
