import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('M/d (E)', 'ja_JP');
    return formatter.format(dateTime);
  }

  double _calculateTimePosition(DateTime time) {
    // 1時間を60ピクセルとして、分単位で計算
    final minutes = time.minute;
    return minutes.toDouble();
  }

  double _calculateHeight(DateTime start, DateTime end) {
    // 時間の差分を計算（分単位）
    final difference = end.difference(start).inMinutes;
    // 1時間を60ピクセルとして計算
    return difference.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isSameDay =
        schedule.startDateTime.year == schedule.endDateTime.year &&
            schedule.startDateTime.month == schedule.endDateTime.month &&
            schedule.startDateTime.day == schedule.endDateTime.day;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScheduleDetailPage(schedule: schedule),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 24 * 60.0, // 24時間分の高さ
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 時間表示部分
              SizedBox(
                width: 80,
                child: Stack(
                  children: [
                    // 時間の目盛り線
                    for (int hour = 0; hour < 24; hour++)
                      Positioned(
                        top: hour * 60.0,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // スケジュール表示部分
              Expanded(
                child: Stack(
                  children: [
                    // 時間の区切り線
                    for (int hour = 0; hour < 24; hour++)
                      Positioned(
                        top: hour * 60.0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                      ),
                    // スケジュールブロック
                    Positioned(
                      top: schedule.startDateTime.hour * 60.0 +
                          _calculateTimePosition(schedule.startDateTime),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _calculateHeight(
                          schedule.startDateTime,
                          schedule.endDateTime,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_formatDateTime(schedule.startDateTime)} - ${_formatDateTime(schedule.endDateTime)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schedule.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (schedule.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  schedule.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (schedule.location != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        schedule.location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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
  }
}
