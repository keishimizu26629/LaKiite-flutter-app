import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entity/schedule_digest_settings.dart';
import '../../domain/interfaces/i_schedule_digest_settings_repository.dart';
import '../../infrastructure/schedule_digest_settings_repository.dart';

final scheduleDigestSettingsRepositoryProvider =
    Provider<IScheduleDigestSettingsRepository>((ref) {
  return ScheduleDigestSettingsRepository();
});

final scheduleDigestSettingsProvider =
    StreamProvider<ScheduleDigestSettings>((ref) {
  return ref
      .watch(scheduleDigestSettingsRepositoryProvider)
      .watchCurrentUserSettings();
});
