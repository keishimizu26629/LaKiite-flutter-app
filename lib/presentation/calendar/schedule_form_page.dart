import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/utils/logger.dart';
import 'package:lakiite/presentation/list/list_detail_page.dart';

/// 15分単位の時間選択ダイアログ
class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePickerDialog({
    super.key,
    required this.initialTime,
  });

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = (widget.initialTime.minute ~/ 15) * 15;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '時間を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 時間選択
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<int>(
                    value: selectedHour,
                    items: List.generate(24, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text('${index.toString().padLeft(2, '0')}時'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedHour = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 分選択
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<int>(
                    value: selectedMinute,
                    items: [0, 15, 30, 45].map((minute) {
                      return DropdownMenuItem(
                        value: minute,
                        child: Text('${minute.toString().padLeft(2, '0')}分'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMinute = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleFormPage extends HookConsumerWidget {
  final Schedule? schedule;
  final DateTime? initialDate;

  const ScheduleFormPage({
    super.key,
    this.schedule,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('ScheduleFormPage: Building form page');
    AppLogger.debug(
        'ScheduleFormPage: Initial date: ${initialDate?.toString() ?? "未指定"}');

    final titleController = useTextEditingController(text: schedule?.title);
    final descriptionController =
        useTextEditingController(text: schedule?.description);
    final locationController =
        useTextEditingController(text: schedule?.location);

    // 初期日付の設定: scheduleがあればその日付、なければinitialDateを使用、どちらもなければ現在日時
    final initialStartDate = schedule?.startDateTime ??
        (initialDate != null
            ? DateTime(initialDate!.year, initialDate!.month, initialDate!.day,
                TimeOfDay.now().hour, TimeOfDay.now().minute)
            : DateTime.now());

    final selectedStartDate = useState<DateTime>(initialStartDate);

    final selectedStartTime = useState<TimeOfDay>(TimeOfDay(
        hour: initialStartDate.hour, minute: initialStartDate.minute));

    // 終了日時も同様に設定（開始日時の1時間後）
    final initialEndDate = schedule?.endDateTime ??
        (initialDate != null
            ? DateTime(initialDate!.year, initialDate!.month, initialDate!.day,
                TimeOfDay.now().hour + 1, TimeOfDay.now().minute)
            : DateTime.now().add(const Duration(hours: 1)));

    final selectedEndDate = useState<DateTime>(initialEndDate);

    final selectedEndTime = useState<TimeOfDay>(
        TimeOfDay(hour: initialEndDate.hour, minute: initialEndDate.minute));

    final hasTitleError = useState<bool>(false);
    final hasLocationError = useState<bool>(false);
    final hasTimeError = useState<bool>(false);

    final selectedLists = useState<List<UserList>>([]);
    final listsAsync = ref.watch(userListsStreamProvider);
    final authState = ref.watch(authNotifierProvider);

    AppLogger.debug('ScheduleFormPage: Initial form values:');
    AppLogger.debug('Title: ${titleController.text}');
    AppLogger.debug('Description: ${descriptionController.text}');
    AppLogger.debug('Location: ${locationController.text}');
    AppLogger.debug('Start Date: ${selectedStartDate.value}');
    AppLogger.debug('Start Time: ${selectedStartTime.value}');
    AppLogger.debug('End Date: ${selectedEndDate.value}');
    AppLogger.debug('End Time: ${selectedEndTime.value}');

    // 編集時の初期値設定
    useEffect(() {
      if (schedule != null && listsAsync.hasValue) {
        final existingLists = listsAsync.value!
            .where((list) => schedule!.sharedLists.contains(list.id))
            .toList();
        selectedLists.value = existingLists;
      }
      return null;
    }, [listsAsync]);

    // 時間の整合性をチェックする関数
    void validateTime() {
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

      hasTimeError.value = endDateTime.isBefore(startDateTime);
    }

    // 初期表示時と時間変更時にバリデーションを実行
    useEffect(() {
      validateTime();
      return null;
    }, [
      selectedStartDate.value,
      selectedStartTime.value,
      selectedEndDate.value,
      selectedEndTime.value
    ]);

    // バリデーション関数
    void validateInputs() {
      hasTitleError.value = titleController.text.trim().isEmpty;
      hasLocationError.value = locationController.text.trim().isEmpty;
    }

    // テキストフィールドの変更を監視
    useEffect(() {
      void listener() {
        validateInputs();
      }

      titleController.addListener(listener);
      locationController.addListener(listener);

      return () {
        titleController.removeListener(listener);
        locationController.removeListener(listener);
      };
    }, [titleController, locationController]);

    // スケジュールの保存処理
    Future<void> handleSave() async {
      AppLogger.debug('ScheduleFormPage: Save button pressed');

      if (titleController.text.isEmpty) {
        AppLogger.warning('ScheduleFormPage: Title is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('タイトルを入力してください')),
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
        AppLogger.warning('ScheduleFormPage: End date is before start date');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('終了日時は開始日時より後に設定してください')),
        );
        return;
      }

      final scheduleNotifier = ref.read(scheduleNotifierProvider.notifier);
      final currentUser = authState.requireValue.user;

      if (currentUser == null) {
        AppLogger.error('ScheduleFormPage: User is not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー認証が必要です')),
        );
        return;
      }

      AppLogger.debug('ScheduleFormPage: Preparing to save schedule');
      AppLogger.debug('Current user ID: ${currentUser.id}');
      AppLogger.debug(
          'Selected lists: ${selectedLists.value.map((l) => l.id).toList()}');

      try {
        if (schedule != null) {
          // AppLogger.debug(
          //     'ScheduleFormPage: Updating schedule ${schedule!.id}');
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
          // AppLogger.debug('ScheduleFormPage: Schedule updated successfully');
        } else {
          AppLogger.debug('ScheduleFormPage: Creating new schedule with:');
          AppLogger.debug('Title: ${titleController.text}');
          AppLogger.debug('Description: ${descriptionController.text}');
          AppLogger.debug('Location: ${locationController.text}');
          AppLogger.debug('StartDateTime: $startDateTime');
          AppLogger.debug('EndDateTime: $endDateTime');
          AppLogger.debug('OwnerId: ${currentUser.id}');
          AppLogger.debug(
              'SharedLists: ${selectedLists.value.map((l) => l.id).toList()}');
          AppLogger.debug('VisibleTo: [${currentUser.id}]');

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
          AppLogger.debug('ScheduleFormPage: Schedule created successfully');
        }

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        AppLogger.error('ScheduleFormPage: Error saving schedule: $e');
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
              decoration: InputDecoration(
                labelText: 'タイトル',
                border: const OutlineInputBorder(),
                errorText: hasTitleError.value ? 'タイトルを入力してください' : null,
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
              decoration: InputDecoration(
                labelText: '場所',
                border: const OutlineInputBorder(),
                errorText: hasLocationError.value
                    ? '場所を入力してください。場所が未定の場合は「未定」と入力してください。'
                    : null,
                helperText: '場所が未定の場合は「未定」と入力してください。',
              ),
            ),
            const SizedBox(height: 16),
            const Text('開始日時',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('日付'),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate.value,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            selectedStartDate.value = picked;
                            if (selectedEndDate.value.isBefore(picked)) {
                              selectedEndDate.value = picked;
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedStartDate.value.year}年${selectedStartDate.value.month}月${selectedStartDate.value.day}日',
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('時間'),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final result = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (context) => CustomTimePickerDialog(
                              initialTime: selectedStartTime.value,
                            ),
                          );
                          if (result != null) {
                            selectedStartTime.value = result;
                            validateTime();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${((selectedStartTime.value.minute ~/ 15) * 15).toString().padLeft(2, '0')}',
                              ),
                              const Icon(Icons.access_time, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('日付'),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate.value,
                            firstDate: selectedStartDate.value,
                            lastDate: DateTime.now()
                                .toUtc()
                                .toLocal()
                                .add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            selectedEndDate.value = picked;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedEndDate.value.year}年${selectedEndDate.value.month}月${selectedEndDate.value.day}日',
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('時間'),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final result = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (context) => CustomTimePickerDialog(
                              initialTime: selectedEndTime.value,
                            ),
                          );
                          if (result != null) {
                            selectedEndTime.value = result;
                            validateTime();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${((selectedEndTime.value.minute ~/ 15) * 15).toString().padLeft(2, '0')}',
                              ),
                              const Icon(Icons.access_time, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasTimeError.value ||
                hasTitleError.value ||
                hasLocationError.value)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitleError.value)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'タイトルを入力してください',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasLocationError.value)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '場所を入力してください。場所が未定の場合は「未定」と入力してください。',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasTimeError.value)
                      const Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '終了日時は開始日時より後に設定してください',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          final newValue = !selectedLists.value.contains(list);
                          if (newValue) {
                            selectedLists.value = [
                              ...selectedLists.value,
                              list
                            ];
                          } else {
                            selectedLists.value = selectedLists.value
                                .where((l) => l.id != list.id)
                                .toList();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selectedLists.value.contains(list),
                                onChanged: (bool? value) {
                                  if (value == true) {
                                    selectedLists.value = [
                                      ...selectedLists.value,
                                      list
                                    ];
                                  } else {
                                    selectedLists.value = selectedLists.value
                                        .where((l) => l.id != list.id)
                                        .toList();
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        list.listName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ListDetailPage(list: list),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '詳細',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
        onPressed: (hasTimeError.value ||
                hasTitleError.value ||
                hasLocationError.value)
            ? null
            : handleSave,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
        backgroundColor: (hasTimeError.value ||
                hasTitleError.value ||
                hasLocationError.value)
            ? Colors.grey
            : null,
      ),
    );
  }
}
