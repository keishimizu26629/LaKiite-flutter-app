import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class ScheduleFormPage extends HookConsumerWidget {
  final Schedule? schedule;
  const ScheduleFormPage({super.key, this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(text: schedule?.title);
    final descriptionController =
        useTextEditingController(text: schedule?.description);
    final locationController =
        useTextEditingController(text: schedule?.location);

    final selectedStartDate =
        useState<DateTime>(schedule?.startDateTime ?? DateTime.now());
    final selectedStartTime = useState<TimeOfDay>(schedule != null
        ? TimeOfDay(
            hour: schedule!.startDateTime.hour,
            minute: schedule!.startDateTime.minute)
        : TimeOfDay.now());

    final selectedEndDate = useState<DateTime>(schedule?.endDateTime ??
        (schedule?.startDateTime ?? DateTime.now())
            .add(const Duration(hours: 1)));
    final selectedEndTime = useState<TimeOfDay>(schedule != null
        ? TimeOfDay(
            hour: schedule!.endDateTime.hour,
            minute: schedule!.endDateTime.minute)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))));

    final selectedLists = useState<List<UserList>>([]);
    final listsAsync = ref.watch(userListsStreamProvider);
    final authState = ref.watch(authNotifierProvider);

    // 編集時の初期値設定
    useEffect(() {
      if (schedule != null && listsAsync.hasValue) {
        final existingLists = listsAsync.value!.where(
          (list) => schedule!.sharedLists.contains(list.id)
        ).toList();
        selectedLists.value = existingLists;
      }
      return null;
    }, [listsAsync]);

    // スケジュールの保存処理
    Future<void> handleSave() async {
      if (titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('タイトルを入力してください')),
        );
        return;
      }

      if (selectedLists.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('公開するリストを選択してください')),
        );
        return;
      }

      final startDateTime = DateTime(
        selectedStartDate.value.year,
        selectedStartDate.value.month,
        selectedStartDate.value.day,
        selectedStartTime.value.hour,
        selectedStartTime.value.minute,
      );

      final endDateTime = DateTime(
        selectedEndDate.value.year,
        selectedEndDate.value.month,
        selectedEndDate.value.day,
        selectedEndTime.value.hour,
        selectedEndTime.value.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('終了日時は開始日時より後に設定してください')),
        );
        return;
      }

      final scheduleNotifier = ref.read(scheduleNotifierProvider.notifier);
      final currentUser = authState.when(
        data: (state) => state.user,
        loading: () => null,
        error: (_, __) => null,
      );

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー情報の取得に失敗しました')),
        );
        return;
      }

      try {
        if (schedule != null) {
          print('ScheduleFormPage: Updating schedule ${schedule!.id}');
          await scheduleNotifier.updateSchedule(
            schedule!.copyWith(
              title: titleController.text,
              description: descriptionController.text,
              location: locationController.text.isEmpty
                  ? null
                  : locationController.text,
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              sharedLists: selectedLists.value.map((l) => l.id).toList(),
              visibleTo: [currentUser.id],
              updatedAt: DateTime.now(),
            ),
          );
          print('ScheduleFormPage: Schedule updated successfully');
        } else {
          print('ScheduleFormPage: Creating new schedule');
          await scheduleNotifier.createSchedule(
            title: titleController.text,
            description: descriptionController.text,
            location: locationController.text.isEmpty
                ? null
                : locationController.text,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            ownerId: currentUser.id,
            sharedLists: selectedLists.value.map((l) => l.id).toList(),
            visibleTo: [currentUser.id],
          );
          print('ScheduleFormPage: Schedule created successfully');
        }

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('ScheduleFormPage: Error saving schedule: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('スケジュールの保存に失敗しました: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule != null ? '予定編集' : '予定作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: '場所',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('開始日時',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('日付'),
                    subtitle: Text(
                      '${selectedStartDate.value.year}年${selectedStartDate.value.month}月${selectedStartDate.value.day}日',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate.value,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        selectedStartDate.value = picked;
                        if (selectedEndDate.value.isBefore(picked)) {
                          selectedEndDate.value = picked;
                        }
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('時間'),
                    subtitle: Text(
                      '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${(selectedStartTime.value.minute - selectedStartTime.value.minute % 15).toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedStartTime.value,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: true,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        final adjustedMinute =
                            picked.minute - picked.minute % 15;
                        selectedStartTime.value = TimeOfDay(
                          hour: picked.hour,
                          minute: adjustedMinute,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('終了日時',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('日付'),
                    subtitle: Text(
                      '${selectedEndDate.value.year}年${selectedEndDate.value.month}月${selectedEndDate.value.day}日',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate.value,
                        firstDate: selectedStartDate.value,
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        selectedEndDate.value = picked;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('時間'),
                    subtitle: Text(
                      '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${(selectedEndTime.value.minute - selectedEndTime.value.minute % 15).toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedEndTime.value,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: true,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        final adjustedMinute =
                            picked.minute - picked.minute % 15;
                        selectedEndTime.value = TimeOfDay(
                          hour: picked.hour,
                          minute: adjustedMinute,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('公開するリスト', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            listsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.list_alt, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('リストがありません。\nホーム画面からリストを作成してください。'),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: lists.map((list) {
                    return CheckboxListTile(
                      title: Text(list.listName),
                      value: selectedLists.value.contains(list),
                      onChanged: (bool? value) {
                        if (value == true) {
                          selectedLists.value = [...selectedLists.value, list];
                        } else {
                          selectedLists.value = selectedLists.value
                              .where((l) => l.id != list.id)
                              .toList();
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('エラー: $error')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: handleSave,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
      ),
    );
  }
}
