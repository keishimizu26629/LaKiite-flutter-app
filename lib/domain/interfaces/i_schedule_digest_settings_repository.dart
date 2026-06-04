import '../entity/schedule_digest_settings.dart';

abstract class IScheduleDigestSettingsRepository {
  Stream<ScheduleDigestSettings> watchCurrentUserSettings();

  Future<void> saveCurrentUserSettings(ScheduleDigestSettings settings);
}
