import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entity/schedule_digest_settings.dart';
import 'schedule_digest_settings_providers.dart';

class ScheduleDigestSettingsPage extends ConsumerWidget {
  const ScheduleDigestSettingsPage({super.key});

  static const String path = 'schedule-digest';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(scheduleDigestSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('朝の共有予定通知'),
      ),
      body: settingsAsync.when(
        data: (settings) => _ScheduleDigestSettingsContent(
          settings: settings,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('通知設定の取得に失敗しました: $error'),
        ),
      ),
    );
  }
}

class _ScheduleDigestSettingsContent extends ConsumerWidget {
  const _ScheduleDigestSettingsContent({required this.settings});

  final ScheduleDigestSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(scheduleDigestSettingsRepositoryProvider);

    Future<void> save(ScheduleDigestSettings nextSettings) async {
      try {
        await repository.saveCurrentUserSettings(nextSettings);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通知設定の保存に失敗しました: $error')),
        );
      }
    }

    return ListView(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('通知する'),
          value: settings.enabled,
          onChanged: (enabled) => save(settings.copyWith(enabled: enabled)),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DropdownButtonFormField<int>(
            key: const Key('schedule-digest-notify-hour-dropdown'),
            initialValue: settings.notifyHour,
            decoration: const InputDecoration(
              icon: Icon(Icons.schedule),
              labelText: '通知時刻',
              helperText: '0時から9時まで選択できます',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var hour = 0; hour <= 9; hour++)
                DropdownMenuItem<int>(
                  value: hour,
                  child: Text('$hour時'),
                ),
            ],
            onChanged: settings.enabled
                ? (value) {
                    if (value == null) return;
                    save(settings.copyWith(notifyHour: value));
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
