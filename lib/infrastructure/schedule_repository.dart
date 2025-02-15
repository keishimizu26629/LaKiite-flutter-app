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
      'dateTime': Timestamp.fromDate(schedule.dateTime),
      'ownerId': schedule.ownerId,
      'sharedLists': schedule.sharedLists,
      'visibleTo': schedule.visibleTo,
      'createdAt': schedule.createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Schedule _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String?,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      ownerId: data['ownerId'] as String,
      sharedLists: List<String>.from(data['sharedLists'] as List),
      visibleTo: List<String>.from(data['visibleTo'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Future<List<Schedule>> getListSchedules(String listId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('sharedLists', arrayContains: listId)
        .orderBy('dateTime', descending: false)
        .get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Future<List<Schedule>> getUserSchedules(String userId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .orderBy('dateTime', descending: false)
        .get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    final docRef = await _firestore
        .collection('schedules')
        .add(_toFirestore(schedule));
    final doc = await docRef.get();
    return _fromFirestore(doc);
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    await _firestore
        .collection('schedules')
        .doc(schedule.id)
        .update(_toFirestore(schedule));
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
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    print('ScheduleRepository: watchUserSchedules called for user: $userId');
    final query = _firestore
        .collection('schedules')
        .where('visibleTo', arrayContains: userId)
        .orderBy('dateTime', descending: false);
    
    print('ScheduleRepository: Query: ${query.parameters}');
    
    return query
        .snapshots()
        .map((snapshot) {
          print('ScheduleRepository: Received snapshot with ${snapshot.docs.length} documents');
          return snapshot.docs.map(_fromFirestore).toList();
        });
  }
}
