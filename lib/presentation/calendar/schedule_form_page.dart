import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/schedule_form_logic.dart';
import 'package:lakiite/presentation/list/list_providers.dart';
import 'package:lakiite/utils/logger.dart';
import 'package:lakiite/presentation/list/list_detail_page.dart';

/// 15分単位の時間選択ダイアログ
class CustomTimePickerDialog extends StatefulWidget {
  const CustomTimePickerDialog({
    super.key,
    required this.initialTime,
  });
  final TimeOfDay initialTime;

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
                    initialValue: selectedHour,
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
                    initialValue: selectedMinute,
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
  const ScheduleFormPage({
    super.key,
    this.schedule,
    this.initialDate,
  });
  final Schedule? schedule;
  final DateTime? initialDate;

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

    final now = DateTime.now();
    final initialStartDate = ScheduleFormLogic.initialStartDate(
      schedule: schedule,
      initialDate: initialDate,
      now: now,
    );

    final selectedStartDate = useState<DateTime>(initialStartDate);

    final selectedStartTime =
        useState<TimeOfDay>(ScheduleFormLogic.timeOf(initialStartDate));

    final initialEndDate = ScheduleFormLogic.initialEndDate(
      schedule: schedule,
      initialDate: initialDate,
      now: now,
    );

    final selectedEndDate = useState<DateTime>(initialEndDate);

    final selectedEndTime = useState<TimeOfDay>(
      ScheduleFormLogic.timeOf(initialEndDate),
    );

    ScheduleFormValidationResult currentValidationResult() {
      return ScheduleFormLogic.validateScheduleForm(
        title: titleController.text,
        location: locationController.text,
        startDate: selectedStartDate.value,
        startTime: selectedStartTime.value,
        endDate: selectedEndDate.value,
        endTime: selectedEndTime.value,
      );
    }

    final formValidationResult = useState<ScheduleFormValidationResult>(
      currentValidationResult(),
    );

    void updateValidationResult() {
      formValidationResult.value = currentValidationResult();
    }

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
        final existingLists = ScheduleFormLogic.selectedListsForSchedule(
          schedule: schedule,
          lists: listsAsync.value!,
        );
        selectedLists.value = existingLists;
      }
      return null;
    }, [listsAsync]);

    // 初期表示時と日時変更時にフォーム全体の検証結果を更新する。
    useEffect(() {
      updateValidationResult();
      return null;
    }, [
      selectedStartDate.value,
      selectedStartTime.value,
      selectedEndDate.value,
      selectedEndTime.value
    ]);

    // テキストフィールドの変更を監視
    useEffect(() {
      void listener() {
        updateValidationResult();
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

      final validationResult = currentValidationResult();
      formValidationResult.value = validationResult;

      if (!validationResult.hasRequiredFields) {
        AppLogger.warning('ScheduleFormPage: Required fields are empty');
        return;
      }

      final startDateTime = ScheduleFormLogic.combineDateAndTime(
        selectedStartDate.value,
        selectedStartTime.value,
      );

      final endDateTime = ScheduleFormLogic.combineDateAndTime(
        selectedEndDate.value,
        selectedEndTime.value,
      );

      if (validationResult.hasInvalidTimeRange) {
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
      final selectedListIds = ScheduleFormLogic.listIds(selectedLists.value);
      AppLogger.debug('Selected lists: $selectedListIds');

      try {
        if (schedule != null) {
          // AppLogger.debug(
          //     'ScheduleFormPage: Updating schedule ${schedule!.id}');
          await scheduleNotifier.updateSchedule(
            schedule!.copyWith(
              title: titleController.text,
              description: descriptionController.text,
              location: ScheduleFormLogic.optionalLocation(
                locationController.text,
              ),
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              sharedLists: selectedListIds,
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
          AppLogger.debug('SharedLists: $selectedListIds');
          AppLogger.debug('VisibleTo: [${currentUser.id}]');

          await scheduleNotifier.createSchedule(
            title: titleController.text,
            description: descriptionController.text,
            location: ScheduleFormLogic.optionalLocation(
              locationController.text,
            ),
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            ownerId: currentUser.id,
            sharedLists: selectedListIds,
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
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
                helperText: '必須',
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
                helperText: '必須。場所が未定の場合は「未定」と入力してください。',
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
                            updateValidationResult();
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
                            updateValidationResult();
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
            if (formValidationResult.value.hasInvalidTimeRange)
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
                    if (formValidationResult.value.hasInvalidTimeRange)
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
                                          color: Colors.blue
                                              .withValues(alpha: 0.1),
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
        onPressed: formValidationResult.value.canSave ? handleSave : null,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
        backgroundColor:
            formValidationResult.value.canSave ? null : Colors.grey,
      ),
    );
  }
}
