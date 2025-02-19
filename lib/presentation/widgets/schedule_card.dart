import 'package:flutter/material.dart';
import '../../domain/entity/schedule.dart';
import '../calendar/schedule_detail_page.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final bool isOwner;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.isOwner,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(schedule.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '開始: ${_formatDateTime(schedule.startDateTime)}\n終了: ${_formatDateTime(schedule.endDateTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (schedule.location != null) ...[
              const SizedBox(height: 2),
              Text(
                '場所: ${schedule.location}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: schedule.reactionCount > 0 ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.reactionCount.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment,
                  size: 16,
                  color: schedule.commentCount > 0 ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.commentCount.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: isOwner
            ? const Icon(Icons.edit, color: Colors.blue)
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScheduleDetailPage(schedule: schedule),
            ),
          );
        },
      ),
    );
  }
}
