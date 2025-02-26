import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class ScheduleTile extends ConsumerWidget {
  final Schedule schedule;
  final String currentUserId;
  final bool showOwner;
  final bool showEditButton;
  final bool isTimelineView;
  final bool showDivider;
  final VoidCallback? onEditPressed;
  final EdgeInsetsGeometry? margin;

  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.currentUserId,
    this.showOwner = true,
    this.showEditButton = false,
    this.isTimelineView = false,
    this.showDivider = false,
    this.onEditPressed,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnSchedule = schedule.ownerId == currentUserId;

    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isTimelineView && !isOwnSchedule ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isTimelineView && !isOwnSchedule
            ? BorderSide.none
            : BorderSide(
                color: isTimelineView
                    ? (isOwnSchedule
                        ? Colors.grey[400]!
                        : Theme.of(context).primaryColor.withOpacity(0.3))
                    : Colors.grey[300]!,
                width: 1,
              ),
      ),
      color: isTimelineView
          ? (isOwnSchedule ? Colors.grey[100] : Colors.white)
          : Colors.grey[50],
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScheduleDetailPage(schedule: schedule),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showEditButton && isOwnSchedule)
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: onEditPressed ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditSchedulePage(
                                  schedule: schedule,
                                ),
                              ),
                            );
                          },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (schedule.description.isNotEmpty) ...[
                Text(
                  schedule.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                      '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (schedule.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showOwner) ...[
                const SizedBox(height: 8),
                FutureBuilder<UserModel?>(
                  future: ref
                      .read(userRepositoryProvider)
                      .getUser(schedule.ownerId),
                  builder: (context, snapshot) {
                    final ownerName = snapshot.hasData
                        ? snapshot.data!.displayName
                        : '読み込み中...';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '作成者: ${isOwnSchedule ? '自分' : ownerName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (showDivider) const Divider(height: 24),
                      ],
                    );
                  },
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (schedule.reactionCount > 0)
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Stack(
                            children: [
                              const Positioned(
                                right: 2,
                                child: Text(
                                  '🤔',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -1,
                                left: -2,
                                child: Text(
                                  '🙋',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.reactionCount}',
                    style: TextStyle(
                      color: schedule.reactionCount > 0
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.blue[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.commentCount}',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
