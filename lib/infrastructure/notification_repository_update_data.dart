import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/notification.dart';

class NotificationRepositoryUpdateData {
  const NotificationRepositoryUpdateData._();

  static Map<String, Object> accepted() {
    return {
      'status': NotificationStatus.accepted.name,
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object> rejected() {
    return {
      'status': NotificationStatus.rejected.name,
      'rejectionCount': FieldValue.increment(1),
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
