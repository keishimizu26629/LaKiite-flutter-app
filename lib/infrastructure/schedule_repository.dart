import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/schedule.dart';
import '../domain/interfaces/i_schedule_repository.dart';

class ScheduleRepository implements IScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository() : _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _toFirestore(Schedule schedule) {
    final data = schedule.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    return data;
  }

  @override
  Future<List<Schedule>> getSchedules(String groupId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('groupId', isEqualTo: groupId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Schedule.fromJson(data);
    }).toList();
  }

  @override
  Future<Schedule> createSchedule({
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
  }) async {
    final scheduleData = {
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'ownerId': ownerId,
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('schedules').add(scheduleData);
    final doc = await docRef.get();
    final data = doc.data()!;
    data['id'] = doc.id;
    return Schedule.fromJson(data);
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
  Stream<List<Schedule>> watchGroupSchedules(String groupId) {
    return _firestore
        .collection('schedules')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Schedule.fromJson(data);
            }).toList());
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    return _firestore
        .collection('schedules')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Schedule.fromJson(data);
            }).toList());
  }
}
