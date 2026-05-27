import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/calendar/widgets/schedule_ownership_style.dart';

class AllDayScheduleCard extends StatelessWidget {
  const AllDayScheduleCard({
    required this.schedule,
    required this.currentUserId,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
    super.key,
  });

  final Schedule schedule;
  final String? currentUserId;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final ownershipStyle = ScheduleOwnershipStyle.resolve(
      context,
      schedule: schedule,
      currentUserId: currentUserId,
    );

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScheduleDetailPage(schedule: schedule),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ownershipStyle.backgroundColor,
          border: Border.all(color: ownershipStyle.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_available,
              size: 16,
              color: ownershipStyle.textColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                schedule.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ownershipStyle.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
