import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleDigestSettings {
  ScheduleDigestSettings({
    required this.userId,
    required this.enabled,
    required this.notifyHour,
    this.lastSentDate,
  }) {
    if (notifyHour < 0 || notifyHour > 9) {
      throw ArgumentError.value(
        notifyHour,
        'notifyHour',
        'notifyHour must be between 0 and 9',
      );
    }
  }

  factory ScheduleDigestSettings.defaults(String userId) {
    return ScheduleDigestSettings(
      userId: userId,
      enabled: true,
      notifyHour: 8,
    );
  }

  factory ScheduleDigestSettings.missingDocumentFallback(String userId) {
    return ScheduleDigestSettings(
      userId: userId,
      enabled: false,
      notifyHour: 8,
    );
  }

  factory ScheduleDigestSettings.fromFirestore({
    required String userId,
    required Map<String, dynamic>? data,
  }) {
    if (data == null) {
      return ScheduleDigestSettings.defaults(userId);
    }

    final rawNotifyHour = data['notifyHour'];
    final notifyHour = rawNotifyHour is int ? rawNotifyHour : 8;

    return ScheduleDigestSettings(
      userId: userId,
      enabled: data['enabled'] as bool? ?? true,
      notifyHour: notifyHour >= 0 && notifyHour <= 9 ? notifyHour : 8,
      lastSentDate: data['lastSentDate'] as String?,
    );
  }

  final String userId;
  final bool enabled;
  final int notifyHour;
  final String? lastSentDate;

  ScheduleDigestSettings copyWith({
    bool? enabled,
    int? notifyHour,
    String? lastSentDate,
  }) {
    return ScheduleDigestSettings(
      userId: userId,
      enabled: enabled ?? this.enabled,
      notifyHour: notifyHour ?? this.notifyHour,
      lastSentDate: lastSentDate ?? this.lastSentDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'notifyHour': notifyHour,
      'lastSentDate': lastSentDate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
