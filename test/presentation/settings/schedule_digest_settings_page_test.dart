import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_digest_settings.dart';
import 'package:lakiite/domain/interfaces/i_schedule_digest_settings_repository.dart';
import 'package:lakiite/presentation/settings/schedule_digest_settings_page.dart';
import 'package:lakiite/presentation/settings/schedule_digest_settings_providers.dart';

void main() {
  testWidgets('朝の共有予定通知設定を表示して保存できる', (tester) async {
    final repository = _FakeScheduleDigestSettingsRepository(
      ScheduleDigestSettings.defaults('user-1'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleDigestSettingsRepositoryProvider.overrideWithValue(
            repository,
          ),
          scheduleDigestSettingsProvider.overrideWith(
            (ref) => Stream.value(repository.current),
          ),
        ],
        child: const MaterialApp(home: ScheduleDigestSettingsPage()),
      ),
    );

    await tester.pump();

    expect(find.text('朝の共有予定通知'), findsOneWidget);
    expect(find.text('通知する'), findsOneWidget);
    expect(
      find.text('今日あなたに共有されている予定がある場合に、指定した時刻に通知を受け取れます。'),
      findsOneWidget,
    );
    expect(find.text('保存'), findsOneWidget);

    expect(find.text('8時'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('schedule-digest-notify-hour-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('7時').last);
    await tester.pumpAndSettle();

    expect(repository.saved, isNull);

    await tester.tap(find.byKey(const Key('schedule-digest-save-button')));
    await tester.pumpAndSettle();

    expect(repository.saved?.notifyHour, 7);
    expect(repository.saved?.enabled, isTrue);
  });

  testWidgets('設定が未作成の場合はオフ表示でオンにして保存すると作成される', (tester) async {
    final repository = _FakeScheduleDigestSettingsRepository(
      ScheduleDigestSettings.missingDocumentFallback('user-1'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleDigestSettingsRepositoryProvider.overrideWithValue(
            repository,
          ),
          scheduleDigestSettingsProvider.overrideWith(
            (ref) => Stream.value(repository.current),
          ),
        ],
        child: const MaterialApp(home: ScheduleDigestSettingsPage()),
      ),
    );

    await tester.pump();

    expect(find.text('通知する'), findsOneWidget);
    expect(find.text('8時'), findsOneWidget);
    expect(repository.saved, isNull);

    final notificationSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(notificationSwitch.value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository.saved, isNull);

    await tester.tap(find.byKey(const Key('schedule-digest-save-button')));
    await tester.pumpAndSettle();

    expect(repository.saved?.enabled, isTrue);
    expect(repository.saved?.notifyHour, 8);
  });
}

class _FakeScheduleDigestSettingsRepository
    implements IScheduleDigestSettingsRepository {
  _FakeScheduleDigestSettingsRepository(this.current);

  ScheduleDigestSettings current;
  ScheduleDigestSettings? saved;

  @override
  Stream<ScheduleDigestSettings> watchCurrentUserSettings() {
    return Stream.value(current);
  }

  @override
  Future<void> saveCurrentUserSettings(ScheduleDigestSettings settings) async {
    saved = settings;
    current = settings;
  }
}
