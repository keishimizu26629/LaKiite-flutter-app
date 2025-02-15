import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class CreateSchedulePage extends HookConsumerWidget {
  final Schedule? schedule;
  const CreateSchedulePage({super.key, this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(text: schedule?.title);
    final descriptionController = useTextEditingController(text: schedule?.description);
    final locationController = useTextEditingController(text: schedule?.location);
    final selectedDate = useState<DateTime>(schedule?.dateTime ?? DateTime.now());
    final selectedTime = useState<TimeOfDay>(
      schedule != null
          ? TimeOfDay(hour: schedule!.dateTime.hour, minute: schedule!.dateTime.minute)
          : TimeOfDay.now()
    );
    final selectedLists = useState<List<UserList>>([]);

    final listsAsync = ref.watch(userListsStreamProvider);
    final authState = ref.watch(authNotifierProvider);

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
            ListTile(
              title: const Text('日付'),
              subtitle: Text(
                '${selectedDate.value.year}年${selectedDate.value.month}月${selectedDate.value.day}日',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.value,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  selectedDate.value = picked;
                }
              },
            ),
            ListTile(
              title: const Text('時間'),
              subtitle: Text(
                '${selectedTime.value.hour}:${selectedTime.value.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime.value,
                );
                if (picked != null) {
                  selectedTime.value = picked;
                }
              },
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
                return Wrap(
                  spacing: 8,
                  children: lists.map((list) {
                    final isSelected = selectedLists.value.contains(list);
                    return FilterChip(
                      label: Text(list.listName),
                      selected: isSelected,
                      onSelected: (value) {
                        if (value) {
                          selectedLists.value = [...selectedLists.value, list];
                        } else {
                          selectedLists.value = selectedLists.value
                              .where((l) => l != list)
                              .toList();
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('エラーが発生しました: $error'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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

          final dateTime = DateTime(
            selectedDate.value.year,
            selectedDate.value.month,
            selectedDate.value.day,
            selectedTime.value.hour,
            selectedTime.value.minute,
          );

          authState.whenData((state) async {
            if (state.status == AuthStatus.authenticated && state.user != null) {
              final currentUserId = state.user!.id;

              // 選択されたリストのメンバーを集める（自分のIDを必ず含める）
              final visibleTo = {currentUserId}; // Setを使用して重複を防ぐ
              for (final list in selectedLists.value) {
                visibleTo.addAll(list.memberIds);
              }

              if (schedule != null) {
                // 更新処理
                final updatedSchedule = Schedule(
                  id: schedule!.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  location: locationController.text.isEmpty ? null : locationController.text,
                  dateTime: dateTime,
                  ownerId: schedule!.ownerId,
                  sharedLists: selectedLists.value.map((list) => list.id).toList(),
                  visibleTo: visibleTo.toList(),
                  createdAt: schedule!.createdAt,
                  updatedAt: DateTime.now(),
                );
                await ref.read(scheduleNotifierProvider.notifier).updateSchedule(updatedSchedule);
              } else {
                // 新規作成処理
                await ref.read(scheduleNotifierProvider.notifier).createSchedule(
                      title: titleController.text,
                      description: descriptionController.text,
                      location: locationController.text.isEmpty
                          ? null
                          : locationController.text,
                      dateTime: dateTime,
                      ownerId: currentUserId,
                      sharedLists:
                          selectedLists.value.map((list) => list.id).toList(),
                      visibleTo: visibleTo.toList(),
                    );
              }

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          });
        },
        label: const Text('保存'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}